/*
 *  @author zz85 / http://twitter.com/blurspline / http://www.lab4games.net/zz85/blog
 *
 *  A general perpose camera, for setting FOV, Lens Focal Length,
 *      and switching between perspective and orthographic views easily.
 *      Use this only if you do not wish to manage
 *      both a Orthographic and Perspective Camera
 *
 */


THREE.CombinedCamera = function ( width, height, fov, near, far, orthoNear, orthoFar ) {

    THREE.Camera.call( this );

    this.fov = fov;

    this.left = -width / 2;
    this.right = width / 2
    this.top = height / 2;
    this.bottom = -height / 2;

    // We could also handle the projectionMatrix internally, but just wanted to test nested camera objects

    this.cameraO = new THREE.OrthographicCamera( width / - 2, width / 2, height / 2, height / - 2,  orthoNear, orthoFar );
    this.cameraP = new THREE.PerspectiveCamera( fov, width / height, near, far );

    this.zoom = 1;

    this.toPerspective();

    var aspect = width/height;
    this.target = new THREE.Object3D()

};

THREE.CombinedCamera.prototype = Object.create( THREE.Camera.prototype );




THREE.CombinedCamera.prototype.lookAt = function () {

    // This routine does not support cameras with rotated and/or translated parent(s)

    var m1 = new THREE.Matrix4();

    return function ( vector ) {
        this.target = vector;
        if(this.inOrthographicMode===true)
        {
            this.toOrthographic();
        }
        
        m1.lookAt( this.position, vector, this.up );

        if ( this.useQuaternion === true )  {

            this.quaternion.setFromRotationMatrix( m1 );

        } else {

            this.rotation.setEulerFromRotationMatrix( m1, this.eulerOrder );

        }

    };

}();


THREE.CombinedCamera.prototype.toPerspective = function () {

    // Switches to the Perspective Camera

    this.near = this.cameraP.near;
    this.far = this.cameraP.far;

    this.cameraP.fov =  this.fov / this.zoom ;

    this.cameraP.updateProjectionMatrix();

    this.projectionMatrix = this.cameraP.projectionMatrix;

    this.inPerspectiveMode = true;
    this.inOrthographicMode = false;

};

THREE.CombinedCamera.prototype.toOrthographic = function () {

    // Switches to the Orthographic camera estimating viewport from Perspective

    var fov = this.fov;
    var aspect = this.cameraP.aspect;
    var near = this.cameraP.near;
    var far = this.cameraP.far;

    var distance = this.position.length()*0.3;
    console.log("distance",distance);
    var width = Math.tan(fov) * distance * aspect;
    var height = Math.tan (fov) * distance;
    console.log("distance",distance,"height",height,"width",width);
    
    //TODO: distance should not be relative to [0,0,0], but to the target (taking panning into account)
    //cameraP
    //set the orthographic view rectangle to 0,0,width,height
    //see here : http://stackoverflow.com/questions/13483775/set-zoomvalue-of-a-perspective-equal-to-perspective

    // The size that we set is the mid plane of the viewing frustum
    /*
    var hyperfocus = ( near + far ) / 2;

    var halfHeight = Math.tan( fov / 2 ) * hyperfocus;
    var planeHeight = 2 * halfHeight;
    var planeWidth = planeHeight * aspect;
    var halfWidth = planeWidth / 2;

    halfHeight /= this.zoom;
    halfWidth /= this.zoom;*/
   
    var halfWidth = width;
    var halfHeight = height;

    this.cameraO.left = halfWidth;
    this.cameraO.right = -halfWidth;
    this.cameraO.top = -halfHeight;
    this.cameraO.bottom = halfHeight;


    this.cameraO.updateProjectionMatrix();

    this.near = this.cameraO.near;
    this.far = this.cameraO.far;
    this.projectionMatrix = this.cameraO.projectionMatrix;

    this.inPerspectiveMode = false;
    this.inOrthographicMode = true;

};


THREE.CombinedCamera.prototype.setSize = function( width, height ) {

    this.cameraP.aspect = width / height;
    this.left = -width / 2;
    this.right = width / 2
    this.top = height / 2;
    this.bottom = -height / 2;

};


THREE.CombinedCamera.prototype.setFov = function( fov ) {

    this.fov = fov;

    if ( this.inPerspectiveMode ) {

        this.toPerspective();

    } else {

        this.toOrthographic();

    }

};

// For mantaining similar API with PerspectiveCamera

THREE.CombinedCamera.prototype.updateProjectionMatrix = function() {

    if ( this.inPerspectiveMode ) {

        this.toPerspective();

    } else {

        this.toPerspective();
        this.toOrthographic();

    }

};

/*
* Uses Focal Length (in mm) to estimate and set FOV
* 35mm (fullframe) camera is used if frame size is not specified;
* Formula based on http://www.bobatkins.com/photography/technical/field_of_view.html
*/
THREE.CombinedCamera.prototype.setLens = function ( focalLength, frameHeight ) {

    if ( frameHeight === undefined ) frameHeight = 24;

    var fov = 2 * THREE.Math.radToDeg( Math.atan( frameHeight / ( focalLength * 2 ) ) );

    this.setFov( fov );

    return fov;
};


THREE.CombinedCamera.prototype.setZoom = function( zoom ) {

    this.zoom = zoom;

    if ( this.inPerspectiveMode ) {

        this.toPerspective();

    } else {

        this.toOrthographic();

    }

};

THREE.CombinedCamera.prototype.toFrontView = function() {

    this.rotation.x = 0;
    this.rotation.y = 0;
    this.rotation.z = 0;
    


};

THREE.CombinedCamera.prototype.toBackView = function() {

    this.rotation.x = 0;
    this.rotation.y = Math.PI;
    this.rotation.z = 0;
    this.rotationAutoUpdate = false;

};

THREE.CombinedCamera.prototype.toLeftView = function() {

    this.rotation.x = 0;
    this.rotation.y = - Math.PI / 2;
    this.rotation.z = 0;
    this.rotationAutoUpdate = false;
    
    
    /*try
    offset = @camera.position.clone().sub(@controls.target)
    nPost = new  THREE.Vector3()
    nPost.x = offset.length()
    @camera.position = nPost
  catch error
    @camera.position = new THREE.Vector3(@defaultCameraPosition.x,0,0)*/

};

THREE.CombinedCamera.prototype.toRightView = function() {

    this.rotation.x = 0;
    this.rotation.y = Math.PI / 2;
    this.rotation.z = 0;
    this.rotationAutoUpdate = false;

};

THREE.CombinedCamera.prototype.toTopView = function() {

    this.rotation.x = - Math.PI / 2;
    this.rotation.y = 0;
    this.rotation.z = 0;
    this.rotationAutoUpdate = false;

};

THREE.CombinedCamera.prototype.toBottomView = function() {

    this.rotation.x = Math.PI / 2;
    this.rotation.y = 0;
    this.rotation.z = 0;
    this.rotationAutoUpdate = false;

};
