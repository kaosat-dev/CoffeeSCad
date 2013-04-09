define (require) ->
  Marionette = require 'marionette'
  
  include = (mixins...) ->
      throw new Error('include(mixins...) requires at least one mixin') unless mixins and mixins.length > 0
  
      for mixin in mixins
        for key, value of mixin
          @::[key] = value unless key is 'included'
  
        mixin.included?.apply(this)
      this

  Backbone.Model.include = Backbone.Collection.include = include
  Backbone.View.include = Backbone.Router.include = include
  Backbone.Marionette.ItemView.include = Backbone.Marionette.CollectionView.include = include
  Backbone.Marionette.CompositeView.include = Backbone.Marionette.View.include = include
  
  return include