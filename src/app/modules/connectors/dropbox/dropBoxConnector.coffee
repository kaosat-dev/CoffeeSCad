define (require)->
  backbone_dropbox = require './backbone.dropbox'
  
  vent = require 'modules/core/vent'
  
  class DropBoxConnector
    constructor:(options)->
      @store = new backbone_dropbox()
      @loggedIn = true
      @vent = vent
      @vent.on("dropBoxConnector:login", @login)
      @vent.on("dropBoxConnector:logout", @logout)
      
    login:=>
      try
        @store.authentificate()
        @loggedIn = true
        @vent.trigger("dropBoxConnector:loggedIn")
      catch error
        @vent.trigger("dropBoxConnector:loginFailed")
        
    logout:=>
      try
        @store.signOut()
        @loggedIn = false
        @vent.trigger("dropBoxConnector:loggedOut")
      catch error
        @vent.trigger("dropBoxConnector:logoutFailed")
    

  return DropBoxConnector