define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  buildProperties = require 'modules/core/utils/buildProperties'
  
  debug  = false
  
  class ProjectFile extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name:     "testFile.coffee"
      content:  ""
      isSaveAdvised: false
      isCompileAdvised: false
    attributeNames: ['name','content','isSaveAdvised','isCompileAdvised']
    persistedAttributeNames : ['name','content']
    buildProperties @
      
    constructor:(options)->
      super options
      #This is used for "dirtyness compare" , might be optimisable (storage vs time , hash vs direct compare)
      @storedContent = @content
      @on("save",   @_onSaved)
      @on("change:name", @_onNameChanged)
      @on("change:content", @_onContentChanged)
    
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
    ###
    parse: (response)=>
      console.log("in projFiles parse")
      for i, v of response
        response[i] = new ProjectFile(v)
        response[i].collection = @
        
      console.log response      
      return response  
    ###
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
      isSaveAdvised:false #based on propagation from project files : if a project file is changed, the project is tagged as "dirty" aswell
      isCompiled: false
      isCompileAdvised:false
    
    attributeNames: ['name','lastModificationDate','isCompiled','isSaveAdvised','isCompileAdvised']
    persistedAttributeNames : ['name','lastModificationDate']
    buildProperties @
    
    constructor:(options)->
      super options
      @rootFolder = new Folder()
      @rootFolder.on("reset",@_onFilesReset)
      @on("change:name", @_onNameChanged)
      @on("compiled",@_onCompiled)
      
      classRegistry={}
      @bom = new Backbone.Collection()
      @rootAssembly = {}
      @dataStore = null
    
    _setupFileEventHandlers:(file)=>
      file.on("change",@_onFileChanged)
      file.on("save",@_onFileSaved)
      #file.on("change:content":()=>console.log "file content changed")
      #file.on("change:isSaveAdvised":()=>console.log "file isSaveAdvised changed")
    
    _addFile:(file)=>
      @rootFolder.add file
      @_setupFileEventHandlers(file)
      @isSaveAdvised = true
      
    addFile:(options)->
      file = new ProjectFile
        name: options.name ? @name+".coffee"
        content: options.content ? " \n\n"  
      @_addFile file   
      
    removeFile:(file)=>
      @rootFolder.remove(file)
      @isSaveAdvised = true
    
    save: (attributes, options)=>
      #project is only a container, data is stored inside the metadata file (.project)
      #metaDataFile = @rootFolder.get(".project")
      #metaDataFile.content = {name:@name,lastModificationDate:@lastModificationDate}
      
      ###
      @dataStore.saveProject(@)
      for index, file of @rootFolder.models
        file.sync = @sync
      
      console.log @sync
      @rootFolder.sync = @sync
      @rootFolder.path = @name
      metaDataFile.sync = @sync
      metaDataFile.save()
      ###
      
      
      backup = @toJSON
      @toJSON= =>
        attributes = _.clone(@attributes)
        for attrName, attrValue of attributes
          if attrName not in @persistedAttributeNames
            delete attributes[attrName]
        return attributes
       
      super attributes, options 
      @toJSON=backup
      
      console.log "rootFolder json"
      console.log @rootFolder.toJSON()
      
      @rootFolder.sync = @sync
      @rootFolder.save()
      
      ###
      for index, file of @rootFolder.models
        file.sync = @sync
        file.save()
      ###
       
      @isSaveAdvised = false
      @isCompileAdvised = false  
      @trigger("save",@)
    
    
    _onCompiled:()=>
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
      mainFile = @rootFolder.get(mainFileName)
      @rootFolder.remove(mainFileName)
      @rootFolder.add(mainFile, {at:0})
      
      configFileName = "config.coffee"
      configFile = @rootFolder.get(configFileName)
      @rootFolder.remove(configFileName)
      @rootFolder.add(configFile, {at:1})
      
      for file in @rootFolder.models
        @_setupFileEventHandlers(file)
    
    _onFileSaved:(fileName)=>
      @lastModificationDate = new Date()
      for file of @rootFolder
        if file.isSaveAdvised
          return
      
    _onFileChanged:(file)=>
      @isSaveAdvised = file.isSaveAdvised if file.isSaveAdvised is true
      @isCompileAdvised = file.isCompileAdvised if file.isCompileAdvised is true
      
  return Project
