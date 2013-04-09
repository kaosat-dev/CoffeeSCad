define (require)->
  base = require './csgBase'
  CAGBase = base.CAGBase
  
  maths = require './maths'
  Side = maths.Side
  
  globals = require './globals'
  defaultResolution2D = globals.defaultResolution2D
  
  utils = require './utils'
  parseOptionAs2DVector = utils.parseOptionAs2DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  
  #set of "global methods"
  
  union = (csg)->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
      result = csgs[0]
      for i in [1...csgs.length]
        result.union(csgs[i])
      result
    else
      csg
  
  subtract = (csg)->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
      result = csgs[0]
      for i in [1...csgs.length]
        result.subtract(csgs[i])
      result
    else
      csg
  
  intersect = (csg)->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
      result = csgs[0]
      for i in [1...csgs.length]
        result.intersect(csgs[i])
      result
    else
      csg
  
  translate = (v, csg) ->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
    else
      csgs = [csg]
    for csg in csgs
      csg.translate(v)
    csgs  
  
  rotate = (degrees, rotationCenter, csg) ->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
    else
      csgs = [csg]
    for csg in csgs
      csg.rotate(degrees, rotationCenter)
    csgs
      
  scale = (f, csg) ->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
    else
      csgs = [csg]
    for csg in csgs
      csg.scale(f)
    csgs
    
  ###    
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
  
  ### 
  #helpers for hull
  sign = (p1,p2,p3)->
    #return ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x))
    return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
  removeFromArray=(array, element)->
    index = array.indexOf element
    array.splice(index, 1)
    return array
 
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
    #console.log "removed points:"
    #console.log toRemove
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
          
  quickHull2d = (cag) ->
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
    
    hullPoints = quickHullSub3(points)
    #console.log("ENDRESULT POINTS: Length#{hullPoints.length}, points:\n #{hullPoints}")
    #console.log "finalHullPoints:\n #{hullPoints}"
    result = CAGBase.fromPoints(hullPoints)
    result
  
  return {
    "hull" : quickHull2d,
    "union": union,
    "subtract":subtract,
    "intersect":intersect,
    "translate":translate,
    "rotate":rotate,
    "scale":scale
  }

