define (require)->

  linearExtrude= (options)->
    #basic linear extrude, with optional twist
    
    
  rotateExtrude= (options)->


  splineExtrude= (options)->
    #allow creation from points or directly from curve
    apath = new THREE.SplineCurve3();
    apath.points.push(new THREE.Vector3(-50, 150, 10));
    apath.points.push(new THREE.Vector3(-20, 180, 20));
    apath.points.push(new THREE.Vector3(40, 220, 50));
    apath.points.push(new THREE.Vector3(200, 290, 100));
    randomSpline =  new THREE.SplineCurve3(randomPoints)
    extrudeSettings.extrudePath = randomSpline;
