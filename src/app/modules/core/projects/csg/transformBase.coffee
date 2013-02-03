define (require)->
  csgMaths = require './maths'
  Matrix4x4 = csgMaths.Matrix4x4
  Vector3D = csgMaths.Vector3D
  Plane = csgMaths.Plane
  
  class TransformBase 
    # Add several convenience methods to the classes that support a transform() method:
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
      @transform Matrix4x4.translation(v)
  
    scale : (f) ->
      @transform Matrix4x4.scaling(f)
  
    rotateX : (deg) ->
      @transform Matrix4x4.rotationX(deg)
  
    rotateY : (deg) ->
      @transform Matrix4x4.rotationY(deg)
  
    rotateZ : (deg) ->
      @transform Matrix4x4.rotationZ(deg)
  
    rotate_alt : (degrees, rotationCenter, rotationAxis) ->
      @transform Matrix4x4.rotation(rotationCenter, rotationAxis, degrees)
  
    rotate_alt2 : (degrees, rotationCenter, rotationAxis) ->
      tmp1 = Matrix4x4.rotation(rotationCenter, rotationAxis, degrees)
      tmp = @transform(tmp1)
      tmp
  
    rotate : (degrees, rotationCenter) ->
      rotationCenter = [0, 0, 0]  unless rotationCenter?
      @translate(rotationCenter)
      @transform(Matrix4x4.rotationX(degrees[0]))
      @transform(Matrix4x4.rotationY(degrees[1]))
      @transform(Matrix4x4.rotationZ(degrees[2]))
      @
      
  return TransformBase