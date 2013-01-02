define (require)->

  class CAG 
    # CAG: solid area geometry: like CSG but 2D
    # Each area consists of a number of sides
    # Each side is a line between 2 points
    constructor: ->
      @sides = []
  
    @fromSides : (sides) ->
      # Construct a CAG from a list of `CAG.Side` instances.
      cag = new CAG()
      cag.sides = sides
      cag
  
    @fromPoints : (points) ->
      # Construct a CAG from a list of points (a polygon)
      # Rotation direction of the points is not relevant. Points can be a convex or concave polygon.
      # Polygon must not self intersect
      numpoints = points.length
      throw new Error("CAG shape needs at least 3 points")  if numpoints < 3
      sides = []
      prevpoint = new CSG.Vector2D(points[numpoints - 1])
      prevvertex = new CAG.Vertex(prevpoint)
      points.map (p) ->
        point = new CSG.Vector2D(p)
        vertex = new CAG.Vertex(point)
        side = new CAG.Side(prevvertex, vertex)
        sides.push side
        prevvertex = vertex
    
      result = CAG.fromSides(sides)
      throw new Error("Polygon is self intersecting!")  if result.isSelfIntersecting()
      area = result.area()
      throw new Error("Degenerate polygon!")  if Math.abs(area) < 1e-5
      result = result.flipped()  if area < 0
      result = result.canonicalized()
      result
  
    @fromPointsNoCheck : (points) ->
      # Like CAG.fromPoints but does not check if it's a valid polygon.
      # Points should rotate counter clockwise
      sides = []
      prevpoint = new CSG.Vector2D(points[points.length - 1])
      prevvertex = new CAG.Vertex(prevpoint)
      points.map (p) ->
        point = new CSG.Vector2D(p)
        vertex = new CAG.Vertex(point)
        side = new CAG.Side(prevvertex, vertex)
        sides.push side
        prevvertex = vertex
    
      CAG.fromSides sides
  
    @fromFakeCSG : (csg) ->
      # Converts a CSG to a CAG. The CSG must consist of polygons with only z coordinates +1 and -1
      # as constructed by CAG.toCSG(-1, 1). This is so we can use the 3D union(), intersect() etc
      sides = csg.polygons.map((p) ->
        CAG.Side.fromFakePolygon p
      )
      CAG.fromSides sides
  
    @fromCompactBinary : (bin) ->
      # Reconstruct a CAG from the output of toCompactBinary()
      throw new Error("Not a CAG")  unless bin.class is "CAG"
      vertices = []
      vertexData = bin.vertexData
      numvertices = vertexData.length / 2
      arrayindex = 0
      vertexindex = 0
    
      while vertexindex < numvertices
        x = vertexData[arrayindex++]
        y = vertexData[arrayindex++]
        pos = new CSG.Vector2D(x, y)
        vertex = new CAG.Vertex(pos)
        vertices.push vertex
        vertexindex++
      sides = []
      numsides = bin.sideVertexIndices.length / 2
      arrayindex = 0
      sideindex = 0
    
      while sideindex < numsides
        vertexindex0 = bin.sideVertexIndices[arrayindex++]
        vertexindex1 = bin.sideVertexIndices[arrayindex++]
        side = new CAG.Side(vertices[vertexindex0], vertices[vertexindex1])
        sides.push side
        sideindex++
      cag = CAG.fromSides(sides)
      cag.isCanonicalized = true
      cag
      
    toString: ->
      result = "CAG (" + @sides.length + " sides):\n"
      @sides.map (side) ->
        result += "  " + side.toString() + "\n"
      result
  
    toCSG: (z0, z1) ->
      polygons = @sides.map((side) ->
        side.toPolygon3D z0, z1
      )
      CSG.fromPolygons polygons
  
    toDebugString1: ->
      @sides.sort (a, b) ->
        a.vertex0.pos.x - b.vertex0.pos.x
  
      str = ""
      @sides.map (side) ->
        str += "(" + side.vertex0.pos.x + "," + side.vertex0.pos.y + ") - (" + side.vertex1.pos.x + "," + side.vertex1.pos.y + ")\n"
  
      str
  
    toDebugString: ->
      
      #    this.sides.sort(function(a,b){
      #      return a.vertex0.pos.x - b.vertex0.pos.x; 
      #    });
      str = "CAG.fromSides([\n"
      @sides.map (side) ->
        str += "  new CAG.Side(new CAG.Vertex(new CSG.Vector2D(" + side.vertex0.pos.x + "," + side.vertex0.pos.y + ")), new CAG.Vertex(new CSG.Vector2D(" + side.vertex1.pos.x + "," + side.vertex1.pos.y + "))),\n"
  
      str += "]);\n"
      str
  
    toCompactBinary: ->
      cag = @canonicalized()
      numsides = cag.sides.length
      vertexmap = {}
      vertices = []
      numvertices = 0
      sideVertexIndices = new Uint32Array(2 * numsides)
      sidevertexindicesindex = 0
      cag.sides.map (side) ->
        [side.vertex0, side.vertex1].map (v) ->
          vertextag = v.getTag()
          vertexindex = undefined
          unless vertextag of vertexmap
            vertexindex = numvertices++
            vertexmap[vertextag] = vertexindex
            vertices.push v
          else
            vertexindex = vertexmap[vertextag]
          sideVertexIndices[sidevertexindicesindex++] = vertexindex
  
  
      vertexData = new Float64Array(numvertices * 2)
      verticesArrayIndex = 0
      vertices.map (v) ->
        pos = v.pos
        vertexData[verticesArrayIndex++] = pos._x
        vertexData[verticesArrayIndex++] = pos._y
  
      result =
        class: "CAG"
        sideVertexIndices: sideVertexIndices
        vertexData: vertexData
      result
  
    toDxf: (blobbuilder) ->
      paths = @getOutlinePaths()
      CAG.PathsToDxf paths, blobbuilder
  
    union: (cag) ->
      cags = undefined
      if cag instanceof Array
        cags = cag
      else
        cags = [cag]
      r = @toCSG(-1, 1)
      cags.map (cag) ->
        r = r.unionSub(cag.toCSG(-1, 1), false, false)
  
      r = r.reTesselated()
      r = r.canonicalized()
      cag = CAG.fromFakeCSG(r)
      cag_canonicalized = cag.canonicalized()
      cag_canonicalized
  
    subtract: (cag) ->
      cags = undefined
      if cag instanceof Array
        cags = cag
      else
        cags = [cag]
      r = @toCSG(-1, 1)
      cags.map (cag) ->
        r = r.subtractSub(cag.toCSG(-1, 1), false, false)
  
      r = r.reTesselated()
      r = r.canonicalized()
      r = CAG.fromFakeCSG(r)
      r = r.canonicalized()
      r
  
    intersect: (cag) ->
      cags = undefined
      if cag instanceof Array
        cags = cag
      else
        cags = [cag]
      r = @toCSG(-1, 1)
      cags.map (cag) ->
        r = r.intersectSub(cag.toCSG(-1, 1), false, false)
  
      r = r.reTesselated()
      r = r.canonicalized()
      r = CAG.fromFakeCSG(r)
      r = r.canonicalized()
      r
  
    transform: (matrix4x4) ->
      ismirror = matrix4x4.isMirroring()
      newsides = @sides.map((side) ->
        side.transform matrix4x4
      )
      result = CAG.fromSides(newsides)
      result = result.flipped()  if ismirror
      result
      
    area: ->
      # see http://local.wasp.uwa.edu.au/~pbourke/geometry/polyarea/ :
      # Area of the polygon. For a counter clockwise rotating polygon the area is positive, otherwise negative
      polygonArea = 0
      @sides.map (side) ->
        polygonArea += side.vertex0.pos.cross(side.vertex1.pos)
  
      polygonArea *= 0.5
      polygonArea
  
    flipped: ->
      newsides = @sides.map((side) ->
        side.flipped()
      )
      newsides.reverse()
      CAG.fromSides newsides
  
    getBounds: ->
      minpoint = undefined
      if @sides.length is 0
        minpoint = new CSG.Vector2D(0, 0)
      else
        minpoint = @sides[0].vertex0.pos
      maxpoint = minpoint
      @sides.map (side) ->
        minpoint = minpoint.min(side.vertex0.pos)
        minpoint = minpoint.min(side.vertex1.pos)
        maxpoint = maxpoint.max(side.vertex0.pos)
        maxpoint = maxpoint.max(side.vertex1.pos)
  
      [minpoint, maxpoint]
  
    isSelfIntersecting: ->
      numsides = @sides.length
      i = 0
  
      while i < numsides
        side0 = @sides[i]
        ii = i + 1
  
        while ii < numsides
          side1 = @sides[ii]
          return true  if CAG.linesIntersect(side0.vertex0.pos, side0.vertex1.pos, side1.vertex0.pos, side1.vertex1.pos)
          ii++
        i++
      false
  
    expandedShell: (radius, resolution) ->
      resolution = resolution or 8
      resolution = 4  if resolution < 4
      cags = []
      pointmap = {}
      cag = @canonicalized()
      cag.sides.map (side) ->
        d = side.vertex1.pos.minus(side.vertex0.pos)
        dl = d.length()
        if dl > 1e-5
          d = d.times(1.0 / dl)
          normal = d.normal().times(radius)
          shellpoints = [side.vertex1.pos.plus(normal), side.vertex1.pos.minus(normal), side.vertex0.pos.minus(normal), side.vertex0.pos.plus(normal)]
          
          #      var newcag = CAG.fromPointsNoCheck(shellpoints); 
          newcag = CAG.fromPoints(shellpoints)
          cags.push newcag
          step = 0
  
          while step < 2
            p1 = (if (step is 0) then side.vertex0.pos else side.vertex1.pos)
            p2 = (if (step is 0) then side.vertex1.pos else side.vertex0.pos)
            tag = p1.x + " " + p1.y
            pointmap[tag] = []  unless tag of pointmap
            pointmap[tag].push
              p1: p1
              p2: p2
  
            step++
  
      for tag of pointmap
        m = pointmap[tag]
        angle1 = undefined
        angle2 = undefined
        pcenter = m[0].p1
        if m.length is 2
          end1 = m[0].p2
          end2 = m[1].p2
          angle1 = end1.minus(pcenter).angleDegrees()
          angle2 = end2.minus(pcenter).angleDegrees()
          angle2 += 360  if angle2 < angle1
          angle2 -= 360  if angle2 >= (angle1 + 360)
          if angle2 < angle1 + 180
            t = angle2
            angle2 = angle1 + 360
            angle1 = t
          angle1 += 90
          angle2 -= 90
        else
          angle1 = 0
          angle2 = 360
        fullcircle = (angle2 > angle1 + 359.999)
        if fullcircle
          angle1 = 0
          angle2 = 360
        if angle2 > (angle1 + 1e-5)
          points = []
          points.push pcenter  unless fullcircle
          numsteps = Math.round(resolution * (angle2 - angle1) / 360)
          numsteps = 1  if numsteps < 1
          step = 0
  
          while step <= numsteps
            angle = angle1 + step / numsteps * (angle2 - angle1)
            angle = angle2  if step is numsteps # prevent rounding errors
            point = pcenter.plus(CSG.Vector2D.fromAngleDegrees(angle).times(radius))
            points.push point  if (not fullcircle) or (step > 0)
            step++
          newcag = CAG.fromPointsNoCheck(points)
          cags.push newcag
      result = new CAG()
      result = result.union(cags)
      result
  
    expand: (radius, resolution) ->
      result = @union(@expandedShell(radius, resolution))
      result
  
    contract: (radius, resolution) ->
      result = @subtract(@expandedShell(radius, resolution))
      result
  
    extrude: (options) ->
      # extruded=cag.extrude({offset: [0,0,10], twistangle: 360, twiststeps: 100});
      # linear extrusion of 2D shape, with optional twist
      # The 2d shape is placed in z=0 plane and extruded into direction <offset> (a CSG.Vector3D)
      # The final face is rotated <twistangle> degrees. Rotation is done around the origin of the 2d shape (i.e. x=0, y=0)
      # twiststeps determines the resolution of the twist (should be >= 1)  
      # returns a CSG object
      
      # empty!
      return new CSG()  if @sides.length is 0
      offsetvector = CSG.parseOptionAs3DVector(options, "offset", [0, 0, 1])
      twistangle = CSG.parseOptionAsFloat(options, "twist", 0)
      twiststeps = CSG.parseOptionAsInt(options, "slices", 10)
      twiststeps = 1  if twistangle is 0
      twiststeps = 1  if twiststeps < 1
      newpolygons = []
      prevtransformedcag = undefined
      prevstepz = undefined
      step = 0
  
      while step <= twiststeps
        stepfraction = step / twiststeps
        transformedcag = this
        angle = twistangle * stepfraction
        transformedcag = transformedcag.rotateZ(angle)  unless angle is 0
        translatevector = new CSG.Vector2D(offsetvector.x, offsetvector.y).times(stepfraction)
        transformedcag = transformedcag.translate(translatevector)
        bounds = transformedcag.getBounds()
        bounds[0] = bounds[0].minus(new CSG.Vector2D(1, 1))
        bounds[1] = bounds[1].plus(new CSG.Vector2D(1, 1))
        stepz = offsetvector.z * stepfraction
        if (step is 0) or (step is twiststeps)
          
          # bottom or top face:
          csgshell = transformedcag.toCSG(stepz - 1, stepz + 1)
          csgplane = CSG.fromPolygons([new CSG.Polygon([new CSG.Vertex(new CSG.Vector3D(bounds[0].x, bounds[0].y, stepz)), new CSG.Vertex(new CSG.Vector3D(bounds[1].x, bounds[0].y, stepz)), new CSG.Vertex(new CSG.Vector3D(bounds[1].x, bounds[1].y, stepz)), new CSG.Vertex(new CSG.Vector3D(bounds[0].x, bounds[1].y, stepz))])])
          flip = (step is 0)
          flip = not flip  if offsetvector.z < 0
          csgplane = csgplane.inverse()  if flip
          csgplane = csgplane.intersect(csgshell)
          
          # only keep the polygons in the z plane:
          csgplane.polygons.map (polygon) ->
            newpolygons.push polygon  if Math.abs(polygon.plane.normal.z) > 0.99
  
        if step > 0
          numsides = transformedcag.sides.length
          sideindex = 0
  
          while sideindex < numsides
            thisside = transformedcag.sides[sideindex]
            prevside = prevtransformedcag.sides[sideindex]
            p1 = new CSG.Polygon([new CSG.Vertex(thisside.vertex1.pos.toVector3D(stepz)), new CSG.Vertex(thisside.vertex0.pos.toVector3D(stepz)), new CSG.Vertex(prevside.vertex0.pos.toVector3D(prevstepz))])
            p2 = new CSG.Polygon([new CSG.Vertex(thisside.vertex1.pos.toVector3D(stepz)), new CSG.Vertex(prevside.vertex0.pos.toVector3D(prevstepz)), new CSG.Vertex(prevside.vertex1.pos.toVector3D(prevstepz))])
            if offsetvector.z < 0
              p1 = p1.flipped()
              p2 = p2.flipped()
            newpolygons.push p1
            newpolygons.push p2
            sideindex++
        prevtransformedcag = transformedcag
        prevstepz = stepz
        step++
      # for step  
      CSG.fromPolygons newpolygons
    
    check: ->
      # check if we are a valid CAG (for debugging)
      errors = []
      errors.push "Self intersects"  if @isSelfIntersecting()
      pointcount = {}
      @sides.map (side) ->
        mappoint = (p) ->
          tag = p.x + " " + p.y
          pointcount[tag] = 0  unless tag of pointcount
          pointcount[tag]++
        mappoint side.vertex0.pos
        mappoint side.vertex1.pos
  
      for tag of pointcount
        count = pointcount[tag]
        errors.push "Uneven number of sides (" + count + ") for point " + tag  if count & 1
      area = @area()
      errors.push "Area is " + area  if area < 1e-5
      if errors.length > 0
        ertxt = ""
        errors.map (err) ->
          ertxt += err + "\n"
  
        throw new Error(ertxt)
  
    canonicalized: ->
      if @isCanonicalized
        this
      else
        factory = new CAG.fuzzyCAGFactory()
        result = factory.getCAG(this)
        result.isCanonicalized = true
        result
  
    getOutlinePaths: ->
      cag = @canonicalized()
      sideTagToSideMap = {}
      startVertexTagToSideTagMap = {}
      cag.sides.map (side) ->
        sidetag = side.getTag()
        sideTagToSideMap[sidetag] = side
        startvertextag = side.vertex0.getTag()
        startVertexTagToSideTagMap[startvertextag] = []  unless startvertextag of startVertexTagToSideTagMap
        startVertexTagToSideTagMap[startvertextag].push sidetag
  
      paths = []
      loop
        startsidetag = null
        for aVertexTag of startVertexTagToSideTagMap
          sidesForThisVertex = startVertexTagToSideTagMap[aVertexTag]
          startsidetag = sidesForThisVertex[0]
          sidesForThisVertex.splice 0, 1
          delete startVertexTagToSideTagMap[aVertexTag]  if sidesForThisVertex.length is 0
          break
        break  if startsidetag is null # we've had all sides
        connectedVertexPoints = []
        sidetag = startsidetag
        thisside = sideTagToSideMap[sidetag]
        startvertextag = thisside.vertex0.getTag()
        loop
          connectedVertexPoints.push thisside.vertex0.pos
          nextvertextag = thisside.vertex1.getTag()
          break  if nextvertextag is startvertextag # we've closed the polygon
          throw new Error("Area is not closed!")  unless nextvertextag of startVertexTagToSideTagMap
          nextpossiblesidetags = startVertexTagToSideTagMap[nextvertextag]
          nextsideindex = -1
          if nextpossiblesidetags.length is 1
            nextsideindex = 0
          else
            
            # more than one side starting at the same vertex. This means we have
            # two shapes touching at the same corner
            bestangle = null
            thisangle = thisside.direction().angleDegrees()
            sideindex = 0
  
            while sideindex < nextpossiblesidetags.length
              nextpossiblesidetag = nextpossiblesidetags[sideindex]
              possibleside = sideTagToSideMap[nextpossiblesidetag]
              angle = possibleside.direction().angleDegrees()
              angledif = angle - thisangle
              angledif += 360  if angledif < -180
              angledif -= 360  if angledif >= 180
              if (nextsideindex < 0) or (angledif > bestangle)
                nextsideindex = sideindex
                bestangle = angledif
              sideindex++
          nextsidetag = nextpossiblesidetags[nextsideindex]
          nextpossiblesidetags.splice nextsideindex, 1
          delete startVertexTagToSideTagMap[nextvertextag]  if nextpossiblesidetags.length is 0
          thisside = sideTagToSideMap[nextsidetag]
        # inner loop
        path = new CSG.Path2D(connectedVertexPoints, true)
        paths.push path
      # outer loop
      paths
      
    @linesIntersect : (p0start, p0end, p1start, p1end) ->
      # see if the line between p0start and p0end intersects with the line between p1start and p1end
      # returns true if the lines strictly intersect, the end points are not counted!
      if p0end.equals(p1start) or p1end.equals(p0start)
        d = p1end.minus(p1start).unit().plus(p0end.minus(p0start).unit()).length()
        return true  if d < 1e-5
      else
        d0 = p0end.minus(p0start)
        d1 = p1end.minus(p1start)
        return false  if Math.abs(d0.cross(d1)) < 1e-9 # lines are parallel
        alphas = CSG.solve2Linear(-d0.x, d1.x, -d0.y, d1.y, p0start.x - p1start.x, p0start.y - p1start.y)
        return true  if (alphas[0] > 1e-6) and (alphas[0] < 0.999999) and (alphas[1] > 1e-5) and (alphas[1] < 0.999999)
      
      #    if( (alphas[0] >= 0) && (alphas[0] <= 1) && (alphas[1] >= 0) && (alphas[1] <= 1) ) return true;
      false
      
    @PathsToDxf : (paths, blobbuilder) ->
      str = "999\nDXF generated by OpenJsCad\n  0\nSECTION\n  2\nENTITIES\n"
      blobbuilder.append str
      paths.map (path) ->
        numpoints_closed = path.points.length + ((if path.closed then 1 else 0))
        str = "  0\nLWPOLYLINE\n  90\n" + numpoints_closed + "\n  70\n" + ((if path.closed then 1 else 0)) + "\n"
        pointindex = 0
    
        while pointindex < numpoints_closed
          pointindexwrapped = pointindex
          pointindexwrapped -= path.points.length  if pointindexwrapped >= path.points.length
          point = path.points[pointindexwrapped]
          str += " 10\n" + point.x + "\n 20\n" + point.y + "\n 30\n0.0\n"
          pointindex++
        blobbuilder.append str
    
      str = "  0\nENDSEC\n  0\nEOF\n"
      blobbuilder.append str
  return CAG