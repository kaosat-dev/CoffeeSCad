define (require)->
  #globals = require './globals'
  #maths = require './maths'
  require 'three'
  
  merge = (options, overrides) ->
    extend (extend {}, options), overrides

  extend = (object, properties) ->
    for key, val of properties
      object[key] = val
    object
    
  
  parseOptions = (options, defaults)->
    if  Object.getPrototypeOf( options ) == Object.prototype
      options = merge defaults, options
    else if options instanceof Array
      indexToName = {}
      result = {}
      index =0
      for own key,val of defaults
        indexToName[index]=key
        result[key]=val
        index++
        
      for option, index in options
        if option?
          name = indexToName[index]
          result[name]=option
      
      options = result
    return options  

  parseOption = (options, optionname, defaultvalue) ->
    # Parse an option from the options object
    # If the option is not present, return the default value
    result = defaultvalue
    result = options[optionname]  if optionname of options  if options
    result
  
  parseOptionAs3DVector = (options, optionname, defaultValue, defaultValue2) ->
    # Parse an option and force into a THREE.Vector3. If a scalar is passed it is converted
    # into a vector with equal x,y,z, if a boolean is passed and is true, take defaultvalue, otherwise defaultvalue2
    if optionname of options
      if options[optionname] == false or options[optionname] == true
        doCenter = parseOptionAsBool(options,optionname,false)  
        if doCenter
          options[optionname]=defaultValue
        else
          options[optionname]=defaultValue2
    
    result = parseOption(options, optionname, defaultValue)
    
    if result instanceof Array
      if result.length == 3
        result = new THREE.Vector3(result[0], result[1], result[2])
      else if result.length == 2
        result = new THREE.Vector3(result[0], result[1], 1)
      else if result.length == 1
        result = new THREE.Vector3(result[0], 1, 1)
    else if result instanceof THREE.Vector3
      result = result
    else
      result = new THREE.Vector3(result, result, result)
    result
  
  parseOptionAs2DVector = (options, optionname, defaultValue, defaultValue2) ->
    # Parse an option and force into a THREE.Vector2. If a scalar is passed it is converted
    # into a vector with equal x,y, if a boolean is passed and is true, take defaultvalue, otherwise defaultvalue2
    if optionname of options
      if options[optionname] == false or options[optionname] == true
        doCenter = parseOptionAsBool(options,optionname,false)  
        if doCenter
          options[optionname]=defaultValue
        else
          options[optionname]=defaultValue2
    
    
    result = parseOption(options, optionname, defaultValue)
    result = new THREE.Vector2(result)
    result
  
  parseOptionAsFloat = (options, optionname, defaultvalue) ->
    result = parseOption(options, optionname, defaultvalue)
    if typeof (result) is "string"
      result = Number(result)
    else throw new Error("Parameter " + optionname + " should be a number")  unless typeof (result) is "number"
    result
  
  parseOptionAsInt = (options, optionname, defaultvalue) ->
    result = parseOption(options, optionname, defaultvalue)
    Number Math.floor(result)
  
  parseOptionAsBool = (options, optionname, defaultvalue) ->
    result = parseOption(options, optionname, defaultvalue)
    if typeof (result) is "string"
      result = true  if result is "true"
      result = false  if result is "false"
      result = false  if result is 0
    result = !!result
    result
    
  parseOptionAsLocations = (options, optionName, defaultValue) ->
    result = parseOption(options, optionName, defaultValue)
    #left, right, top, bottom, front back when used alone, overide all others
    #front left front right , top left etc (dual params) override ternary params
    #so by params size : 1>2>3 
    mapping_old = {
    "top":globals.top,
    "bottom":globals.bottom,
    "left":globals.left,
    "right":globals.right,
    "front":globals.front,
    "back":globals.back,
    }

    mapping = {
      "all":(parseInt("111111",2)),
      "top": (parseInt("101111",2)),
      "bottom":parseInt("011111",2),
      "left":parseInt("111011",2),
      "right":parseInt("110111",2),
      "front":parseInt("111110",2),
      "back":parseInt("111101",2)
    }

    stuff = null
    for location in result
      #trim leading and trailing whitespaces
      location = location.replace /^\s+|\s+$/g, ""
      locations =location.split(" ")
      #console.log "location"
      #console.log location 
      subStuff = null
      for loc in locations
        loc = mapping[loc]
        if not subStuff?
          subStuff = loc
        else 
          subStuff = subStuff & loc
      if not stuff?
        stuff = subStuff
      else
        stuff = stuff | subStuff
      
    stuff.toString(2)
    
  parseCenter = (options, optionname, defaultValue, defaultValue2, vectorClass) ->
    # Parse a "center" option and force into a THREE.Vector3. If a scalar is passed it is converted
    # into a vector with equal x,y,z, if a boolean is passed and is true, take defaultvalue, otherwise defaultvalue2
    if optionname of options
      centerOption = options[optionname]
      if centerOption instanceof Array
        newDefaultValue = new vectorClass(defaultValue)
        newDefaultValue2 = new vectorClass(defaultValue2)
        for component, index  in centerOption
          if typeof component is 'boolean'
            if index is 0 
              centerOption[index] = if component == true then newDefaultValue2.x else if component == false then newDefaultValue.x else centerOption[index]
            else if index is 1
              centerOption[index] = if component == true then newDefaultValue2.y else if component == false then newDefaultValue.y  else centerOption[index]
            else if index is 2
              centerOption[index] = if component == true then newDefaultValue2.z else if component == false then newDefaultValue.z  else centerOption[index]
        options[optionname] = centerOption
      else    
        if typeof centerOption is 'boolean'
          doCenter = parseOptionAsBool(options,optionname,false)  
          if doCenter
            options[optionname]=defaultValue2
          else
            options[optionname]=defaultValue
    
    result = parseOption(options, optionname, defaultValue)
    result = new vectorClass(result)
    result
    
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
    
  interpolateBetween2DPointsForY = (point1, point2, y) ->
    # Get the x coordinate of a point with a certain y coordinate, interpolated between two
    # points (THREE.Vector2).
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
  
  reTesselateCoplanarPolygons = (sourcepolygons, destpolygons) ->
    # Retesselation function for a set of coplanar polygons. See the introduction at the top of
    # this file.
    EPS = 1e-5
    numpolygons = sourcepolygons.length
    if numpolygons > 0
      plane = sourcepolygons[0].plane
      shared = sourcepolygons[0].shared
      orthobasis = new OrthoNormalBasis(plane)
      polygonvertices2d = [] # array of array of THREE.Vector2
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
            pos2d = new THREE.Vector2(pos2d.x, newy)
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
              x1 = interpolateBetween2DPointsForY(el1.topleft, el1.bottomleft, middleycoordinate)
              x2 = interpolateBetween2DPointsForY(el2.topleft, el2.bottomleft, middleycoordinate)
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
            x = interpolateBetween2DPointsForY(activepolygon.topleft, activepolygon.bottomleft, ycoordinate)
            topleft = new THREE.Vector2(x, ycoordinate)
            x = interpolateBetween2DPointsForY(activepolygon.topright, activepolygon.bottomright, ycoordinate)
            topright = new THREE.Vector2(x, ycoordinate)
            x = interpolateBetween2DPointsForY(activepolygon.topleft, activepolygon.bottomleft, nextycoordinate)
            bottomleft = new THREE.Vector2(x, nextycoordinate)
            x = interpolateBetween2DPointsForY(activepolygon.topright, activepolygon.bottomright, nextycoordinate)
            bottomright = new THREE.Vector2(x, nextycoordinate)
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
  
  
  class FuzzyFactory
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
          FuzzyFactory.insertKey key, elementLookupTable, valueQuantized1
          FuzzyFactory.insertKey key, elementLookupTable, valueQuantized2
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
            keyset = FuzzyFactory.intersectSets(keyset, elementLookupTable[valueQuantized])
        else
          return null
        return null  if FuzzyFactory.isEmptySet(keyset)
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
  
    @isEmptySet : (obj) ->
      for key of obj
        return false
      true
    
    @intersectSets : (set1, set2) ->
      result = {}
      for key of set1
        result[key] = true  if key of set2
      result
    
    @joinSets : (set1, set2) ->
      result = {}
      for key of set1
        result[key] = true
      for key of set2
        result[key] = true
      result
  
  
  class FuzzyCSGFactory 
    constructor: ->
      @vertexfactory = new FuzzyFactory(3, 1e-5)
      @planefactory = new FuzzyFactory(4, 1e-5)
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
      newvertices = (@getVertex vertex for vertex in sourcepolygon.vertices)
      new Polygon(newvertices, newshared, newplane)
  
    getCSG: (sourceCsg) ->
      #deprecated
      _this = this
      newpolygons = sourceCsg.polygons.map((polygon) ->
        _this.getPolygon polygon
      )
      CSGBase.fromPolygons newpolygons
      
    getCSGPolygons: (sourceCsg) ->
      #returns new polygons based on sourceCSG
      newpolygons = (@getPolygon polygon for polygon in sourceCsg.polygons)


  class FuzzyCAGFactory
    constructor:->
      @vertexfactory = new FuzzyFactory(2, 1e-5)
  
    getVertex: (sourcevertex) ->
      elements = [sourcevertex.pos._x, sourcevertex.pos._y]
      result = @vertexfactory.lookupOrCreate(elements, (els) ->
        sourcevertex
      )
      result
  
    getSide: (sourceside) ->
      vertex0 = @getVertex(sourceside.vertex0)
      vertex1 = @getVertex(sourceside.vertex1)
      new Side(vertex0, vertex1)
  
    getCAG: (sourcecag) ->
      _this = this
      newsides = sourcecag.sides.map((side) ->
        _this.getSide side
      )
      CAGBase.fromSides newsides
      
    getCAGSides:(sourceCag) ->
      _this = this
      newsides = sourceCag.sides.map((side) ->
        _this.getSide side
      )
      newsides
  
  return {
      "parseOption": parseOption
      "parseOptions":parseOptions
      "parseOptionAs3DVector": parseOptionAs3DVector  
      "parseOptionAs2DVector": parseOptionAs2DVector
      "parseOptionAsFloat": parseOptionAsFloat
      "parseOptionAsInt": parseOptionAsInt
      "parseOptionAsBool": parseOptionAsBool
      "parseOptionAsLocations":parseOptionAsLocations
      "parseCenter":parseCenter
      "insertSorted": insertSorted
      "interpolateBetween2DPointsForY": interpolateBetween2DPointsForY 
      "reTesselateCoplanarPolygons": reTesselateCoplanarPolygons 
      "FuzzyFactory": FuzzyFactory 
      "FuzzyCSGFactory": FuzzyCSGFactory
      "FuzzyCAGFactory": FuzzyCAGFactory 
      "merge":merge
      "extend":extend
  }
