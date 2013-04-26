define (require) ->
  
  class ModuleRegistry
    constructor:->
      @modules = []
      
    registerSubApp:(module)->
    