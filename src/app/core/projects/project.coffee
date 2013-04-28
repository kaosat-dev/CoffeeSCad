define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  buildProperties = require 'core/utils/buildProperties'
  Compiler = require './compiler'
  
  debug  = false
  
  class ProjectFile extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name:     "testFile.coffee"
      content:  ""
      isActive: false
      isSaveAdvised: false
      isCompileAdvised: false
    attributeNames: ['name','content','isActive','isSaveAdvised','isCompileAdvised']
    persistedAttributeNames : ['name','content']
    buildProperties @
      
    constructor:(options)->
      super options
      #This is used for "dirtyness compare" , might be optimisable (storage vs time , hash vs direct compare)
      @storedContent = @content
      @on("save",   @_onSaved)
      @on("change:name", @_onNameChanged)
      @on("change:content", @_onContentChanged)
      @on("change:isActive",@_onIsActiveChanged)
    
    _onNameChanged:()=>
      @isSaveAdvised = true

    _onContentChanged:()=>
      @isCompileAdvised = true
      if (@storedContent is @content)
        @isSaveAdvised = false
      else
        @isSaveAdvised = true
        
    _onSaved:()=>
      #when save is sucessfull
      @storedContent = @content
      @isSaveAdvised = false
      
    _onIsActiveChanged:=>
      if @isActive
        @trigger("activated")
      else
        @trigger("deActivated")
   
    save: (attributes, options)=>
      backup = @toJSON
      @toJSON= =>
        attributes = _.clone(@attributes)
        for attrName, attrValue of attributes
          if attrName not in @persistedAttributeNames
            delete attributes[attrName]
        return attributes
       
      super attributes, options 
      @toJSON=backup
      @trigger("save",@)
     
     destroy:(options)=>
      options = options or {}
      @trigger('destroy', @, @collection, options)
      
      
  class Folder extends Backbone.Collection
    model: ProjectFile
    sync : null
    constructor:(options)->
      super options
      @_storageData = []

    save:=>
      for index, file of @models
        file.sync = @sync
        file.save() 
      
    changeStorage:(storeName,storeData)->
      for oldStoreName in  @_storageData
        delete @[oldStoreName]
      @_storageData = []  
      @_storageData.push(storeName)
      @[storeName] = storeData
      for index, file of @models
        file.sync = @sync 
        #file.pathRoot= project.get("name")
   
   
  class Project extends Backbone.Model
    """Main aspect of coffeescad : contains all the files
    * project is a top level element ("folder"+metadata)
    * a project contains files 
    * a project can reference another project (includes)
    """
    idAttribute: 'name'
    defaults:
      name:     "Project"
      lastModificationDate: null
      activeFile : null
      isSaveAdvised:false #based on propagation from project files : if a project file is changed, the project is tagged as "dirty" aswell
      isCompiled: false
      isCompileAdvised:false
    
    attributeNames: ['name','lastModificationDate','activeFile','isCompiled','isSaveAdvised','isCompileAdvised']
    persistedAttributeNames : ['name','lastModificationDate']
    buildProperties @
    
    constructor:(options)->
      options = options or {}
      super options
      @compiler = options.compiler ? new Compiler()
      
      @rootFolder = new Folder()
      @rootFolder.on("reset",@_onFilesReset)
      
      classRegistry={}
      @bom = new Backbone.Collection()
      @rootAssembly = {}
      @dataStore = null
      
      @on("change:name", @_onNameChanged)
      @on("compiled",@_onCompiled)
      @on("compile:error",@_onCompileError)
      @on("loaded",@_onFilesReset)
      
    addFile:(options)->
      file = new ProjectFile
        name: options.name ? @name+".coffee"
        content: options.content ? " \n\n"
      @_addFile(file)   
      return file
      
    removeFile:(file)=>
      @rootFolder.remove(file)
      @isSaveAdvised = true
    
    save: (attributes, options)=>
      #project is only a container, if really necessary data could be stored inside the metadata file (.project)
      @dataStore.saveProject(@)
      @_clearFlags()
      @trigger("save", @)
      
    compile:(options)=>
      if not @compiler?
        throw new Error("No compiler specified")
      @compiler.project = @
      return @compiler.compile(options)
    
    makeFileActive:(options)=>
      #set the currently active file (only one at a time)
      #you could argue that this is purely UI side, in fact it is not : events, adding data to the file etc should use the currently active
      #file, therefore there is logic , not just UI , but the UI should reflect this
      options = options or {}
      fileName = null
      
      if options instanceof String or typeof options is 'string' 
        fileName = options
      if options instanceof ProjectFile 
        fileName = options.name
      if options.file
        fileName = options.file.name
      if options.fileName
        fileName = options.fileName
        
      file = @rootFolder.get(fileName)  
      if file?
        file.isActive = true
        @activeFile =file
        #DESELECT ALL OTHERS   
        otherFiles = _.without(@rootFolder.models, file) 
        for otherFile in otherFiles
          otherFile.isActive=false
      return @activeFile
      
    _addFile:(file)=>
      @rootFolder.add file
      @_setupFileEventHandlers(file)
      @isSaveAdvised = true
    
    _setupFileEventHandlers:(file)=>
      file.on("change:content",@_onFileChanged)
      file.on("save",@_onFileSaved)
      file.on("destroy",@_onFileDestroyed)
      
    _clearFlags:=>
      #used to reset project into a "neutral" state (no save and compile required)
      for file in @rootFolder.models
        file.isSaveAdvised = false
        file.isCompileAdvised = false
      @isSaveAdvised = false
      @isCompileAdvised = false
      
    _onCompiled:=>
      @compiler.project = null
      @isCompileAdvised = false
      for file in @rootFolder.models
        file.isCompileAdvised = false
      @isCompiled = true
      
    _onCompileError:=>
      @compiler.project = null
      @isCompileAdvised = false
      for file in @rootFolder.models
        file.isCompileAdvised = false
      @isCompiled = true
      
    _onNameChanged:(model, name)=>
      try
        mainFile = @rootFolder.get(@previous('name')+".coffee")
        if mainFile?
          console.log "project name changed from #{@previous('name')} to #{name}"
          mainFile.name = "#{name}.coffee"
      catch error
        console.log "error in rename : #{error}"
    
    _onFilesReset:()=>
      #add various event bindings, reorder certain specific files
      mainFileName ="#{@name}.coffee"
      ### 
      mainFile = @rootFolder.get(mainFileName)
      @rootFolder.remove(mainFileName)
      @rootFolder.add(mainFile, {at:0})
      
      configFileName = "config.coffee"
      configFile = @rootFolder.get(configFileName)
      @rootFolder.remove(configFileName)
      @rootFolder.add(configFile, {at:1})
      ###
      console.log "files reset, setting active file to",mainFileName
      @makeFileActive({fileName:mainFileName})
      
      for file in @rootFolder.models
        @_setupFileEventHandlers(file)
        
      @_clearFlags()
    
    _onFileSaved:(fileName)=>
      @lastModificationDate = new Date()
      for file of @rootFolder
        if file.isSaveAdvised
          return
      
    _onFileChanged:(file)=>
      @isSaveAdvised = file.isSaveAdvised if file.isSaveAdvised is true
      @isCompileAdvised = file.isCompileAdvised if file.isCompileAdvised is true
    
    _onFileDestroyed:(file)=>
      if @dataStore
        @dataStore.destroyFile(@name, file.name)
      
  return Project
