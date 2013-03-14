define (require)->
  marionette = require 'marionette'
  modelBinder = require 'modelbinder'
  collectionBinder = require 'collectionbinder'
  
  class BoundView extends Backbone.Marionette.ItemView
    constructor: ->
      @__modelBinder__ = new Backbone.ModelBinder()
      @rebindModel()

    close: ->
      @__modelBinder__.unbind()

    rebindModel: ->
      @__modelBinder__.bind @model, @$el,@modelBindings

    setModel: (model)->
      @model = model
      @rebindModel()
  
  class BoundCollectionView extends Backbone.Marionette.CollectionView
    
    constructor:(options)->
      super options
      elManagerFactory = new Backbone.CollectionBinder.ElManagerFactory options.template, @modelBindings
      @__collectionBinder__ = new Backbone.CollectionBinder(elManagerFactory)
      @rebindCollection()
  
    rebindCollection: ->
      @__collectionBinder__.bind(@collection, @$el)
  
    close: ->
      @__collectionBinder__.unbind()
  
    getModelForEl: (el)->
      @__collectionBinder__.getManagerForEl(el).getModel()
      

  return {"BoundView":BoundView,"BoundCollectionView":BoundCollectionView}
