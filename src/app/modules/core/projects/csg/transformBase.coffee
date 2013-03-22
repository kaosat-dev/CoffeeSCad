define (require)->
  csgMaths = require './maths'
  Matrix4x4 = csgMaths.Matrix4x4
  Vector3D = csgMaths.Vector3D
  Plane = csgMaths.Plane
  
  class TransformBase 
    # Add several convenience methods to the classes that support a transform() method:
    
    constructor:(options)->
      @position = new Vector3D(0,0,0)
      @rotation = new Vector3D(0,0,0)
      
    mirrored : (plane) ->
      @transform Matrix4x4.mirroring(plane)
  
    mirroredX : ->
      plane = new Plane(new Vector3D(1, 0, 0), 0)
      @mirrored plane
  
    mirroredY : ->
      plane = new Plane(new Vector3D(0, 1, 0), 0)
      @mirrored plane
  
    mirroredZ : ->
      plane = new Plane(new Vector3D(0, 0, 1), 0)
      @mirrored plane
  
    translate : (v) ->
      #TODO: find why check is needed for the strange 
      #cases where @position is not defined: could be a transformbase subclass which does not call super(options)?
      if @position?
        if v instanceof csgMaths.Vector2D
          v = v.toVector3D()
        v = new Vector3D(v)
        @position = @position.plus(v)
      else
        if v instanceof csgMaths.Vector2D
          v = v.toVector3D()
        v = new Vector3D(v)
        @position = new Vector3D(v)
      return @transform Matrix4x4.translation(v)
  
    scale : (f) ->
      @transform Matrix4x4.scaling(f)
  
    rotateX : (deg) ->
      @transform Matrix4x4.rotationX(deg)
  
    rotateY : (deg) ->
      @transform Matrix4x4.rotationY(deg)
  
    rotateZ : (deg) ->
      @transform Matrix4x4.rotationZ(deg)
   
    rotate : (degrees, rotationCenter) ->
      rotationCenter = [0, 0, 0]  unless rotationCenter?
      @translate(rotationCenter)
      
      xMatrix = Matrix4x4.rotationX(degrees[0])
      yMatrix = Matrix4x4.rotationY(degrees[1])
      zMatrix = Matrix4x4.rotationZ(degrees[2])
      
      @transform(xMatrix)
      @transform(yMatrix)
      @transform(zMatrix)
      
      if not @rotation?
        @rotation = new Vector3D()
      @rotation = @rotation.multiply4x4(yMatrix).transform(yMatrix).transform(zMatrix)
      @
      
      
      
  return TransformBase