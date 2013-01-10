define (require)->
  base = require './csg'
  CAGBase = base.CAGBase
  
  maths = require './csg.maths'
  Vertex = maths.Vertex
  Vertex2D = maths.Vertex
  Vector2D = maths.Vector2D
  Side = maths.Side
  
  globals = require './csg.globals'
  defaultResolution2D = globals.defaultResolution2D
  
  utils = require './csg.utils'
  parseOptionAs2DVector = utils.parseOptionAs2DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  
  #set of "global methods"
  union = (csg)->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
    else
      csgs = [csg]
    result = @
    i = 0
    while i < csgs.length
      islast = (i is (csgs.length - 1))
      result = result.unionSub(csgs[i], islast, islast)
      i++
      
  scale = (f, csg) ->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
    else
      csgs = [csg]
    for csg in csgs
      csg.transform Matrix4x4.scaling(f)
      
  #helpers for hull
  sign = (p1,p2,p3)->
    #console.log "in sign"
    #console.log p1
    #console.log p2
    #console.log p3
    #return ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x))
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
  
  isLeft=(a, b, c)->
     return ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x)) > 0
  
  pointLineDist2 = (pt, lineStart, lineEnd)->
    sqr = (x) ->
      x * x
    dist2 = (v, w) ->
      sqr(v.x - w.x) + sqr(v.y - w.y)
    distToSegmentSquared = (p, v, w) ->
      l2 = dist2(v, w)
      return dist2(p, v)  if l2 is 0
      t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2
      return dist2(p, v)  if t < 0
      return dist2(p, w)  if t > 1
      dist2 p,
        x: v.x + t * (w.x - v.x)
        y: v.y + t * (w.y - v.y)
    
    return   distToSegmentSquared(pt, lineStart, lineEnd)
      #Math.sqrt distToSegmentSquared
  
  pointLineDist_old = (pt, lineStart, lineEnd)->
    tmpVect = lineEnd.minus(lineStart)
    tmpVect2 = pt.minus(lineStart)
    
    numer =  tmpVect2.dot(tmpVect)
    if (numer <= 0.0)
      point = lineStart
      return pt.minus(point).length()#lineStart
    denom = tmpVect.dot(tmpVect)
    if (numer >= denom)
      point = lineEnd
      return pt.minus(point).length()
      #return 0#lineEnd
    
    point = lineStart.plus(tmpVect.times(numer/denom))
    return pt.minus(point).length()
 
  pointLineDist = (pt, lineStart, lineEnd)->
    vY = lineEnd.x-lineStart.x
    vX = lineEnd.y-lineStart.y
    return (vX * (pt.x - lineStart.x) + vY * (pt.y - lineStart.y))
    
  pointInTriangle = (pt, v1, v2, v3)->
    ###
    console.log pt
    console.log v1
    console.log v2
    console.log v3
    ###
    b1 = sign(pt, v1, v2) < 0.0
    b2 = sign(pt, v2, v3) < 0.0
    b3 = sign(pt, v3, v1) < 0.0
    return ((b1 == b2) and (b2 == b3))
    
  findFarthestPointAndFilter=(points, minPoint, maxPoint)->
    #console.log " "
    #console.log "min #{minPoint}, max #{maxPoint}"
    #max distance search and removal of points on line
    maxDist = -Infinity
    maxDistPoint = null
    filteredPoints = []
    
    for point in points
      dist = pointLineDist2(point, minPoint, maxPoint)
      #console.log "point: #{point} dist: #{dist} maxdist#{maxDist} "
      if dist>0
        filteredPoints.push(point)
      else
        continue
      if dist > maxDist
        maxDist = dist
        maxDistPoint = point
    #console.log "resultPoints #{filteredPoints}"
    return [maxDistPoint,filteredPoints]
  
  
  removeFromArray=(array, element)->
    index = array.indexOf element
    array.splice(index, 1)
    return array
    
  
  hullSub2=(divLine, points)->
    #divLine : dividing line going from min to max
    #points :  a list of points to process
    #console.log "hullSub2: points:"
    #console.log points
    minPoint = divLine[0]
    maxPoint = divLine[1]
    hullDivLines = []
    result = findFarthestPointAndFilter(points,minPoint,maxPoint)
    furthestPoint=result[0]
    newPoints = result[1]
    #console.log "furthestPoint #{furthestPoint}"
    #console.log "points len #{points}"
    
    if furthestPoint? #did we find a max point ?
      hullDivLines = hullDivLines.concat(hullSub2([minPoint, furthestPoint], newPoints))#left
      hullDivLines = hullDivLines.concat(hullSub2([furthestPoint, maxPoint], newPoints))#right
      hullDivLines
    else # if there is no more point "outside" the base line, the current base line is part of the convex hull
      [divLine]
    
  hullSub2Init=(points)->
    minPoint = {x:+Infinity,y:0}
    maxPoint = {x:-Infinity,y:0}  
    #--------------------------------------
    #Find first two points on the convex hull
   
    for point in points
        if point.x < minPoint.x
          minPoint = point
        if point.x > maxPoint.x
          maxPoint = point
    
    resultPoints = []
    
    leftResult = hullSub2([minPoint,maxPoint],points)
    for pt in leftResult
      resultPoints.push(pt[0])
      resultPoints.push(pt[1])
    
    rightResult = hullSub2([maxPoint,minPoint],points)
    for pt in rightResult
      resultPoints.push(pt[0])
      resultPoints.push(pt[1])
      
    #FILTER DUPLICATES
    posIndex= []
    posExists = (pos)->
      index = "#{pos._x};#{pos._y}"
      if posIndex.indexOf(index) == -1
        posIndex.push index
        return false
      return true
    result = []
    
    lowX = +Infinity
    lowY = +Infinity
    highX = -Infinity
    highY = -Infinity 
    
    for point in resultPoints
      #remove redundant positions
      if not posExists(point)
        result.push(point)
        
        if point.x<lowX
          lowX= point.x
        if point.x>highX
          highX = point.x
        
        if point.y<lowY
          lowY= point.y
        if point.y>highY
          highY = point.y
    
    ####NOW WE NEED TO ORDER THEM CLOCKWISE
    #First find center (integrated with the above)
    centerX = highX - ((highX-lowX) * 0.5)
    centerY = highY - ((highY-lowY) * 0.5)
    center = new Vector2D(centerX,centerY)
    
    comparatorClockwise =(center,a,b)->
      aTanA = Math.atan2(a.y - center.y, a.x - center.x)
      aTanB = Math.atan2(b.y - center.y, b.x - center.x)
      if (aTanA < aTanB)
        return 1
      else if (aTanB > aTanA)
        return -1
      return 0
    
    #console.log "preSort #{result}"
    
    result = result.sort (a,b) ->
      res = comparatorClockwise(center, a,b)
      console.log res
      return res
    #console.log "postSort #{result}"
    result
    
  makeClockWise = (points)->
    #FILTER DUPLICATES
    posIndex= []
    posExists = (pos)->
      index = "#{pos._x};#{pos._y}"
      if posIndex.indexOf(index) == -1
        posIndex.push index
        return false
      return true
    result = []
    
    lowX = +Infinity
    lowY = +Infinity
    highX = -Infinity
    highY = -Infinity 
    
    #remove redundant positions
    for point in points
      if not posExists(point)
        result.push(point)
        
        if point.x<lowX
          lowX= point.x
        if point.x>highX
          highX = point.x
        
        if point.y<lowY
          lowY= point.y
        if point.y>highY
          highY = point.y
    
    centerX = highX - ((highX-lowX) * 0.5)
    centerY = highY - ((highY-lowY) * 0.5)
    center = new Vector2D(centerX,centerY)
    
    comparatorClockwise =(center,a,b)->
      aTanA = Math.atan2(a.y - center.y, a.x - center.x)
      aTanB = Math.atan2(b.y - center.y, b.x - center.x)
      if (aTanA < aTanB)
        return 1
      else if (aTanB > aTanA)
        return -1
      return 0
    result = result.sort (a,b) ->
      return comparatorClockwise(center, a,b)
    result
    
  quickHullSub=(points)->
    console.log "input points:"
    #console.log points
    
    #recursive quickhull function
    if points.length <= 2
      return points
    
    ###
    Array.prototype.remove = (args...) ->
      output = []
      for arg in args
        index = @indexOf arg
        output.push @splice(index, 1) if index isnt -1
      output = output[0] if args.length is 1
      output   
    ###
    
    #utils
    findFarthestPoint=(points, minPoint, maxPoint)->
      console.log "min #{minPoint}, max #{maxPoint}"
      #max distance search
      maxDist = -Infinity
      maxDistPoint = null
      for point in points
        dist = pointLineDist(point, minPoint, maxPoint)
        console.log "point: #{point} dist: #{dist} maxdist#{maxDist} "
        if dist > maxDist
          maxDist = dist
          maxDistPoint = point
      return maxDistPoint
    
    removePoints=(points, maxDistPoint, minPoint, maxPoint)->
      #Point exclusion
      result = points.slice(0)
      toRemove = []
      
      for i in [result.length - 1..0] by -1
        point = result[i]
        if pointInTriangle(point, maxDistPoint, minPoint, maxPoint)
          toRemove.push(point)
          #result.remove(point)    
          result=removeFromArray(result, point)
            
      #console.log "end points count : #{points.length}"
      console.log "removed points:"
      console.log toRemove
      return result
      
    #--------------------------------------
    resultPoints = []
    
    minPoint = {x:+Infinity,y:0}
    maxPoint = {x:-Infinity,y:0}  
    #--------------------------------------
    #Find first two points on the convex hull
   
    for point in points
        if point.x < minPoint.x
          minPoint = point
        if point.x > maxPoint.x
          maxPoint = point
          
    #points.remove(minPoint)
    #points.remove(maxPoint)
    points = removeFromArray(points, minPoint)
    points = removeFromArray(points, maxPoint)
    
    #console.log "MinPoint #{minPoint}, Maxpoint: #{maxPoint}"
    #--------------------------------------
    #divide into two sets of point : on the left and right from the line created by minPoint->maxPoint
    rightSet = []
    leftSet = []
    for point in points
      cross = sign(point,minPoint,maxPoint)
      if cross > 0 #left
        leftSet.push(point)
      else if cross < 0 #right
        rightSet.push(point)
      #we leave out anything on the line (cross ==0)
      
      ###
      if isLeft(minPoint,maxPoint,point)
        leftSet.push(point)
      else
        rightSet.push(point)
      ###
        
    
    #--------------------------------------
    #max distance search & point exclusion
    #console.log "original resultPoints"
    #console.log resultPoints
    if leftSet.length >= 0
      maxDistPoint = findFarthestPoint(leftSet, minPoint, maxPoint)
      if maxDistPoint != null
        #leftSet.remove(maxDistPoint)
        leftSet = removeFromArray(leftSet, maxDistPoint)
      
      ###
      newLeftSet = removePoints(leftSet,maxDistPoint, minPoint, maxPoint)
      #no points deleted we already cut the max
      if newLeftSet.length == leftSet.length
        resultPoints = resultPoints.concat newLeftSet
      else
        leftSet = removePoints(leftSet,maxDistPoint, minPoint, maxPoint)
        subResult = CAGBase.hullSub(leftSet)
        resultPoints = resultPoints.concat subResult
      ###
      subResult = quickHullSub(leftSet)
      resultPoints = resultPoints.concat subResult
    else
      resultPoints = resultPoints.concat leftSet
      
    #-------------------------
    resultPoints.push(minPoint)
    if maxDistPoint? then resultPoints.push(maxDistPoint)
    resultPoints.push(maxPoint) 
    
    #------------------------
    if rightSet.length >= 0
      maxDistPoint = findFarthestPoint(rightSet, minPoint, maxPoint)
      if maxDistPoint != null
        resultPoints.push(maxDistPoint)
        rightSet = removeFromArray(rightSet, maxDistPoint)
        #rightSet.remove(maxDistPoint)
      
      ###
      newRightSet = removePoints(rightSet, maxDistPoint, minPoint, maxPoint)
      if newRightSet.length == rightSet.length
        resultPoints =resultPoints.concat rightSet
      else
        resultPoints = resultPoints.concat CAGBase.hullSub(newRightSet)
      ###
      subResult = quickHullSub(rightSet)
      resultPoints = resultPoints.concat subResult
      
    else
      resultPoints = resultPoints.concat rightSet

    #TODO put the points in the right order to avoid issues: min maxDistPoint max
    #TODO do the left side/right side in the correct order aswell
    return resultPoints    
    
  quickHull2dVar2 = (cag...) ->
    #quickhull hull implementation experiment
    #see here http://westhoffswelt.de/blog/0040_quickhull_introduction_and_php_implementation.html/
    cags = undefined
    if cag instanceof Array
      cags = cag
    else
      cags = [cag]

    #TODO: sort all points for optimising
    points = []
    posIndex= []
    
    posExists = (pos)->
      index = "#{pos._x};#{pos._y}"
      if posIndex.indexOf(index) == -1
        posIndex.push index
        return false
      return true
             
    cags.map (cag) ->
      for side in cag.sides
        v0Pos = side.vertex0.pos
        v1Pos = side.vertex1.pos
        #remove redundant positions
        if not posExists(v0Pos)
          points.push(v0Pos)
        if not posExists(v1Pos)
          points.push(v1Pos)
    
    points = _(points).sortBy (u) -> [u._x, u._y]
    console.log points.length   
    hullPoints = hullSub2Init(points)#CAGBase.hullSub(points)
    console.log("ENDRESULT POINTS: #{hullPoints.length}")
    console.log hullPoints
    result = CAGBase.fromPoints(hullPoints)
    result
  
  quickHull2d_old = (cag...) ->
    #quickhull hull implementation experiment
    #see here http://westhoffswelt.de/blog/0040_quickhull_introduction_and_php_implementation.html/
    cags = undefined
    if cag instanceof Array
      cags = cag
    else
      cags = [cag]

    #TODO: sort all points for optimising
    points = []
    posIndex= []
    
    posExists = (pos)->
      index = "#{pos._x};#{pos._y}"
      if posIndex.indexOf(index) == -1
        posIndex.push index
        return false
      return true
             
    cags.map (cag) ->
      for side in cag.sides
        v0Pos = side.vertex0.pos
        v1Pos = side.vertex1.pos
        #remove redundant positions
        if not posExists(v0Pos)
          points.push(v0Pos)
        if not posExists(v1Pos)
          points.push(v1Pos)
    
    points = _(points).sortBy (u) -> [u._x, u._y]
    console.log points.length   
    hullPoints = quickHullSub(points)#CAGBase.hullSub(points)
    console.log("ENDRESULT POINTS: Length#{hullPoints.length}, points:\n #{hullPoints}")
    hullPoints = makeClockWise(hullPoints)
    
    console.log "finalHullPoints:\n #{hullPoints}"
    result = CAGBase.fromPoints(hullPoints)
    result

  
  filterDuplicatePoints = (points) ->
    
 
  #-----------------------------------------------------------------------------------
  ###FROM THIS POINT ON, implem 3 of quickHULL###
  #utils
  distance = (A, B, C)->
    ABx = B.x-A.x
    ABy = B.y-A.y
    num = ABx*(A.y-C.y)-ABy*(A.x-C.x)
    if (num < 0)
      num = -num
    return num
  
  pointLocation = ( A,  B,  P) ->
    cp1 = (B.x-A.x)*(P.y-A.y) - (B.y-A.y)*(P.x-A.x)
    if cp1>0
      return 1
    return -1
  
  findFarthestPoint=(points, minPoint, maxPoint)->
    #max distance search
    maxDist = -Infinity
    maxDistPoint = null
    for point in points
      dist = distance(point, minPoint, maxPoint)#pointLineDist2(point, minPoint, maxPoint)
      if dist > maxDist
        maxDist = dist
        maxDistPoint = point
    return maxDistPoint
    
  removePoints=(points, maxDistPoint, minPoint, maxPoint)->
    #Point exclusion
    result = points.slice(0)
    toRemove = []
    
    for i in [result.length - 1..0] by -1
      point = result[i]
      if pointInTriangle(point, maxDistPoint, minPoint, maxPoint)
        toRemove.push(point)
        #result.remove(point)    
        result=removeFromArray(result, point)
    console.log "removed points:"
    console.log toRemove
    return result  
  
  getLeftAndRighSets = (points, minPoint, maxPoint)->
    #divide into two sets of points : on the left and right from the line created by minPoint->maxPoint
    rightSet = []
    leftSet = []
    for point in points
      cross = sign(point,minPoint,maxPoint)
      if cross < 0 #left
        leftSet.push(point)
      else if cross > 0 #right
        rightSet.push(point)
      #we leave out anything on the line (cross ==0)
    return [leftSet, rightSet]
    
  quickHullSub3 = (points) ->
    convexHull = []
    if points.length < 3
      return points
    #--------------------------------------
    #Find first two points on the convex hull (min, max)
    minPoint = {x:+Infinity,y:0}
    maxPoint = {x:-Infinity,y:0}  
    for point in points
        if point.x < minPoint.x
          minPoint = point
        if point.x > maxPoint.x
          maxPoint = point
    convexHull.push(minPoint)
    convexHull.push(maxPoint)
    removeFromArray(points, minPoint)
    removeFromArray(points, maxPoint)
    #--------------------------------------
    #divide into two sets of points : on the left and right from the line created by minPoint->maxPoint
    [rightSet,leftSet] = getLeftAndRighSets(points, minPoint, maxPoint)
    hullSet(minPoint, maxPoint, rightSet, convexHull)
    hullSet(maxPoint, minPoint, leftSet, convexHull)
    
    return convexHull
  
  hullSet = (minPoint, maxPoint, set, hull)->  
    insertPosition = hull.indexOf(maxPoint)
    if (set.length == 0)
      return
    if (set.length == 1) 
      p = set[0]
      removeFromArray(set, p)
      hull.splice(insertPosition, 0, p)
      return
    furthestPoint = findFarthestPoint(set, minPoint, maxPoint)
    hull.splice(insertPosition, 0, furthestPoint)
    
    [rightSet,leftSet] = getLeftAndRighSets(set, minPoint, furthestPoint)
    [rightSet2,leftSet2] = getLeftAndRighSets(set, furthestPoint, maxPoint)
    
    hullSet(minPoint, furthestPoint, rightSet, hull)
    hullSet(furthestPoint, maxPoint, rightSet2, hull)
          
  quickHull2d = (cag...) ->
    #quickhull hull implementation experiment
    #see here http://westhoffswelt.de/blog/0040_quickhull_introduction_and_php_implementation.html/
    cags = undefined
    if cag instanceof Array
      cags = cag
    else
      cags = [cag]

    #TODO: sort all points for optimising
    points = []
    posIndex= []
    
    posExists = (pos)->
      index = "#{pos._x};#{pos._y}"
      if posIndex.indexOf(index) == -1
        posIndex.push index
        return false
      return true
             
    cags.map (cag) ->
      for side in cag.sides
        v0Pos = side.vertex0.pos
        v1Pos = side.vertex1.pos
        #remove redundant positions
        if not posExists(v0Pos)
          points.push(v0Pos)
        if not posExists(v1Pos)
          points.push(v1Pos)
    
    points = _(points).sortBy (u) -> [u._x, u._y]
    console.log points.length   
    hullPoints = quickHullSub3(points)
    
    console.log("ENDRESULT POINTS: Length#{hullPoints.length}, points:\n #{hullPoints}")
    
    #hullPoints = makeClockWise(hullPoints)
    console.log "finalHullPoints:\n #{hullPoints}"
    
    result = CAGBase.fromPoints(hullPoints)
    result
    
  
  return {
    "quickHull2d" : quickHull2d
    "quickHull2dVar2":quickHull2dVar2
  }

