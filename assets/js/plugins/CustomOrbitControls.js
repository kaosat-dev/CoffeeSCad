/**
 * @author qiao / https://github.com/qiao
 * @author mrdoob / http://mrdoob.com
 * @author alteredq / http://alteredqualia.com/
 * @author WestLangley / https://github.com/WestLangley
 */

THREE.CustomOrbitControls = function ( object, domElement ) {

    //THREE.EventTarget.call( this );

    this.object = object;
    this.domElement = ( domElement !== undefined ) ? domElement : document;

    // API

    this.target = new THREE.Vector3();
    this.eye = new THREE.Vector3();

    this.zoom = 1.0;
    this.userZoom = true;
    this.userZoomSpeed = 1.0;

    this.userRotate = true;
    this.userRotateSpeed = 1.0;

    this.autoRotate = false;
    this.autoRotateSpeed = 2.0; // 30 seconds per round when fps is 60

    this.minPolarAngle = 0; // radians
    this.maxPolarAngle = Math.PI; // radians

    this.minDistance = 0;
    this.maxDistance = Infinity;
    
    
    //
    this.panSpeed = 0.3;

    this.noRotate = false;
    this.noZoom = false;
    this.noPan = false;
    
    var _panStart = new THREE.Vector2();
    var _panEnd = new THREE.Vector2();

    // internals

    var scope = this;

    var EPS = 0.000001;
    var PIXELS_PER_ROUND = 1800;

    var rotateStart = new THREE.Vector2();
    var rotateEnd = new THREE.Vector2();
    var rotateDelta = new THREE.Vector2();

    var zoomStart = new THREE.Vector2();
    var zoomEnd = new THREE.Vector2();
    var zoomDelta = new THREE.Vector2();

    var phiDelta = 0;
    var thetaDelta = 0;
    var scale = 1;

    var lastPosition = new THREE.Vector3();

    var STATE = { NONE : -1, ROTATE : 0, ZOOM : 1 , PAN:2};
    var state = STATE.NONE;

    // events

    var changeEvent = { type: 'change' };


    this.rotateLeft = function ( angle ) {

        if ( angle === undefined ) {

            angle = getAutoRotationAngle();

        }

        thetaDelta += angle;

    };

    this.rotateRight = function ( angle ) {

        if ( angle === undefined ) {

            angle = getAutoRotationAngle();

        }

        thetaDelta -= angle;

    };

    this.rotateUp = function ( angle ) {

        if ( angle === undefined ) {

            angle = getAutoRotationAngle();

        }

        phiDelta -= angle;

    };

    this.rotateDown = function ( angle ) {

        if ( angle === undefined ) {

            angle = getAutoRotationAngle();

        }

        phiDelta += angle;
        
    };

    this.zoomIn = function ( zoomScale ) {

        if ( zoomScale === undefined ) {

            zoomScale = getZoomScale();
        }

        scale /= zoomScale;
    };

    this.zoomOut = function ( zoomScale ) {

        if ( zoomScale === undefined ) {

            zoomScale = getZoomScale();

        }

        scale *= zoomScale;
    };

   
    this.update_old= function () {

        var position = this.object.position;
        var offset = position.clone().subSelf( this.target )

        // angle from z-axis around y-axis

        var theta = Math.atan2( offset.x, offset.z );

        // angle from y-axis

        var phi = Math.atan2( Math.sqrt( offset.x * offset.x + offset.z * offset.z ), offset.y );

        if ( this.autoRotate ) {

            this.rotateLeft( getAutoRotationAngle() );

        }

        theta += thetaDelta;
        phi += phiDelta;

        // restrict phi to be between desired limits
        phi = Math.max( this.minPolarAngle, Math.min( this.maxPolarAngle, phi ) );

        // restrict phi to be betwee EPS and PI-EPS
        phi = Math.max( EPS, Math.min( Math.PI - EPS, phi ) );

        var radius = offset.length() * scale;

        // restrict radius to be between desired limits
        radius = Math.max( this.minDistance, Math.min( this.maxDistance, radius ) );

        offset.x = radius * Math.sin( phi ) * Math.sin( theta );
        offset.y = radius * Math.cos( phi );
        offset.z = radius * Math.sin( phi ) * Math.cos( theta );

        position.copy( this.target ).addSelf( offset );
        this.object.lookAt( this.target );
        
        
        //hack for camera
       

        thetaDelta = 0;
        phiDelta = 0;
        scale = 1;

        if ( lastPosition.distanceTo( this.object.position ) > 0 ) {

            this.dispatchEvent( changeEvent );

            lastPosition.copy( this.object.position );
            
            if (this.object.inOrthographicMode)
            {
                this.zoom = radius/1000;
                console.log("Zoom");
                console.log(this.zoom)
                console.log("radius");
                console.log(radius/1000);
            }
        this.object.setZoom(this.zoom);
        }

    };
    

    this.update = function(){
        
        if ( !this.noRotate ) {

           this.rotateCamera();

        }
        
        if ( !this.noZoom ) {

            this.zoomCamera();

        }
        if ( !this.noPan )
        {
            this.panCamera();
        }
        
        this.object.position.add( this.target, this.eye );
        //this.object.position.copy( this.target ).addSelf( this.eye  );
        this.object.lookAt( this.target );

        
        if ( lastPosition.distanceToSquared( this.object.position ) > 0 ) {

            this.dispatchEvent( changeEvent );

            lastPosition.copy( this.object.position );
        }
    };
    
    this.zoomCamera = function()
    {
        var position = this.object.position;
        var offset = position.clone().subSelf( this.target )
        var radius = offset.length() * scale;

        // restrict radius to be between desired limits
        radius = Math.max( this.minDistance, Math.min( this.maxDistance, radius ) );
        this.eye.multiplyScalar(radius);
        scale = 1.0;
       /*
       var factor = 1.0 + ( zoomEnd.y - zoomStart.y ) * this.userZoomSpeed;
        if ( factor !== 1.0 && factor > 0.0 ) {
            this.eye.multiplyScalar( factor*2000);
        }*/
        

    };
    
    this.rotateCamera = function () {
     
        var position = this.object.position;
        var offset = position.clone().subSelf( this.target )

        // angle from z-axis around y-axis

        var theta = Math.atan2( offset.x, offset.y );

        // angle from y-axis

        var phi = Math.atan2( Math.sqrt( offset.x * offset.x + offset.y * offset.y ), offset.z );

        /*
        if ( this.autoRotate ) {

            this.rotateLeft( getAutoRotationAngle() );

        }*/

        theta += thetaDelta;
        phi += phiDelta;

        // restrict phi to be between desired limits
        phi = Math.max( this.minPolarAngle, Math.min( this.maxPolarAngle, phi ) );

        // restrict phi to be betwee EPS and PI-EPS
        phi = Math.max( EPS, Math.min( Math.PI - EPS, phi ) );

        
        offset.x = Math.sin( phi ) * Math.sin( theta );
        offset.z = Math.cos( phi );
        offset.y = Math.sin( phi ) * Math.cos( theta );

        this.eye = offset
        
        thetaDelta = 0;
        phiDelta = 0;
        //scale = 1;
     };

    
    this.panCamera = function () {

        var mouseChange = _panEnd.clone().subSelf( _panStart );
        
        if ( mouseChange.lengthSq() ) {
            
            //mouseChange.multiplyScalar( this.target.length() * this.panSpeed );
            mouseChange.multiplyScalar(this.panSpeed );
            //mouseChange.multiplyScalar( this.eye.length() * this.panSpeed );
            
            var pan = this.target.clone().crossSelf(this.object.up ).setLength( mouseChange.x );
            pan.addSelf( this.object.up.clone().setLength( mouseChange.y ) );
            
            
            var pan2 = this.object.up.clone()
            //console.log("up vector: ("+pan2.x+", "+pan2.y+", ",+pan2.z+")")
            this.object.matrixWorld.multiplyVector3( pan2 );
            //console.log("up vector 2: ("+pan2.x+", "+pan2.y+", ",+pan2.z+")")

            /*we need two vectors relative to the camera: up and left 
             *  for this we need the "eye vector (see below) and either cam.up or cam.left to get the other"
             * and scale these two by mousechange values
             * */
            //get "eye vector" (ray from cam to target)
            var eyeVector = this.object.position.clone().subSelf( this.target );
            //get cam up vector 
            var upVector = this.object.up.clone();
            //left/right vector
            //var sideVector = new THREE.Vector3(1,0,0);
            //var panVector = new THREE.Vector3(mouseChange.x,0,mouseChange.y).crossSelf(eyeVector);
            
            var panVector = eyeVector.crossSelf(upVector).setLength( mouseChange.x );
            panVector.addSelf(upVector.setLength( mouseChange.y ) );
            
            //console.log("eyeVector: ("+eyeVector.x+", "+eyeVector.y+", ",+eyeVector.z+")");
            //console.log("pan vector: ("+panVector.x+", "+panVector.y+", ",+panVector.z+")");
            
            pan=panVector;
            this.object.position.addSelf( pan);
            this.target.addSelf(pan);
            
            //console.log("mouse: ("+mouseChange.x+ ", "+ mouseChange.y +") Pan:("+pan.x+ ", " + pan.y + ", "+pan.z+")");
       
            
            _panStart = _panEnd;
            /*
            if ( _this.staticMoving ) {

                _panStart = _panEnd;

            } else {

                _panStart.addSelf( mouseChange.sub( _panEnd, _panStart ).multiplyScalar( _this.dynamicDampingFactor ) );

            }*/

        }

    };


    function getAutoRotationAngle() {

        return 2 * Math.PI / 60 / 60 * scope.autoRotateSpeed;

    }

    function getZoomScale() {

        return Math.pow( 0.95, scope.userZoomSpeed );

    }

    function onMouseDown( event ) {

        if ( !scope.userRotate ) return;

        event.preventDefault();

        if ( event.button === 0 ) {

            state = STATE.ROTATE;

            rotateStart.set( event.clientX, event.clientY );

        }else if (event.button ===2) {
            
            state = STATE.PAN;
            
            _panStart = _panEnd = new THREE.Vector2( event.clientX, event.clientY );
            
        }else if ( event.button === 1 ) {

            state = STATE.ZOOM;

            zoomStart.set( event.clientX, event.clientY );

        }

        document.addEventListener( 'mousemove', onMouseMove, false );
        document.addEventListener( 'mouseup', onMouseUp, false );

    }

    function onMouseMove( event ) {

        event.preventDefault();

        if ( state === STATE.ROTATE ) {

            rotateEnd.set( event.clientX, event.clientY );
            rotateDelta.sub( rotateEnd, rotateStart );

            scope.rotateLeft( 2 * Math.PI * rotateDelta.x / PIXELS_PER_ROUND * scope.userRotateSpeed );
            scope.rotateUp( 2 * Math.PI * rotateDelta.y / PIXELS_PER_ROUND * scope.userRotateSpeed );

            rotateStart.copy( rotateEnd );

        } else if ( state === STATE.ZOOM ) {

            zoomEnd.set( event.clientX, event.clientY );
            zoomDelta.sub( zoomEnd, zoomStart );

            if ( zoomDelta.y > 0 ) {

                scope.zoomIn();

            } else {

                scope.zoomOut();
            }
            zoomStart.copy( zoomEnd );
        }else if (state === STATE.PAN){
            
            _panEnd = new THREE.Vector2( event.clientX, event.clientY );
        }
        

    }

    function onMouseUp( event ) {

        if ( ! scope.userRotate ) return;

        document.removeEventListener( 'mousemove', onMouseMove, false );
        document.removeEventListener( 'mouseup', onMouseUp, false );

        state = STATE.NONE;

    }

    function onMouseWheel( event ) {

        if ( ! scope.userZoom ) return;
        
        var event = window.event || event;
        var wheelDelta = null;
        
        if ('wheelDelta' in event)
        {
            wheelDelta = event.wheelDelta;
        }else
        {
            wheelDelta = event.detail * (-120);
        }

        if (wheelDelta > 0 ) {

            scope.zoomOut();

        } else {

            scope.zoomIn();
        }
        
        /*
        var delta = 0;

        if ( event.wheelDelta ) { // WebKit / Opera / Explorer 9

            delta = event.wheelDelta / 40;

        } else if ( event.detail ) { // Firefox

            delta = - event.detail / 3;

        }
        zoomStart.y += ( 1 / delta ) * 0.05;*/
    }
    

    this.domElement.addEventListener( 'contextmenu', function ( event ) { event.preventDefault(); }, false );
    this.domElement.addEventListener( 'mousedown', onMouseDown, false );
    this.domElement.addEventListener( 'mousewheel', onMouseWheel, false );
    this.domElement.addEventListener( 'DOMMouseScroll', onMouseWheel, false );

};
