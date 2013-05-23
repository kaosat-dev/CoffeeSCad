define (require)->
  StoreBase = require '../storeBase2'
  utils = require 'core/utils/utils'
  merge = utils.merge
  
  class NodeJsStore extends StoreBase
    constructor:(options)->
      defaults= {
        type: "node"
        name: "nodeStore"
        shortName: "node"
        description: "node js local file system store"
        rootUri:  process.env.HOME or process.env.HOMEPATH or process.env.USERPROFILE
      }
      options = merge defaults, options
      super options
      
      @fs = require './nodeFS'
    
    listProjects:( uri )=>
      deferred =  $.Deferred()
      $.when( @fs.readdir(uri) ).done( (files)->
        projectsList = []
        for file in files
          if @fs.isProj( file )
            projectsList.push( file )
        deferred.resolve( projectsList )
        )
      return deferred

    
      
    
