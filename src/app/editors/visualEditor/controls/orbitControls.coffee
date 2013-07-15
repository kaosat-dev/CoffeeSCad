define (require) ->
  THREE = require 'three'
  ###
  @author qiao / https://github.com/qiao
  @author mrdoob / http://mrdoob.com
  @author alteredq / http://alteredqualia.com/
  @author WestLangley / https://github.com/WestLangley
  ###
  OrbitControls = (object, domElement) ->
    THREE.EventDispatcher.call @   
    @object = object
    @domElement = (if (domElement isnt `undefined`) then domElement else document)
    
    # API
    @center = new THREE.Vector3()
    @userZoom = true
    @userZoomSpeed = 1.0
    @userRotate = true
    @userRotateSpeed = 1.0
    @autoRotate = false
    @autoRotateSpeed = 2.0 # 30 seconds per round when fps is 60
    @minPolarAngle = 0 # radians
    @maxPolarAngle = Math.PI # radians
    @minDistance = 0
    @maxDistance = Infinity
    
    #internals
    scope = this
    EPS = 0.000001
    PIXELS_PER_ROUND = 1800
    rotateStart = new THREE.Vector2()
    rotateEnd = new THREE.Vector2()
    rotateDelta = new THREE.Vector2()
    zoomStart = new THREE.Vector2()
    zoomEnd = new THREE.Vector2()
    zoomDelta = new THREE.Vector2()
    phiDelta = 0
    thetaDelta = 0
    scale = 1
    lastPosition = new THREE.Vector3()
    STATE =
      NONE: -1
      ROTATE: 0
      ZOOM: 1
  
    state = STATE.NONE
    
    #events
    changeEvent = type: "change"
        
    @rotateLeft = (angle) ->
      angle = getAutoRotationAngle()  if angle is `undefined`
      thetaDelta -= angle
  
    @rotateRight = (angle) ->
      angle = getAutoRotationAngle()  if angle is `undefined`
      thetaDelta += angle
  
    @rotateUp = (angle) ->
      angle = getAutoRotationAngle()  if angle is `undefined`
      phiDelta -= angle
  
    @rotateDown = (angle) ->
      angle = getAutoRotationAngle()  if angle is `undefined`
      phiDelta += angle
  
    @zoomIn = (zoomScale) ->
      zoomScale = getZoomScale()  if zoomScale is `undefined`
      scale /= zoomScale
  
    @zoomOut = (zoomScale) ->
      zoomScale = getZoomScale()  if zoomScale is `undefined`
      scale *= zoomScale
      
    @update = ->
      position = @object.position
      offset = position.clone().sub(@center)
      #angle from z-axis around y-axis
      theta = Math.atan2(offset.x, offset.z)
      # angle from y-axis
      phi = Math.atan2(Math.sqrt(offset.x * offset.x + offset.z * offset.z), offset.y)
      @rotateLeft getAutoRotationAngle()  if @autoRotate
      theta += thetaDelta
      phi += phiDelta
      # restrict phi to be between desired limits
      phi = Math.max(@minPolarAngle, Math.min(@maxPolarAngle, phi))
      #restrict phi to be betwee EPS and PI-EPS
      phi = Math.max(EPS, Math.min(Math.PI - EPS, phi))
      radius = offset.length() * scale
      # restrict radius to be between desired limits
      radius = Math.max(@minDistance, Math.min(@maxDistance, radius))
      offset.x = radius * Math.sin(phi) * Math.sin(theta)
      offset.y = radius * Math.cos(phi)
      offset.z = radius * Math.sin(phi) * Math.cos(theta)
      position.copy(@center).add offset
      @object.lookAt @center
      thetaDelta = 0
      phiDelta = 0
      scale = 1
      if lastPosition.distanceTo(@object.position) > 0
        @dispatchEvent changeEvent
        lastPosition.copy @object.position
    
    getAutoRotationAngle = ->
      2 * Math.PI / 60 / 60 * scope.autoRotateSpeed
      
    getZoomScale = ->
      Math.pow 0.95, scope.userZoomSpeed
      
    onMouseDown = (event) ->
      console.log "mousedown"
      return  unless scope.userRotate
      event.preventDefault()
      if event.button is 0 or event.button is 2
        state = STATE.ROTATE
        rotateStart.set event.clientX, event.clientY
      else if event.button is 1
        state = STATE.ZOOM
        zoomStart.set event.clientX, event.clientY
      document.addEventListener "mousemove", onMouseMove, false
      document.addEventListener "mouseup", onMouseUp, false
      
    onMouseMove = (event) ->
      console.log "moving"
      event.preventDefault()
      if state is STATE.ROTATE
        rotateEnd.set event.clientX, event.clientY
        rotateDelta.subVectors rotateEnd, rotateStart
        scope.rotateLeft 2 * Math.PI * rotateDelta.x / PIXELS_PER_ROUND * scope.userRotateSpeed
        scope.rotateUp 2 * Math.PI * rotateDelta.y / PIXELS_PER_ROUND * scope.userRotateSpeed
        rotateStart.copy rotateEnd
      else if state is STATE.ZOOM
        zoomEnd.set event.clientX, event.clientY
        zoomDelta.subVectors zoomEnd, zoomStart
        if zoomDelta.y > 0
          scope.zoomIn()
        else
          scope.zoomOut()
        zoomStart.copy zoomEnd
        
    onMouseUp = (event) ->
      return  unless scope.userRotate
      document.removeEventListener "mousemove", onMouseMove, false
      document.removeEventListener "mouseup", onMouseUp, false
      state = STATE.NONE
      
    onMouseWheel = (event) ->
      return  unless scope.userZoom
      delta = 0
      if event.wheelDelta # WebKit / Opera / Explorer 9
        delta = event.wheelDelta
      # Firefox
      else delta = -event.detail  if event.detail
      if delta > 0
        scope.zoomOut()
      else
        scope.zoomIn()

  
    @domElement.addEventListener "contextmenu", ((event) ->event.preventDefault()), false
    @domElement.addEventListener "mousedown", onMouseDown, false
    @domElement.addEventListener "mousewheel", onMouseWheel, false
    @domElement.addEventListener "DOMMouseScroll", onMouseWheel, false # firefox

  return OrbitControls