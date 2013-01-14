define (require)->
  
  class DropBoxConnectorSettings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "DropBoxConnector"
      title: "DropBox Connector"
      configured  : false
      
    constructor:(options)->
      super options
      @dropBoxStorage = require './dropboxStorage'
    
    login:->
      @dropBoxStorage.authentificate()