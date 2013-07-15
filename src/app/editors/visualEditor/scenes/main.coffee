define (require) ->
  THREE = require 'three'
  
  mainScene = new THREE.Scene()

  #console.log "Setting up lights"
  pointLight = new THREE.PointLight(0x333333,4)
  pointLight.position.x = -2500
  pointLight.position.y = -2500
  pointLight.position.z = 2200
  
  pointLight2 = new THREE.PointLight(0x333333,3)
  pointLight2.position.x = 2500
  pointLight2.position.y = 2500
  pointLight2.position.z = -5200

  ambientColor = 0x253565
  ambientColor = 0x354575
  ambientColor = 0x455585
  ambientColor = 0x565595
  ambientLight = new THREE.AmbientLight(ambientColor)
  
  spotLight = new THREE.SpotLight( 0xbbbbbb, 1.5)    
  spotLight.position.x = 50
  spotLight.position.y = 50
  spotLight.position.z = 300
  
  #spotLight.shadowCameraVisible = true
  
  spotLight.shadowCameraNear = 1
  spotLight.shadowCameraFar = 500
  spotLight.shadowCameraFov = 50
  
  spotLight.shadowMapBias = 0.000039
  spotLight.shadowMapDarkness = 0.5
  shadowResolution = 512 #parseInt(@settings.shadowResolution.split("x")[0])
  spotLight.shadowMapWidth = shadowResolution
  spotLight.shadowMapHeight = shadowResolution
  
  spotLight.castShadow = true
  
  light= spotLight 
  
  #@camera.add(pointLight)
  lights = [ambientLight,pointLight, pointLight2, spotLight]
  mainScene.lights = lights
  for light in lights
    mainScene.add(light)
  return mainScene