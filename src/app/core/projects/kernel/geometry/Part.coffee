define (require) ->
  ObjectBase = require '../base'
  
  
  class Part extends ObjectBase
    constructor:(options)->
      super options
      parent= @__proto__.__proto__.constructor.name
      #register(@__proto__.constructor.name, @, options)
      
      defaults = {manufactured:true}
      options = merge defaults, options
      @manufactured = options.manufactured
      
return Part