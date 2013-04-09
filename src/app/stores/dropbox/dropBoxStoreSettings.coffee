define (require)->
  
  class DropBoxStoreSettings extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name: "DropBoxStore"
      title: "DropBox Store"
      configured  : false
      
    constructor:(options)->
      super options
      @dropBoxStorage = require './dropboxStorage'
    
    login:->
      @dropBoxStorage.authentificate()