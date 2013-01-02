define (require)->
  console.log "in base, looking for maths"
  Polygon = require './cgs.maths'
  

  class TransformBase
    # Add several convenience methods to the classes that support a transform() method:
    mirrored = (plane) ->
      @transform CSG.Matrix4x4.mirroring(plane)
  
    mirroredX = ->
      plane = new CSG.Plane(new CSG.Vector3D(1, 0, 0), 0)
      @mirrored plane
  
    mirroredY = ->
      plane = new CSG.Plane(new CSG.Vector3D(0, 1, 0), 0)
      @mirrored plane
  
    mirroredZ = ->
      plane = new CSG.Plane(new CSG.Vector3D(0, 0, 1), 0)
      @mirrored plane
  
    translate = (v) ->
      @transform CSG.Matrix4x4.translation(v)
  
    scale = (f) ->
      @transform CSG.Matrix4x4.scaling(f)
  
    rotateX = (deg) ->
      @transform CSG.Matrix4x4.rotationX(deg)
  
    rotateY = (deg) ->
      @transform CSG.Matrix4x4.rotationY(deg)
  
    rotateZ = (deg) ->
      @transform CSG.Matrix4x4.rotationZ(deg)
  
    rotate_alt = (degrees, rotationCenter, rotationAxis) ->
      @transform CSG.Matrix4x4.rotation(rotationCenter, rotationAxis, degrees)
  
    rotate_alt2 = (degrees, rotationCenter, rotationAxis) ->
      tmp1 = CSG.Matrix4x4.rotation(rotationCenter, rotationAxis, degrees)
      tmp = @transform(tmp1)
      tmp
  
    rotate = (degrees, rotationCenter) ->
      rotationCenter = [0, 0, 0]  unless rotationCenter?
      tmp = @translate(rotationCenter)
      tmp = tmp.transform(CSG.Matrix4x4.rotationX(degrees[0]))
      tmp = tmp.transform(CSG.Matrix4x4.rotationY(degrees[1]))
      tmp = tmp.transform(CSG.Matrix4x4.rotationZ(degrees[2]))
      tmp
      
  return TransformBase