define (require) ->
  THREE = require 'three'
  ###
  @author Eberhard Graether / http://egraether.com/
  ###
  THREE.TrackballControls = (object, domElement) ->
    
    # API
    #A
    #S
    #D
    
    # internals
    
    # for reset
    
    # events
    
    # methods
    
    # listeners
    keydown = (event) ->
      return  if _this.enabled is false
      window.removeEventListener "keydown", keydown
      _prevState = _state
      if _state isnt STATE.NONE
        return
      else if event.keyCode is _this.keys[STATE.ROTATE] and not _this.noRotate
        _state = STATE.ROTATE
      else if event.keyCode is _this.keys[STATE.ZOOM] and not _this.noZoom
        _state = STATE.ZOOM
      else _state = STATE.PAN  if event.keyCode is _this.keys[STATE.PAN] and not _this.noPan
    keyup = (event) ->
      return  if _this.enabled is false
      _state = _prevState
      window.addEventListener "keydown", keydown, false
    mousedown = (event) ->
      return  if _this.enabled is false
      event.preventDefault()
      event.stopPropagation()
      _state = event.button  if _state is STATE.NONE
      if _state is STATE.ROTATE and not _this.noRotate
        _rotateStart = _rotateEnd = _this.getMouseProjectionOnBall(event.clientX, event.clientY)
      else if _state is STATE.ZOOM and not _this.noZoom
        _zoomStart = _zoomEnd = _this.getMouseOnScreen(event.clientX, event.clientY)
      else _panStart = _panEnd = _this.getMouseOnScreen(event.clientX, event.clientY)  if _state is STATE.PAN and not _this.noPan
      document.addEventListener "mousemove", mousemove, false
      document.addEventListener "mouseup", mouseup, false
    mousemove = (event) ->
      return  if _this.enabled is false
      event.preventDefault()
      event.stopPropagation()
      if _state is STATE.ROTATE and not _this.noRotate
        _rotateEnd = _this.getMouseProjectionOnBall(event.clientX, event.clientY)
      else if _state is STATE.ZOOM and not _this.noZoom
        _zoomEnd = _this.getMouseOnScreen(event.clientX, event.clientY)
      else _panEnd = _this.getMouseOnScreen(event.clientX, event.clientY)  if _state is STATE.PAN and not _this.noPan
    mouseup = (event) ->
      return  if _this.enabled is false
      event.preventDefault()
      event.stopPropagation()
      _state = STATE.NONE
      document.removeEventListener "mousemove", mousemove
      document.removeEventListener "mouseup", mouseup
    mousewheel = (event) ->
      return  if _this.enabled is false
      event.preventDefault()
      event.stopPropagation()
      delta = 0
      if event.wheelDelta # WebKit / Opera / Explorer 9
        delta = event.wheelDelta / 40
      # Firefox
      else delta = -event.detail / 3  if event.detail
      _zoomStart.y += (1 / delta) * 0.05
    touchstart = (event) ->
      return  if _this.enabled is false
      switch event.touches.length
        when 1
          _state = STATE.TOUCH_ROTATE
          _rotateStart = _rotateEnd = _this.getMouseProjectionOnBall(event.touches[0].pageX, event.touches[0].pageY)
        when 2
          _state = STATE.TOUCH_ZOOM
          dx = event.touches[0].pageX - event.touches[1].pageX
          dy = event.touches[0].pageY - event.touches[1].pageY
          _touchZoomDistanceEnd = _touchZoomDistanceStart = Math.sqrt(dx * dx + dy * dy)
        when 3
          _state = STATE.TOUCH_PAN
          _panStart = _panEnd = _this.getMouseOnScreen(event.touches[0].pageX, event.touches[0].pageY)
        else
          _state = STATE.NONE
    touchmove = (event) ->
      return  if _this.enabled is false
      event.preventDefault()
      event.stopPropagation()
      switch event.touches.length
        when 1
          _rotateEnd = _this.getMouseProjectionOnBall(event.touches[0].pageX, event.touches[0].pageY)
        when 2
          dx = event.touches[0].pageX - event.touches[1].pageX
          dy = event.touches[0].pageY - event.touches[1].pageY
          _touchZoomDistanceEnd = Math.sqrt(dx * dx + dy * dy)
        when 3
          _panEnd = _this.getMouseOnScreen(event.touches[0].pageX, event.touches[0].pageY)
        else
          _state = STATE.NONE
    touchend = (event) ->
      return  if _this.enabled is false
      switch event.touches.length
        when 1
          _rotateStart = _rotateEnd = _this.getMouseProjectionOnBall(event.touches[0].pageX, event.touches[0].pageY)
        when 2
          _touchZoomDistanceStart = _touchZoomDistanceEnd = 0
        when 3
          _panStart = _panEnd = _this.getMouseOnScreen(event.touches[0].pageX, event.touches[0].pageY)
      _state = STATE.NONE
    THREE.EventDispatcher.call this
    _this = this
    STATE =
      NONE: -1
      ROTATE: 0
      ZOOM: 1
      PAN: 2
      TOUCH_ROTATE: 3
      TOUCH_ZOOM: 4
      TOUCH_PAN: 5
  
    @object = object
    @domElement = (if (domElement isnt `undefined`) then domElement else document)
    @enabled = true
    @screen =
      width: 0
      height: 0
      offsetLeft: 0
      offsetTop: 0
  
    @radius = (@screen.width + @screen.height) / 4
    @rotateSpeed = 1.0
    @zoomSpeed = 1.2
    @panSpeed = 0.3
    @noRotate = false
    @noZoom = false
    @noPan = false
    @staticMoving = false
    @dynamicDampingFactor = 0.2
    @minDistance = 0
    @maxDistance = Infinity
    @keys = [65, 83, 68]
    @target = new THREE.Vector3()
    lastPosition = new THREE.Vector3()
    _state = STATE.NONE
    _prevState = STATE.NONE
    _eye = new THREE.Vector3()
    _rotateStart = new THREE.Vector3()
    _rotateEnd = new THREE.Vector3()
    _zoomStart = new THREE.Vector2()
    _zoomEnd = new THREE.Vector2()
    _touchZoomDistanceStart = 0
    _touchZoomDistanceEnd = 0
    _panStart = new THREE.Vector2()
    _panEnd = new THREE.Vector2()
    @target0 = @target.clone()
    @position0 = @object.position.clone()
    @up0 = @object.up.clone()
    changeEvent = type: "change"
    @handleResize = ->
      @screen.width = window.innerWidth
      @screen.height = window.innerHeight
      @screen.offsetLeft = 0
      @screen.offsetTop = 0
      @radius = (@screen.width + @screen.height) / 4
  
    @handleEvent = (event) ->
      this[event.type] event  if typeof this[event.type] is "function"
  
    @getMouseOnScreen = (clientX, clientY) ->
      new THREE.Vector2((clientX - _this.screen.offsetLeft) / _this.radius * 0.5, (clientY - _this.screen.offsetTop) / _this.radius * 0.5)
  
    @getMouseProjectionOnBall = (clientX, clientY) ->
      mouseOnBall = new THREE.Vector3((clientX - _this.screen.width * 0.5 - _this.screen.offsetLeft) / _this.radius, (_this.screen.height * 0.5 + _this.screen.offsetTop - clientY) / _this.radius, 0.0)
      length = mouseOnBall.length()
      if length > 1.0
        mouseOnBall.normalize()
      else
        mouseOnBall.z = Math.sqrt(1.0 - length * length)
      _eye.copy(_this.object.position).sub _this.target
      projection = _this.object.up.clone().setLength(mouseOnBall.y)
      projection.add _this.object.up.clone().cross(_eye).setLength(mouseOnBall.x)
      projection.add _eye.setLength(mouseOnBall.z)
      projection
  
    @rotateCamera = ->
      angle = Math.acos(_rotateStart.dot(_rotateEnd) / _rotateStart.length() / _rotateEnd.length())
      if angle
        axis = (new THREE.Vector3()).crossVectors(_rotateStart, _rotateEnd).normalize()
        quaternion = new THREE.Quaternion()
        angle *= _this.rotateSpeed
        quaternion.setFromAxisAngle axis, -angle
        _eye.applyQuaternion quaternion
        _this.object.up.applyQuaternion quaternion
        _rotateEnd.applyQuaternion quaternion
        if _this.staticMoving
          _rotateStart.copy _rotateEnd
        else
          quaternion.setFromAxisAngle axis, angle * (_this.dynamicDampingFactor - 1.0)
          _rotateStart.applyQuaternion quaternion
  
    @zoomCamera = ->
      if _state is STATE.TOUCH_ZOOM
        factor = _touchZoomDistanceStart / _touchZoomDistanceEnd
        _touchZoomDistanceStart = _touchZoomDistanceEnd
        _eye.multiplyScalar factor
      else
        factor = 1.0 + (_zoomEnd.y - _zoomStart.y) * _this.zoomSpeed
        if factor isnt 1.0 and factor > 0.0
          _eye.multiplyScalar factor
          if _this.staticMoving
            _zoomStart.copy _zoomEnd
          else
            _zoomStart.y += (_zoomEnd.y - _zoomStart.y) * @dynamicDampingFactor
  
    @panCamera = ->
      mouseChange = _panEnd.clone().sub(_panStart)
      if mouseChange.lengthSq()
        mouseChange.multiplyScalar _eye.length() * _this.panSpeed
        pan = _eye.clone().cross(_this.object.up).setLength(mouseChange.x)
        pan.add _this.object.up.clone().setLength(mouseChange.y)
        _this.object.position.add pan
        _this.target.add pan
        if _this.staticMoving
          _panStart = _panEnd
        else
          _panStart.add mouseChange.subVectors(_panEnd, _panStart).multiplyScalar(_this.dynamicDampingFactor)
  
    @checkDistances = ->
      if not _this.noZoom or not _this.noPan
        _this.object.position.setLength _this.maxDistance  if _this.object.position.lengthSq() > _this.maxDistance * _this.maxDistance
        _this.object.position.addVectors _this.target, _eye.setLength(_this.minDistance)  if _eye.lengthSq() < _this.minDistance * _this.minDistance
  
    @update = ->
      _eye.subVectors _this.object.position, _this.target
      _this.rotateCamera()  unless _this.noRotate
      _this.zoomCamera()  unless _this.noZoom
      _this.panCamera()  unless _this.noPan
      _this.object.position.addVectors _this.target, _eye
      _this.checkDistances()
      _this.object.lookAt _this.target
      if lastPosition.distanceToSquared(_this.object.position) > 0
        _this.dispatchEvent changeEvent
        lastPosition.copy _this.object.position
  
    @reset = ->
      _state = STATE.NONE
      _prevState = STATE.NONE
      _this.target.copy _this.target0
      _this.object.position.copy _this.position0
      _this.object.up.copy _this.up0
      _eye.subVectors _this.object.position, _this.target
      _this.object.lookAt _this.target
      _this.dispatchEvent changeEvent
      lastPosition.copy _this.object.position
  
    @domElement.addEventListener "contextmenu", ((event) ->
      event.preventDefault()
    ), false
    @domElement.addEventListener "mousedown", mousedown, false
    @domElement.addEventListener "mousewheel", mousewheel, false
    @domElement.addEventListener "DOMMouseScroll", mousewheel, false # firefox
    @domElement.addEventListener "touchstart", touchstart, false
    @domElement.addEventListener "touchend", touchend, false
    @domElement.addEventListener "touchmove", touchmove, false
    window.addEventListener "keydown", keydown, false
    window.addEventListener "keyup", keyup, false
    @handleResize()
  return THREE.TrackballControls