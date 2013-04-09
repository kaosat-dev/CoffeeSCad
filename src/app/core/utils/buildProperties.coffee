define (require)->
  buildProperties = (func) ->
    #based on https://gist.github.com/ndnichols/4079943
    buildGetter = (name) ->
      -> @get name
    buildSetter = (name) ->
      (value) -> @set name, value
    for attr in func.prototype.attributeNames
      Object.defineProperty func.prototype, attr,
        get: buildGetter attr
        set: buildSetter attr
 
  return buildProperties