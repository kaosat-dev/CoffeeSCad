define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  buildProperties = require 'modules/core/utils/buildProperties'
  
  debug  = false
  
  class ProjectFile extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name:     "mainFile"
      ext:      "coffee"
      content:  ""
      dirty: false
    attributeNames: ['name','ext','content','dirty']
    buildProperties @
      
    constructor:(options)->
      super options
      @storedContent = @get("content") #This is used for "dirtyness compare" , might be optimisable (storage vs time , hash vs direct compare)
      @bind("save",   @onSaved)
      @on("change:name", @onChanged)
      @on("change:ext", @onChanged)
      @on("change:content", @onChanged)
    
    onChanged:()=>
      if @storedContent == @get("content")
          @dirty=false
      else
          @dirty = true
    
    onSaved:()=>
      #when save is sucessfull
      @storedContent = @get("content")
      @dirty=false
      
      
  class ProjectFiles extends Backbone.Collection
    model: ProjectFile
    sync = null
    constructor:(options)->
      super options
      @sync=null
    ###
    parse: (response)=>
      console.log("in projFiles parse")
      for i, v of response
        response[i] = new ProjectFile(v)
        response[i].collection = @
        
      console.log response      
      return response  
    ###
    changeSync:(newSync,additional)->
      for index, file of @models
        file.sync = @store.sync 
        file.pathRoot= project.get("name")
   
   
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
    
    constructor:(options)->
      super options
      @dirty    = false #based on propagation from project files : if a project file is changed, the project is tagged as "dirty" aswell
      @new      = true
      @bind("reset", @onReset)
      @bind("sync",  @onSync)
      @bind("change",@onChanged)
      @files = []
      @pfiles = new ProjectFiles()
      @pfiles.on("reset",@onFilesReset)
      @on("change:name", @onProjectNameChanged)
      
      classRegistry={}
      @bom = new Backbone.Collection()
      @rootAssembly = {}
    
    onProjectNameChanged:(model, name)=>
      console.log "project name changed from #{@previous('name')} to #{name}"
      mainFile = @pfiles.get(@previous('name'))
      console.log mainFile
      mainFile.set("name",name)
    
    rename:(newName)=>
      if newName != @get("name")
        @set("name",newName)
    
    onFilesReset:()=>
      #add various event bindings, reorder certain specific files
      mainFileName = @get("name")
      mainFile = @pfiles.get(mainFileName)
      @pfiles.remove(mainFileName)
      @pfiles.add(mainFile, {at:0})
      
      configFileName = "config"
      configFile = @pfiles.get(configFileName)
      @pfiles.remove(configFileName)
      @pfiles.add(configFile, {at:1})
      
      for pFile in @pfiles.models
        pFile.bind("change", ()=> @onFileChanged(pFile.get("id")))
        pFile.bind("saved" , ()=> @onFileSaved(pFile.get("id")))
        pFile.bind("dirtied", ()=> @trigger "dirtied")
        pFile.bind("cleaned", ()=> @onFileSaved(pFile.get("id")))
    
    switchStorage:(storageType)->
      @storageType = storageType
      switch storageType
        when "browser"
          locStorName = @get("name")+"-files"
          @pfiles.sync = ""
          @pfiles.localStorage= new Backbone.LocalStorage(locStorName)
    
    save: (attributes, options)=>
      super attributes, options
      rootStoreURI = "projects-"+@get("name")+"-files"
      @pfiles.sync = @sync
      for index, file of @pfiles.models
        file.save() 
        file.trigger("save")

    onReset:()->
      if debug
        console.log "Project model reset" 
        console.log @
        console.log "_____________"
    
    onSync:()->
      @new = false
      if debug
        console.log "Project sync" 
        console.log @
        console.log "_____________"
      
    onChanged:(settings, value)=>
      #@compile()      
      @dirty=true
      for key, val of @changedAttributes()
        switch key
          when "name"
            locStorName = val+"-files"
            @pfiles.localStorage= new Backbone.LocalStorage(locStorName)
            
    onFileSaved:(fileName)=>
      @set("lastModificationDate",new Date())
      for file of @pfiles
        if file.dirty
          return
      @trigger "allSaved"
      
    onFileChanged:(fileName)=>
      @trigger "change"
      
    isNew2:()->
      return @new 
      
    add:(pFile)=>
      @pfiles.add pFile
      @files.push pFile.get("name")
      pFile.bind("change", ()=> @onFileChanged(pFile.get("id")))
      pFile.bind("saved" , ()=> @onFileSaved(pFile.get("id")))
      pFile.bind("dirtied", ()=> @trigger "dirtied")
      pFile.bind("cleaned", ()=> @onFileSaved(pFile.get("id")))
      
      #we added a new file, so project as changed -> mark as dirty
      @dirty=true
      @trigger "dirtied"
    
    remove:(pFile)=>
      index = @files.indexOf(pFile.get("name"))
      @files.splice(index, 1) 
      @pfiles.remove(pFile)
    
    fetch_file:(options)=>
      id = options.id
      console.log "id specified: #{id}"
      if @pfiles.get(id)
        pFile = @pfiles.get(id)
      else
        pFile = new ProjectFile({name:id})
        pFile.collection = @pfiles
        pFile.fetch()
      return pFile
      
    createFile:(options)->
      file = new ProjectFile
        name: options.name ? "a File"
        content: options.content ? " \n\n"  
        ext:  options.ext ? "coffee"
      @add file      
      
  return Project
