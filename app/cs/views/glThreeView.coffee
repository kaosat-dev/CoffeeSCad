define (require) ->
  $ = require 'jquery'
  marionette = require 'marionette'
  THREE = require 'three'
  threedView_template = require "text!templates/3dview.tmpl"
  requestAnimationFrame = require 'anim'
  
  class GlThreeView extends marionette.ItemView
    template: threedView_template
    ui:
      renderBlock : "#glArea"
    triggers:
      'mousedown': 'mdown'
      #'mousemove': 'mmove'
    events:
      'mousemove'   : 'mousemove'
      'mouseup'     : 'mouseup'
    
    mousemove:(ev)->
      
    
    mouseup:(ev)=>
      ###console.log ev
      console.log "clientX: #{ev.clientX} clientY: #{ev.clientY}"
      console.log "clientX: #{ev.offsetX} clientY: #{ev.offsetY}"
      ###
      
      #$(@ui.renderBlock)
      x = ev.offsetX;
      y = ev.offsetY;
      v = new THREE.Vector3((x/@width)*2-1, -(y/@height)*2+1, 0.5)
      @projector.unprojectVector(v, @camera)
      ray = new THREE.Ray(@camera.position, v.subSelf(@camera.position).normalize())
      
      #console.log(ray)
      #console.log @controller
      #console.log("Controller objects "+@controller.objects)
      intersects = ray.intersectObjects(@controller.objects)
      
      if intersects?
        #console.log "interesects" 
        #console.log intersects
        if intersects.length > 0
          @controller.setCurrent(intersects[0].object)
          console.log @current.name
          newMat = new THREE.MeshLambertMaterial
            color: 0x0000FF
          @current.material = newMat
        else
          if @current?
            newMat = new THREE.MeshLambertMaterial
              color: 0xCC0000
            @current.material = newMat
            @current=null
            
      
    
    constructor:(options)->
      super options
      
      @width = 800
      @height = 600
      
      #camera attributes
      @viewAngle=45
      ASPECT = @width / @height
      NEAR = 1
      FAR = 10000
      
      #console.log("Aspect: #{ASPECT}")
      #create a WebGL renderer, camera
      #and a scene
      @renderer = new THREE.WebGLRenderer 
        clearColor: 0xEEEEEE
        clearAlpha: 1
        antialias: true
      @renderer.clear()  
      
      @camera =
        new THREE.PerspectiveCamera(
          @viewAngle,
          ASPECT,
          NEAR,
          FAR)
      #the camera starts at 0,0,0
      #so pull it back
      @camera.position.z = 300
          
      @scene = new THREE.Scene()
      #add the camera to the scene
      @scene.add(@camera)
      
      @addObjs()
      #@addObjs2()
      @setupLights()
      @addPlane()
      @addStuff()
      
      @renderer.setSize(@width, @height)
  
      @controller = new THREE.Object3D()      
      @controller.setCurrent = (current)=>
        @current = current
        
      @controller.objects = @scene.__objects
      @projector = new THREE.Projector()
        
    addObjs2: () =>
      @cube = new THREE.Mesh(new THREE.CubeGeometry(50,50,50),new THREE.MeshBasicMaterial({color: 0x000000}))
      @scene.add(@cube)
      
    addObjs: () =>
      #set up material
      sphereMaterial =
      new THREE.MeshLambertMaterial
        color: 0xCC0000
      
      
      #set up the sphere vars
      radius = 50
      segments = 16
      rings = 16

      #create a new mesh with
      #sphere geometry - we will cover
      #the sphereMaterial next!
      sphere = new THREE.Mesh(
      
        new THREE.SphereGeometry(
          radius,
          segments,
          rings),
      
        sphereMaterial)
      sphere.name="Shinyyy"
      #add the sphere to the scene
      @scene.add(sphere)
      
      
    
    setupLights:()=>
      #create a point light
      pointLight =
        new THREE.PointLight(0xFFFFFF)

      #set its position
      pointLight.position.x = 10
      pointLight.position.y = 50
      pointLight.position.z = 130

      #add to the scene
      @scene.add(pointLight)
      
    addPlane:()=>
      planeGeo = new THREE.PlaneGeometry(400, 400, 10, 10)
      planeMat = new THREE.LineBasicMaterial({color: 0xFFFFFF, lineWidth: 1})
      #planeMat = new THREE.MeshLambertMaterial({color: 0xFFFFFF})
      plane = new THREE.Mesh(planeGeo, planeMat)
      plane.rotation.x = -Math.PI/2
      plane.position.y = -30
      #plane.receiveShadow = true
      @scene.add(plane)
      
    addStuff:()=>
      v=(x,y,z)->
         return new THREE.Vector3(x,y,z)
      lineGeo = new THREE.Geometry()
      lineGeo.vertices.push(
        v(-50, 0, 0), v(50, 0, 0),
        v(0, -50, 0), v(0, 50, 0),
        v(0, 0, -50), v(0, 0, 50),

        v(-50, 50, -50), v(50, 50, -50),
        v(-50, -50, -50), v(50, -50, -50),
        v(-50, 50, 50), v(50, 50, 50),
        v(-50, -50, 50), v(50, -50, 50),

        v(-50, 0, 50), v(50, 0, 50),
        v(-50, 0, -50), v(50, 0, -50),
        v(-50, 50, 0), v(50, 50, 0),
        v(-50, -50, 0), v(50, -50, 0),

        v(50, -50, -50), v(50, 50, -50),
        v(-50, -50, -50), v(-50, 50, -50),
        v(50, -50, 50), v(50, 50, 50),
        v(-50, -50, 50), v(-50, 50, 50),

        v(0, -50, 50), v(0, 50, 50),
        v(0, -50, -50), v(0, 50, -50),
        v(50, -50, 0), v(50, 50, 0),
        v(-50, -50, 0), v(-50, 50, 0),

        v(50, 50, -50), v(50, 50, 50),
        v(50, -50, -50), v(50, -50, 50),
        v(-50, 50, -50), v(-50, 50, 50),
        v(-50, -50, -50), v(-50, -50, 50),

        v(-50, 0, -50), v(-50, 0, 50),
        v(50, 0, -50), v(50, 0, 50),
        v(0, 50, -50), v(0, 50, 50),
        v(0, -50, -50), v(0, -50, 50)
      )
      lineMat = new THREE.LineBasicMaterial({color: 0x808080, lineWidth: 1})
      line = new THREE.Line(lineGeo, lineMat)
      line.type = THREE.Lines
      @scene.add (line)
      
      
    onRender:()=>
      container = $(@ui.renderBlock)
      container.append(@renderer.domElement)
      @animate()
      
    animate:()=>
      t= new Date().getTime()
      #console.log t
      @camera.position.x = Math.sin(t/10000)*300
      @camera.position.y = 150
      @camera.position.z = Math.cos(t/10000)*300
      # you need to update lookAt on every frame
      @camera.lookAt(@scene.position)
      
      @renderer.render(@scene, @camera)
      requestAnimationFrame(@animate)
      

  return GlThreeView
