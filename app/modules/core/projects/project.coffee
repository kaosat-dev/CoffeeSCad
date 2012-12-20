define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
 
  
  CsgProcessor    = require "modules/csg.processor"
  
  debug  = false
  #TODO: add support for multiple types of storage, settable per project
  #syncType = Backbone.LocalStorage
  
  class ProjectFile extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name:     "mainPart"
      ext:      "coscad"
      content:  ""
           
    constructor:(options)->
      super options
      @rendered = false
      @dirty    = false
      @storedContent = @get("content") #This is used for "dirtyness compare" , might be optimisable (storage vs time , hash vs direct compare)
      @bind("change", @onChanged)
      @bind("sync",   @onSynched)
      
    onChanged:()=>
      if @storedContent == @get("content")
          @dirty = false
      else
          @dirty = true
      if @dirty
        @trigger "dirtied"
      else
        @trigger "cleaned"
    
    onSynched:()=>
      #when save is sucessfull
      console.log "synching"
      @storedContent = @get("content")
      @dirty=false
      @trigger "saved"
      
  class ProjectFiles extends Backbone.Collection
    model: ProjectFile
    #localStorage: new Backbone.LocalStorage("_")
    ###
    parse: (response)=>
      console.log("in projFiles parse")
      for i, v of response
        response[i] = new ProjectFile(v)
        response[i].collection = @
        
      console.log response      
      return response  
    ###
    
  class Project extends Backbone.Model
    """Main aspect of coffeescad : contains all the parts
    * project is a top level element ("folder"+metadata)
    * a project contains files /parts
    * a project can reference another project (includes)
    """
    
    idAttribute: 'name'
    defaults:
      name:     "TestProject"
      lastModificationDate: null
      
    @exporter : new CsgStlExporterMin()
    @csgProcessor : new CsgProcessor()
    
    constructor:(options)->
      super options
      @dirty    = false #based on propagation from project files : if a project file is changed, the project is tagged as "dirty" aswell
      @new      = true
      @bind("reset", @onReset)
      @bind("sync",  @onSync)
      @bind("change",@onChanged)
      @files = []
      @pfiles = new ProjectFiles()
      
      locStorName = @get("name")+"-parts"
      @pfiles.localStorage= new Backbone.LocalStorage(locStorName)
      storageType = "localStorage"#can be localStorage, dropbox, github
      
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
      
    onChanged:(settings, value)->
      @dirty=true
      for key, val of @changedAttributes()
        switch key
          when "name"
            locStorName = val+"-parts"
            @pfiles.localStorage= new Backbone.LocalStorage(locStorName)
            
    onPartSaved:(partName)=>
      @set("lastModificationDate",new Date())
      for part of @pfiles
        if part.dirty
          return
      @trigger "allSaved"
      
    onPartChanged:()=>
      
    isNew2:()->
      return @new 
      
    add:(pFile)=>
      @pfiles.add pFile
      @files.push pFile.get("name")
      pFile.bind("change", ()=> @trigger "change")
      pFile.bind("saved" , ()=> @onPartSaved(pFile.get("id")))
      pFile.bind("dirtied", ()=> @trigger "dirtied")
      pFile.bind("cleaned", ()=> @onPartSaved(pFile.get("id")))
    
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
      
    export:(format)->
      
    ###
    parse: (response)=>
      console.log("in proj parse")
      console.log response
      return response
    ###
      
  return {ProjectFile,Project}
