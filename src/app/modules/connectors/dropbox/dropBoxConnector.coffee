define (require)->
  backbone_dropbox = require './backbone.dropbox'
  
  vent = require 'modules/core/vent'
  
  class DropBoxConnector
    constructor:(options)->
      @store = new backbone_dropbox()
      @vent = vent
      @vent.on("dropBoxConnector:login", @login)
      
    login:=>
      try
        @store.authentificate()
        @vent.trigger("dropBoxConnector:loggedIn")
      catch error
        @vent.trigger("dropBoxConnector:loginFailed")
        
    logout:=>
      try
        @store.signOut()
      catch error
        @vent.trigger("dropBoxConnector:logoutFailed")
    

  return DropBoxConnector