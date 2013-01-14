define (require) ->
  utils = require "modules/core/utils/utils"
  
  class BomExporter
    ###
    exports the given projects' bom (BILL of material) as a json file
    ###
    
    constructor:->
      @mimeType = "application/sla"
    
    export:(project)=>
      
  return BomExporter
 
  