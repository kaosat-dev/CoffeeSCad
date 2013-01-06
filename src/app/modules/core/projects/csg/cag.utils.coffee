define (require)->
  maths = require './csg.maths'
  utils = require './csg.utils'
  FuzzyCSGFactory = utils.FuzzyCSGFactory
  CAG = {}
  
  class CAG.FuzzyCAGFactory
    @vertexfactory = new FuzzyCSGFactory(2, 1e-5)
  
    getVertex: (sourcevertex) ->
      elements = [sourcevertex.pos._x, sourcevertex.pos._y]
      result = @vertexfactory.lookupOrCreate(elements, (els) ->
        sourcevertex
      )
      result
  
    getSide: (sourceside) ->
      vertex0 = @getVertex(sourceside.vertex0)
      vertex1 = @getVertex(sourceside.vertex1)
      new CAG.Side(vertex0, vertex1)
  
    getCAG: (sourcecag) ->
      _this = this
      newsides = sourcecag.sides.map((side) ->
        _this.getSide side
      )
      CAG.fromSides newsides
      
  return CAG