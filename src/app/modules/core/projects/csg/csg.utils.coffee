define (require)->
  maths = require './csg.maths'
  console.log "in utils, looking for maths"
  Vector2D = maths.Vector2D
  Vector3D = maths.Vector3D
  Vertex   = maths.Vertex
  Line2D   = maths.Line2D
  OrthoNormalBasis = maths.OrthoNormalBasis
  Polygon = maths.Polygon
  
  CSG={}

  CSG.parseOption = (options, optionname, defaultvalue) ->
    # Parse an option from the options object
    # If the option is not present, return the default value
    result = defaultvalue
    result = options[optionname]  if optionname of options  if options
    result
  
  CSG.parseOptionAs3DVector = (options, optionname, defaultvalue) ->
    # Parse an option and force into a Vector3D. If a scalar is passed it is converted
    # into a vector with equal x,y,z
    result = CSG.parseOption(options, optionname, defaultvalue)
    result = new Vector3D(result)
    result
  
  CSG.parseOptionAs2DVector = (options, optionname, defaultvalue) ->
    # Parse an option and force into a Vector2D. If a scalar is passed it is converted
    # into a vector with equal x,y
    result = CSG.parseOption(options, optionname, defaultvalue)
    result = new Vector2D(result)
    result
  
  CSG.parseOptionAsFloat = (options, optionname, defaultvalue) ->
    result = CSG.parseOption(options, optionname, defaultvalue)
    if typeof (result) is "string"
      result = Number(result)
    else throw new Error("Parameter " + optionname + " should be a number")  unless typeof (result) is "number"
    result
  
  CSG.parseOptionAsInt = (options, optionname, defaultvalue) ->
    result = CSG.parseOption(options, optionname, defaultvalue)
    Number Math.floor(result)
  
  CSG.parseOptionAsBool = (options, optionname, defaultvalue) ->
    result = CSG.parseOption(options, optionname, defaultvalue)
    if typeof (result) is "string"
      result = true  if result is "true"
      result = false  if result is "false"
      result = false  if result is 0
    result = !!result
    result
  
  

  CSG.solve2Linear = (a, b, c, d, u, v) ->
    # solve 2x2 linear equation:
    # [ab][x] = [u]
    # [cd][y]   [v]
    det = a * d - b * c
    invdet = 1.0 / det
    x = u * d - b * v
    y = -u * c + a * v
    x *= invdet
    y *= invdet
    [x, y]
    
  insertSorted = (array, element, comparefunc) ->
    leftbound = 0
    rightbound = array.length
    while rightbound > leftbound
      testindex = Math.floor((leftbound + rightbound) / 2)
      testelement = array[testindex]
      compareresult = comparefunc(element, testelement)
      if compareresult > 0 # element > testelement
        leftbound = testindex + 1
      else
        rightbound = testindex
    array.splice leftbound, 0, element
    
  CSG.interpolateBetween2DPointsForY = (point1, point2, y) ->
    # Get the x coordinate of a point with a certain y coordinate, interpolated between two
    # points (Vector2D).
    # Interpolation is robust even if the points have the same y coordinate
    f1 = y - point1.y
    f2 = point2.y - point1.y
    if f2 < 0
      f1 = -f1
      f2 = -f2
    t = undefined
    if f1 <= 0
      t = 0.0
    else if f1 >= f2
      t = 1.0
    else if f2 < 1e-10
      t = 0.5
    else
      t = f1 / f2
    result = point1.x + t * (point2.x - point1.x)
    result
  
  CSG.reTesselateCoplanarPolygons = (sourcepolygons, destpolygons) ->
    # Retesselation function for a set of coplanar polygons. See the introduction at the top of
    # this file.
    EPS = 1e-5
    numpolygons = sourcepolygons.length
    if numpolygons > 0
      plane = sourcepolygons[0].plane
      shared = sourcepolygons[0].shared
      orthobasis = new OrthoNormalBasis(plane)
      polygonvertices2d = [] # array of array of Vector2D
      polygontopvertexindexes = [] # array of indexes of topmost vertex per polygon
      topy2polygonindexes = {}
      ycoordinatetopolygonindexes = {}
      xcoordinatebins = {}
      ycoordinatebins = {}
      
      # convert all polygon vertices to 2D
      # Make a list of all encountered y coordinates
      # And build a map of all polygons that have a vertex at a certain y coordinate:    
      ycoordinateBinningFactor = 1.0 / EPS * 10
      polygonindex = 0
  
      while polygonindex < numpolygons
        poly3d = sourcepolygons[polygonindex]
        vertices2d = []
        numvertices = poly3d.vertices.length
        minindex = -1
        if numvertices > 0
          miny = undefined
          maxy = undefined
          maxindex = undefined
          i = 0
  
          while i < numvertices
            pos2d = orthobasis.to2D(poly3d.vertices[i].pos)
            
            # perform binning of y coordinates: If we have multiple vertices very
            # close to each other, give them the same y coordinate:
            ycoordinatebin = Math.floor(pos2d.y * ycoordinateBinningFactor)
            newy = undefined
            if ycoordinatebin of ycoordinatebins
              newy = ycoordinatebins[ycoordinatebin]
            else if ycoordinatebin + 1 of ycoordinatebins
              newy = ycoordinatebins[ycoordinatebin + 1]
            else if ycoordinatebin - 1 of ycoordinatebins
              newy = ycoordinatebins[ycoordinatebin - 1]
            else
              newy = pos2d.y
              ycoordinatebins[ycoordinatebin] = pos2d.y
            pos2d = new Vector2D(pos2d.x, newy)
            vertices2d.push pos2d
            y = pos2d.y
            if (i is 0) or (y < miny)
              miny = y
              minindex = i
            if (i is 0) or (y > maxy)
              maxy = y
              maxindex = i
            ycoordinatetopolygonindexes[y] = {}  unless y of ycoordinatetopolygonindexes
            ycoordinatetopolygonindexes[y][polygonindex] = true
            i++
          if miny >= maxy
            
            # degenerate polygon, all vertices have same y coordinate. Just ignore it from now:
            vertices2d = []
          else
            topy2polygonindexes[miny] = []  unless miny of topy2polygonindexes
            topy2polygonindexes[miny].push polygonindex
        # if(numvertices > 0)
        # reverse the vertex order:
        vertices2d.reverse()
        minindex = numvertices - minindex - 1
        polygonvertices2d.push vertices2d
        polygontopvertexindexes.push minindex
        polygonindex++
      ycoordinates = []
      for ycoordinate of ycoordinatetopolygonindexes
        ycoordinates.push ycoordinate
      ycoordinates.sort (a, b) ->
        a - b
  
      
      # Now we will iterate over all y coordinates, from lowest to highest y coordinate
      # activepolygons: source polygons that are 'active', i.e. intersect with our y coordinate
      #   Is sorted so the polygons are in left to right order
      # Each element in activepolygons has these properties:
      #        polygonindex: the index of the source polygon (i.e. an index into the sourcepolygons and polygonvertices2d arrays)
      #        leftvertexindex: the index of the vertex at the left side of the polygon (lowest x) that is at or just above the current y coordinate
      #        rightvertexindex: dito at right hand side of polygon
      #        topleft, bottomleft: coordinates of the left side of the polygon crossing the current y coordinate  
      #        topright, bottomright: coordinates of the right hand side of the polygon crossing the current y coordinate  
      activepolygons = []
      prevoutpolygonrow = []
      yindex = 0
  
      while yindex < ycoordinates.length
        newoutpolygonrow = []
        ycoordinate_as_string = ycoordinates[yindex]
        ycoordinate = Number(ycoordinate_as_string)
        
        # update activepolygons for this y coordinate:
        # - Remove any polygons that end at this y coordinate
        # - update leftvertexindex and rightvertexindex (which point to the current vertex index 
        #   at the the left and right side of the polygon
        # Iterate over all polygons that have a corner at this y coordinate:
        polygonindexeswithcorner = ycoordinatetopolygonindexes[ycoordinate_as_string]
        activepolygonindex = 0
  
        while activepolygonindex < activepolygons.length
          activepolygon = activepolygons[activepolygonindex]
          polygonindex = activepolygon.polygonindex
          if polygonindexeswithcorner[polygonindex]
            
            # this active polygon has a corner at this y coordinate:
            vertices2d = polygonvertices2d[polygonindex]
            numvertices = vertices2d.length
            newleftvertexindex = activepolygon.leftvertexindex
            newrightvertexindex = activepolygon.rightvertexindex
            
            # See if we need to increase leftvertexindex or decrease rightvertexindex:
            loop
              nextleftvertexindex = newleftvertexindex + 1
              nextleftvertexindex = 0  if nextleftvertexindex >= numvertices
              break  unless vertices2d[nextleftvertexindex].y is ycoordinate
              newleftvertexindex = nextleftvertexindex
            nextrightvertexindex = newrightvertexindex - 1
            nextrightvertexindex = numvertices - 1  if nextrightvertexindex < 0
            newrightvertexindex = nextrightvertexindex  if vertices2d[nextrightvertexindex].y is ycoordinate
            if (newleftvertexindex isnt activepolygon.leftvertexindex) and (newleftvertexindex is newrightvertexindex)
              
              # We have increased leftvertexindex or decreased rightvertexindex, and now they point to the same vertex
              # This means that this is the bottom point of the polygon. We'll remove it:
              activepolygons.splice activepolygonindex, 1
              --activepolygonindex
            else
              activepolygon.leftvertexindex = newleftvertexindex
              activepolygon.rightvertexindex = newrightvertexindex
              activepolygon.topleft = vertices2d[newleftvertexindex]
              activepolygon.topright = vertices2d[newrightvertexindex]
              nextleftvertexindex = newleftvertexindex + 1
              nextleftvertexindex = 0  if nextleftvertexindex >= numvertices
              activepolygon.bottomleft = vertices2d[nextleftvertexindex]
              nextrightvertexindex = newrightvertexindex - 1
              nextrightvertexindex = numvertices - 1  if nextrightvertexindex < 0
              activepolygon.bottomright = vertices2d[nextrightvertexindex]
          ++activepolygonindex
        # if polygon has corner here
        # for activepolygonindex
        nextycoordinate = undefined
        if yindex >= ycoordinates.length - 1
          
          # last row, all polygons must be finished here:
          activepolygons = []
          nextycoordinate = null
        # yindex < ycoordinates.length-1
        else
          nextycoordinate = Number(ycoordinates[yindex + 1])
          middleycoordinate = 0.5 * (ycoordinate + nextycoordinate)
          
          # update activepolygons by adding any polygons that start here: 
          startingpolygonindexes = topy2polygonindexes[ycoordinate_as_string]
          for polygonindex_key of startingpolygonindexes
            polygonindex = startingpolygonindexes[polygonindex_key]
            vertices2d = polygonvertices2d[polygonindex]
            numvertices = vertices2d.length
            topvertexindex = polygontopvertexindexes[polygonindex]
            
            # the top of the polygon may be a horizontal line. In that case topvertexindex can point to any point on this line.
            # Find the left and right topmost vertices which have the current y coordinate:
            topleftvertexindex = topvertexindex
            loop
              i = topleftvertexindex + 1
              i = 0  if i >= numvertices
              break  unless vertices2d[i].y is ycoordinate
              break  if i is topvertexindex # should not happen, but just to prevent endless loops
              topleftvertexindex = i
            toprightvertexindex = topvertexindex
            loop
              i = toprightvertexindex - 1
              i = numvertices - 1  if i < 0
              break  unless vertices2d[i].y is ycoordinate
              break  if i is topleftvertexindex # should not happen, but just to prevent endless loops
              toprightvertexindex = i
            nextleftvertexindex = topleftvertexindex + 1
            nextleftvertexindex = 0  if nextleftvertexindex >= numvertices
            nextrightvertexindex = toprightvertexindex - 1
            nextrightvertexindex = numvertices - 1  if nextrightvertexindex < 0
            newactivepolygon =
              polygonindex: polygonindex
              leftvertexindex: topleftvertexindex
              rightvertexindex: toprightvertexindex
              topleft: vertices2d[topleftvertexindex]
              topright: vertices2d[toprightvertexindex]
              bottomleft: vertices2d[nextleftvertexindex]
              bottomright: vertices2d[nextrightvertexindex]
  
            insertSorted activepolygons, newactivepolygon, (el1, el2) ->
              x1 = CSG.interpolateBetween2DPointsForY(el1.topleft, el1.bottomleft, middleycoordinate)
              x2 = CSG.interpolateBetween2DPointsForY(el2.topleft, el2.bottomleft, middleycoordinate)
              return 1  if x1 > x2
              return -1  if x1 < x2
              0
  
        # for(var polygonindex in startingpolygonindexes)
        #  yindex < ycoordinates.length-1
        #if( (yindex == ycoordinates.length-1) || (nextycoordinate - ycoordinate > EPS) )
        if true
          
          # Now activepolygons is up to date
          # Build the output polygons for the next row in newoutpolygonrow:
          for activepolygon_key of activepolygons
            activepolygon = activepolygons[activepolygon_key]
            polygonindex = activepolygon.polygonindex
            vertices2d = polygonvertices2d[polygonindex]
            numvertices = vertices2d.length
            x = CSG.interpolateBetween2DPointsForY(activepolygon.topleft, activepolygon.bottomleft, ycoordinate)
            topleft = new Vector2D(x, ycoordinate)
            x = CSG.interpolateBetween2DPointsForY(activepolygon.topright, activepolygon.bottomright, ycoordinate)
            topright = new Vector2D(x, ycoordinate)
            x = CSG.interpolateBetween2DPointsForY(activepolygon.topleft, activepolygon.bottomleft, nextycoordinate)
            bottomleft = new Vector2D(x, nextycoordinate)
            x = CSG.interpolateBetween2DPointsForY(activepolygon.topright, activepolygon.bottomright, nextycoordinate)
            bottomright = new Vector2D(x, nextycoordinate)
            outpolygon =
              topleft: topleft
              topright: topright
              bottomleft: bottomleft
              bottomright: bottomright
              leftline: Line2D.fromPoints(topleft, bottomleft)
              rightline: Line2D.fromPoints(bottomright, topright)
  
            if newoutpolygonrow.length > 0
              prevoutpolygon = newoutpolygonrow[newoutpolygonrow.length - 1]
              d1 = outpolygon.topleft.distanceTo(prevoutpolygon.topright)
              d2 = outpolygon.bottomleft.distanceTo(prevoutpolygon.bottomright)
              if (d1 < EPS) and (d2 < EPS)
                
                # we can join this polygon with the one to the left:
                outpolygon.topleft = prevoutpolygon.topleft
                outpolygon.leftline = prevoutpolygon.leftline
                outpolygon.bottomleft = prevoutpolygon.bottomleft
                newoutpolygonrow.splice newoutpolygonrow.length - 1, 1
            newoutpolygonrow.push outpolygon
          # for(activepolygon in activepolygons)
          if yindex > 0
            
            # try to match the new polygons against the previous row:
            prevcontinuedindexes = {}
            matchedindexes = {}
            i = 0
  
            while i < newoutpolygonrow.length
              thispolygon = newoutpolygonrow[i]
              ii = 0
  
              while ii < prevoutpolygonrow.length
                unless matchedindexes[ii] # not already processed?
                  
                  # We have a match if the sidelines are equal or if the top coordinates
                  # are on the sidelines of the previous polygon
                  prevpolygon = prevoutpolygonrow[ii]
                  if prevpolygon.bottomleft.distanceTo(thispolygon.topleft) < EPS
                    if prevpolygon.bottomright.distanceTo(thispolygon.topright) < EPS
                      
                      # Yes, the top of this polygon matches the bottom of the previous:
                      matchedindexes[ii] = true
                      
                      # Now check if the joined polygon would remain convex:
                      d1 = thispolygon.leftline.direction().x - prevpolygon.leftline.direction().x
                      d2 = thispolygon.rightline.direction().x - prevpolygon.rightline.direction().x
                      leftlinecontinues = Math.abs(d1) < EPS
                      rightlinecontinues = Math.abs(d2) < EPS
                      leftlineisconvex = leftlinecontinues or (d1 >= 0)
                      rightlineisconvex = rightlinecontinues or (d2 >= 0)
                      if leftlineisconvex and rightlineisconvex
                        
                        # yes, both sides have convex corners:
                        # This polygon will continue the previous polygon
                        thispolygon.outpolygon = prevpolygon.outpolygon
                        thispolygon.leftlinecontinues = leftlinecontinues
                        thispolygon.rightlinecontinues = rightlinecontinues
                        prevcontinuedindexes[ii] = true
                      break
                ii++
              i++
            # if(!prevcontinuedindexes[ii])
            # for ii
            # for i
            ii = 0
  
            while ii < prevoutpolygonrow.length
              unless prevcontinuedindexes[ii]
                
                # polygon ends here
                # Finish the polygon with the last point(s):
                prevpolygon = prevoutpolygonrow[ii]
                prevpolygon.outpolygon.rightpoints.push prevpolygon.bottomright
                
                # polygon ends with a horizontal line:
                prevpolygon.outpolygon.leftpoints.push prevpolygon.bottomleft  if prevpolygon.bottomright.distanceTo(prevpolygon.bottomleft) > EPS
                
                # reverse the left half so we get a counterclockwise circle:
                prevpolygon.outpolygon.leftpoints.reverse()
                points2d = prevpolygon.outpolygon.rightpoints.concat(prevpolygon.outpolygon.leftpoints)
                vertices3d = []
                points2d.map (point2d) ->
                  point3d = orthobasis.to3D(point2d)
                  vertex3d = new Vertex(point3d)
                  vertices3d.push vertex3d
  
                polygon = new Polygon(vertices3d, shared, plane)
                destpolygons.push polygon
              ii++
          # if(yindex > 0)
          i = 0
  
          while i < newoutpolygonrow.length
            thispolygon = newoutpolygonrow[i]
            unless thispolygon.outpolygon
              
              # polygon starts here:
              thispolygon.outpolygon =
                leftpoints: []
                rightpoints: []
  
              thispolygon.outpolygon.leftpoints.push thispolygon.topleft
              
              # we have a horizontal line at the top:
              thispolygon.outpolygon.rightpoints.push thispolygon.topright  if thispolygon.topleft.distanceTo(thispolygon.topright) > EPS
            else
              
              # continuation of a previous row
              thispolygon.outpolygon.leftpoints.push thispolygon.topleft  unless thispolygon.leftlinecontinues
              thispolygon.outpolygon.rightpoints.push thispolygon.topright  unless thispolygon.rightlinecontinues
            i++
          prevoutpolygonrow = newoutpolygonrow
        yindex++
  
  
  class CSG.fuzzyFactory
    # This class acts as a factory for objects. We can search for an object with approximately
    # the desired properties (say a rectangle with width 2 and height 1) 
    # The lookupOrCreate() method looks for an existing object (for example it may find an existing rectangle
    # with width 2.0001 and height 0.999. If no object is found, the user supplied callback is
    # called, which should generate a new object. The new object is inserted into the database
    # so it can be found by future lookupOrCreate() calls.
    constructor : (numdimensions, tolerance) ->
      # Constructor:
      #   numdimensions: the number of parameters for each object
      #     for example for a 2D rectangle this would be 2
      #   tolerance: The maximum difference for each parameter allowed to be considered a match
      lookuptable = []
      i = 0
    
      while i < numdimensions
        lookuptable.push {}
        i++
      @lookuptable = lookuptable
      @nextElementId = 1
      @multiplier = 1.0 / tolerance
      @objectTable = {}
  
    lookupOrCreate: (els, creatorCallback) ->
      # var obj = f.lookupOrCreate([el1, el2, el3], function(elements) {/* create the new object */});
      # Performs a fuzzy lookup of the object with the specified elements.
      # If found, returns the existing object
      # If not found, calls the supplied callback function which should create a new object with
      # the specified properties. This object is inserted in the lookup database.
      object = undefined
      key = @lookupKey(els)
      if key is null
        object = creatorCallback(els)
        key = @nextElementId++
        @objectTable[key] = object
        dimension = 0
  
        while dimension < els.length
          elementLookupTable = @lookuptable[dimension]
          value = els[dimension]
          valueMultiplied = value * @multiplier
          valueQuantized1 = Math.floor(valueMultiplied)
          valueQuantized2 = Math.ceil(valueMultiplied)
          CSG.fuzzyFactory.insertKey key, elementLookupTable, valueQuantized1
          CSG.fuzzyFactory.insertKey key, elementLookupTable, valueQuantized2
          dimension++
      else
        object = @objectTable[key]
      object
  
    # ----------- PRIVATE METHODS:
    lookupKey: (els) ->
      keyset = {}
      dimension = 0
  
      while dimension < els.length
        elementLookupTable = @lookuptable[dimension]
        value = els[dimension]
        valueQuantized = Math.round(value * @multiplier)
        valueQuantized += ""
        if valueQuantized of elementLookupTable
          if dimension is 0
            keyset = elementLookupTable[valueQuantized]
          else
            keyset = CSG.fuzzyFactory.intersectSets(keyset, elementLookupTable[valueQuantized])
        else
          return null
        return null  if CSG.fuzzyFactory.isEmptySet(keyset)
        dimension++
      
      # return first matching key:
      for key of keyset
        return key
      null
  
    lookupKeySetForDimension: (dimension, value) ->
      result = undefined
      elementLookupTable = @lookuptable[dimension]
      valueMultiplied = value * @multiplier
      valueQuantized = Math.floor(value * @multiplier)
      if valueQuantized of elementLookupTable
        result = elementLookupTable[valueQuantized]
      else
        result = {}
      result
  
    @insertKey : (key, lookuptable, quantizedvalue) ->
      if quantizedvalue of lookuptable
        lookuptable[quantizedvalue][key] = true
      else
        newset = {}
        newset[key] = true
        lookuptable[quantizedvalue] = newset
  
    @isEmptySet = (obj) ->
      for key of obj
        return false
      true
    
    @intersectSets = (set1, set2) ->
      result = {}
      for key of set1
        result[key] = true  if key of set2
      result
    
     @joinSets = (set1, set2) ->
      result = {}
      for key of set1
        result[key] = true
      for key of set2
        result[key] = true
      result
  
  
  class CSG.FuzzyCSGFactory 
    constructor: ->
      @vertexfactory = new CSG.fuzzyFactory(3, 1e-5)
      @planefactory = new CSG.fuzzyFactory(4, 1e-5)
      @polygonsharedfactory = {}
  
    getPolygonShared: (sourceshared) ->
      hash = sourceshared.getHash()
      if hash of @polygonsharedfactory
        @polygonsharedfactory[hash]
      else
        @polygonsharedfactory[hash] = sourceshared
        sourceshared
  
    getVertex: (sourcevertex) ->
      elements = [sourcevertex.pos._x, sourcevertex.pos._y, sourcevertex.pos._z]
      result = @vertexfactory.lookupOrCreate(elements, (els) ->
        sourcevertex
      )
      result
  
    getPlane: (sourceplane) ->
      elements = [sourceplane.normal._x, sourceplane.normal._y, sourceplane.normal._z, sourceplane.w]
      result = @planefactory.lookupOrCreate(elements, (els) ->
        sourceplane
      )
      result
  
    getPolygon: (sourcepolygon) ->
      newplane = @getPlane(sourcepolygon.plane)
      newshared = @getPolygonShared(sourcepolygon.shared)
      _this = this
      newvertices = sourcepolygon.vertices.map((vertex) ->
        _this.getVertex vertex
      )
      new Polygon(newvertices, newshared, newplane)
  
    getCSG: (sourceCsg) ->
      #deprecated
      _this = this
      newpolygons = sourceCsg.polygons.map((polygon) ->
        _this.getPolygon polygon
      )
      CSGBase.fromPolygons newpolygons
      
    getCSGPolygons: (sourceCsg) ->
      _this = this
      newpolygons = sourceCsg.polygons.map((polygon) ->
        _this.getPolygon polygon
      )
      newpolygons


  class CSG.FuzzyCAGFactory
    @vertexfactory = new CSG.FuzzyCSGFactory(2, 1e-5)
  
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
      
      
  return CSG  
  ### 
  return {
    "CSG":
      "parseOption": CSG.parseOption
      "parseOptionAs3DVector": CSG.parseOptionAs3DVector  
      "parseOptionAs2DVector": CSG.parseOptionAs2DVector
      "parseOptionAsFloat": CSG.parseOptionAsFloat
      "parseOptionAsInt": CSG.parseOptionAsInt
      "parseOptionAsBool": CSG.parseOptionAsBool
      "IsFloat": CSG.IsFloat
      "solve2Linear": CSG.solve2Linear
      "insertSorted": insertSorted
      "interpolateBetween2DPointsForY": CSG.interpolateBetween2DPointsForY 
      "reTesselateCoplanarPolygons": CSG.reTesselateCoplanarPolygons 
      "fuzzyFactory": CSG.fuzzyFactory 
      "fuzzyCSGFactory": CSG.fuzzyCSGFactory 
  }###
