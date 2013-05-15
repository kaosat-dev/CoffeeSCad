define (require)->
  csgMaths = require './maths'
  Vector3D = csgMaths.Vector3D
  Matrix4x4 = csgMaths.Matrix4x4
  Plane = csgMaths.Plane
  OrthoNormalBasis = csgMaths.OrthoNormalBasis
  
  class Properties
    # # Class Properties
    # This class is used to store properties of a solid
    # A property can for example be a Vertex, a Plane or a Line3D
    # Whenever an affine transform is applied to the CSG solid, all its properties are
    # transformed as well.
    # The properties can be stored in a complex nested structure (using arrays and objects)
    
    constructor:->
  
    _transform: (matrix4x4) ->
      result = new Properties()
      Properties.transformObj this, result, matrix4x4
      result
  
    _merge: (otherproperties) ->
      result = new Properties()
      Properties.cloneObj this, result
      Properties.addFrom result, otherproperties
      result
  
    @transformObj = (source, result, matrix4x4) ->
      for propertyname of source
        continue  if propertyname is "_transform"
        continue  if propertyname is "_merge"
        propertyvalue = source[propertyname]
        transformed = propertyvalue
        if typeof (propertyvalue) is "object"
          if ("transform" of propertyvalue) and (typeof (propertyvalue.transform) is "function")
            transformed = propertyvalue.transform(matrix4x4)
          else if propertyvalue instanceof Array
            transformed = []
            Properties.transformObj propertyvalue, transformed, matrix4x4
          else if propertyvalue instanceof Properties
            transformed = new Properties()
            Properties.transformObj propertyvalue, transformed, matrix4x4
        result[propertyname] = transformed
  
    @cloneObj = (source, result) ->
      for propertyname of source
        continue  if propertyname is "_transform"
        continue  if propertyname is "_merge"
        propertyvalue = source[propertyname]
        cloned = propertyvalue
        if typeof (propertyvalue) is "object"
          if propertyvalue instanceof Array
            cloned = []
            i = 0
            while i < propertyvalue.length
              cloned.push propertyvalue[i]
              i++
          else if propertyvalue instanceof Properties
            cloned = new Properties()
            Properties.cloneObj propertyvalue, cloned
        result[propertyname] = cloned
  
    @addFrom = (result, otherproperties) ->
      for propertyname of otherproperties
        continue  if propertyname is "_transform"
        continue  if propertyname is "_merge"
        if (propertyname of result) and (typeof (result[propertyname]) is "object") and (result[propertyname] instanceof Properties) and (typeof (otherproperties[propertyname]) is "object") and (otherproperties[propertyname] instanceof Properties)
          Properties.addFrom result[propertyname], otherproperties[propertyname]
        else result[propertyname] = otherproperties[propertyname]  unless propertyname of result
  
  class Connector
    # A connector allows to attach two objects at predefined positions
    # For example a servo motor and a servo horn:
    # Both can have a Connector called 'shaft'
    # The horn can be moved and rotated such that the two connectors match
    # and the horn is attached to the servo motor at the proper position. 
    # Connectors are stored in the properties of a CSG solid so they are
    # ge the same transformations applied as the solid
    constructor: (point, axisvector, normalvector) ->
      @point = new Vector3D(point)
      @axisvector = new Vector3D(axisvector).unit()
      @normalvector = new Vector3D(normalvector).unit()
  
    normalized: ->
      axisvector = @axisvector.unit()
      # make the normal vector truly normal:
      n = @normalvector.cross(axisvector).unit()
      normalvector = axisvector.cross(n)
      @axisvector = axisvector
      @normalvector = normalvector
      @
  
    transform: (matrix4x4) ->
      point = @point.multiply4x4(matrix4x4)
      axisvector = @point.plus(@axisvector).multiply4x4(matrix4x4).minus(point)
      normalvector = @point.plus(@normalvector).multiply4x4(matrix4x4).minus(point)
      #new Connector(point, axisvector, normalvector)
      @point = point
      @axisvector = axisvector
      @normalvector = normalvector
      @
    
    getTransformationTo: (other, mirror, normalrotation) ->
      # Get the transformation matrix to connect this Connector to another connector
      #   other: a Connector to which this connector should be connected
      #   mirror: false: the 'axis' vectors of the connectors should point in the same direction
      #           true: the 'axis' vectors of the connectors should point in opposite direction
      #   normalrotation: degrees of rotation between the 'normal' vectors of the two
      #                   connectors
      mirror = (if mirror then true else false)
      normalrotation = (if normalrotation then Number(normalrotation) else 0)
      us = @normalized()
      other = other.normalized()
      
      # shift to the origin:
      transformation = Matrix4x4.translation(@point.negated())
      
      # construct the plane crossing through the origin and the two axes:
      axesplane = Plane.anyPlaneFromVector3Ds(new Vector3D(0, 0, 0), us.axisvector, other.axisvector)
      axesbasis = new OrthoNormalBasis(axesplane)
      angle1 = axesbasis.to2D(us.axisvector).angle()
      angle2 = axesbasis.to2D(other.axisvector).angle()
      rotation = 180.0 * (angle2 - angle1) / Math.PI
      rotation += 180.0  if mirror
      transformation = transformation.multiply(axesbasis.getProjectionMatrix())
      transformation = transformation.multiply(Matrix4x4.rotationZ(rotation))
      transformation = transformation.multiply(axesbasis.getInverseProjectionMatrix())
      usAxesAligned = us.transform(transformation)
      
      # Now we have done the transformation for aligning the axes.
      # We still need to align the normals:
      normalsplane = Plane.fromNormalAndPoint(other.axisvector, new Vector3D(0, 0, 0))
      normalsbasis = new OrthoNormalBasis(normalsplane)
      angle1 = normalsbasis.to2D(usAxesAligned.normalvector).angle()
      angle2 = normalsbasis.to2D(other.normalvector).angle()
      rotation = 180.0 * (angle2 - angle1) / Math.PI
      rotation += normalrotation
      transformation = transformation.multiply(normalsbasis.getProjectionMatrix())
      transformation = transformation.multiply(Matrix4x4.rotationZ(rotation))
      transformation = transformation.multiply(normalsbasis.getInverseProjectionMatrix())
      
      # and translate to the destination point:
      transformation = transformation.multiply(Matrix4x4.translation(other.point))
      usAligned = us.transform(transformation)
      transformation
  
    axisLine: ->
      new Line3D(@point, @axisvector)
    
    extend: (distance) ->
      # creates a new Connector, with the connection point moved in the direction of the axisvector
      newpoint = @point.plus(@axisvector.unit().times(distance))
      new Connector(newpoint, @axisvector, @normalvector)
  
  return {
      "Connector":Connector
      "Properties":Properties
  }
