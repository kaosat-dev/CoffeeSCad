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
    
    #API additions
    @target = new THREE.Vector3()
    @eye = new THREE.Vector3()
    _panStart = new THREE.Vector2()
    _panEnd = new THREE.Vector2()
    
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
      
    @zoomCamera = ->
      position = @object.position
      offset = position.clone().sub(@target)
      radius = offset.length() * scale
      
      # restrict radius to be between desired limits
      radius = Math.max(@minDistance, Math.min(@maxDistance, radius))
      @eye.multiplyScalar radius
      scale = 1.0
    
    #
    #       var factor = 1.0 + ( zoomEnd.y - zoomStart.y ) * this.userZoomSpeed;
    #        if ( factor !== 1.0 && factor > 0.0 ) {
    #            this.eye.multiplyScalar( factor*2000);
    #        }
    
    @rotateCamera = ->
      position = @object.position
      offset = position.clone().sub(@target)
      
      # angle from z-axis around y-axis
      theta = Math.atan2(offset.x, offset.y)
      
      # angle from y-axis
      phi = Math.atan2(Math.sqrt(offset.x * offset.x + offset.y * offset.y), offset.z)
      
      #
      #        if ( this.autoRotate ) {
      #
      #            this.rotateLeft( getAutoRotationAngle() );
      #
      #        }
      theta += thetaDelta
      phi += phiDelta
      
      # restrict phi to be between desired limits
      phi = Math.max(@minPolarAngle, Math.min(@maxPolarAngle, phi))
      
      # restrict phi to be betwee EPS and PI-EPS
      phi = Math.max(EPS, Math.min(Math.PI - EPS, phi))
      offset.x = Math.sin(phi) * Math.sin(theta)
      offset.z = Math.cos(phi)
      offset.y = Math.sin(phi) * Math.cos(theta)
      @eye = offset
      thetaDelta = 0
      phiDelta = 0
      #scale = 1;
      @theta =theta
      @phi = phi
      
    
    @panCamera = ->
      mouseChange = _panEnd.clone().sub(_panStart)
      if mouseChange.lengthSq()
        
        #mouseChange.multiplyScalar( this.target.length() * this.panSpeed );
        mouseChange.multiplyScalar @panSpeed
        
        pan = @target.clone().cross(@object.up).setLength(mouseChange.x)
        pan.add @object.up.clone().setLength(mouseChange.y)
        pan2 = @object.up.clone()
        
        #console.log("up vector: ("+pan2.x+", "+pan2.y+", ",+pan2.z+")")
        #@object.matrixWorld.scale(pan2)
        #@object.matrixWorld.multiplyVector3 pan2
        #Matrix4's .multiplyVector3() has been removed. Use vector.applyMatrix4( matrix ) or vector.applyProjection( matrix )
        
        #console.log("up vector 2: ("+pan2.x+", "+pan2.y+", ",+pan2.z+")")
        
        #we need two vectors relative to the camera: up and left 
        #             *  for this we need the "eye vector (see below) and either cam.up or cam.left to get the other"
        #             * and scale these two by mousechange values
        #             * 
        
        #console.log("View angle : #{@theta} #{@phi}")
        
        #get "eye vector" (ray from cam to target)
        eyeVector = @object.position.clone().sub(@target)
        
        #console.log("Cam position: #{@object.position.x}, #{@object.position.y}, #{@object.position.z}")
        #console.log("eyeVector: ("+eyeVector.x+", "+eyeVector.y+", "+eyeVector.z+")")
        
        #get cam up vector 
        upVector = @object.up.clone()
        leftVector = new THREE.Vector3(1,0,0)
        
        #get actual pan vector: 
        #for x first (cam pan left/right)
        panVector = eyeVector.clone().cross(upVector).setLength(mouseChange.x)#this works
        
        panVector.add( @object.up.clone().setLength( mouseChange.y ) )#not right
        #panVector.add(eyeVector.clone().cross(leftVector).setLength(mouseChange.y))#not right
        #console.log "test vect #{toto.x} #{toto.y} #{toto.z}"
        
        vector2dAngle= (vector)=>
          if(vector.x != 0)
            if vector.x > 0
              return  Math.atan(vector.y/vector.x)
            else
              return Math.atan(vector.y/vector.x) - Math.PI
          else
            if vector.y > 0
              return Math.PI/2 
            else
              return -Math.PI/2
        
        ###
        #left/right vector
        tmp1 = new THREE.Vector2(0,1)
        tmp1 = new THREE.Vector2(panVector.x,panVector.y) 
        
        angDifUp = - (Math.PI/2.0) + vector2dAngle(tmp1)
        angDelta = vector2dAngle(mouseChange)
        
        #Norm of the delta vector
        normDelta = mouseChange.length()
        newDelta = new THREE.Vector2(normDelta*Math.cos(angDelta+angDifUp),normDelta*Math.sin(angDelta+angDifUp))
        
        #console.log ("angDifUp #{angDifUp}, angDelta#{angDelta}, deltaNorm #{normDelta}, newDelta #{newDelta.x} #{newDelta.y}")
        panVector = new THREE.Vector3(newDelta.x,newDelta.y,0)
        ###
        
        console.log("pan vector: ("+panVector.x+", "+panVector.y+", "+panVector.z+")")
        
        
        
        pan = panVector
        @object.position.add pan
        @target.add pan
        
        #console.log("mouse: ("+mouseChange.x+ ", "+ mouseChange.y +") Pan:("+pan.x+ ", " + pan.y + ", "+pan.z+")");
        _panStart = _panEnd

        
    @update_old = ->
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
     
    @update = =>
      if not @noRotate
        @rotateCamera()
      if not @noZoom
        @zoomCamera()
      if not @noPan 
        @panCamera()
        
      @object.position.addVectors( @target, @eye)
      @object.lookAt(@target)
      
      if ( lastPosition.distanceToSquared( @object.position ) >0)
        @dispatchEvent(changeEvent)
        lastPosition.copy(@object.position)
    
    getAutoRotationAngle = ->
      2 * Math.PI / 60 / 60 * scope.autoRotateSpeed
      
    getZoomScale = ->
      Math.pow 0.95, scope.userZoomSpeed
      
    onMouseDown = (event) ->
      return  unless scope.userRotate
      event.preventDefault()
      if event.button is 0
        state = STATE.ROTATE
        rotateStart.set event.clientX, event.clientY
      else if event.button is 2
        state = STATE.PAN
        _panStart = _panEnd = new THREE.Vector2(event.clientX, event.clientY)
      else if event.button is 1 
        state = STATE.ZOOM
        zoomStart.set(event.clientX, event.clientY)
        

      document.addEventListener "mousemove", onMouseMove, false
      document.addEventListener "mouseup", onMouseUp, false
      
    onMouseMove = (event) ->
      event.preventDefault()
      if state is STATE.ROTATE
        rotateEnd.set event.clientX, event.clientY
        rotateDelta.subVectors rotateEnd, rotateStart
        scope.rotateLeft 2 * Math.PI * rotateDelta.x / PIXELS_PER_ROUND * scope.userRotateSpeed*-1
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
      else if state is STATE.PAN
        _panEnd = new THREE.Vector2(event.clientX, event.clientY)
        
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