define (require) ->
  THREE = require 'three'

  colorInvertShader = 
        uniforms:
            "tDiffuse": { type: "t", value: null }
        vertexShader: 
            """varying vec2 vUv;
            void main() {
                vUv = vec2( uv.x, uv.y );
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }"""
        fragmentShader: 
            """
            uniform sampler2D tDiffuse;
            varying vec2 vUv;
     
            void main() {
                vec4 srcColor = texture2D( tDiffuse, vUv );
                vec4 endColor = vec4(1.0, 1.0, 1.0, 1.0)- srcColor * 200.0;
                if(endColor[0]<0.3)
                {
                  endColor[3]=1.0;
                }
                else
                {
                  endColor[3]=0.0;
                }
                gl_FragColor = endColor;//vec4(1.0, 1.0, 1.0, 1.0)- srcColor * 200.0 ;
            }"""
            

  depthExtractShaderOld= 
    uniforms:
      "tDiffuse": { type: "t", value: null }
    vertexShader: 
      """varying vec2 vUv;
      void main() {
          vUv = vec2( uv.x, uv.y );
          gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
      }"""
    fragmentShader: 
      """
      vec4 pack (float depth)
      {
        const vec4 c_bias = vec4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
       
        float r = depth;
        float g = fract(r * 255.0);
        float b = fract(g * 255.0);
        float a = fract(b * 255.0);
        vec4 color = vec4(r, g, b, a);
       
        return color - (color.yzww * c_bias);
      }
      
      void main()
      {
        const float c_LinearDepthConstant = 1.0 / (1.0 - 30.0);
        float linearDepth = length(v_vPosition) * c_LinearDepthConstant;
       
        gl_FragColor = pack(linearDepth);
      }
      
      """
  
  #most of this is taken from the THREE.js SSAO shader
  depthExtractShader=
    uniforms:
      "tDiffuse": { type: "t", value: null }
      "tDepth":   { type: "t", value: null }
      "size":     { type: "v2", value: new THREE.Vector2( 512, 512 ) }
      "cameraNear":   { type: "f", value: 1 }
      "cameraFar":    { type: "f", value: 100 }
    vertexShader: 
      """varying vec2 vUv;
      void main() 
      {
          vUv = vec2( uv.x, uv.y );
          gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
      }"""
    fragmentShader: 
      """
      uniform sampler2D tDiffuse;
      uniform sampler2D tDepth;
      
      varying vec2 vUv;
      uniform float cameraNear;
      uniform float cameraFar;
      uniform vec2 size;// texture width, height
      
      
      float cameraFarPlusNear = cameraFar + cameraNear;
      float cameraFarMinusNear = cameraFar - cameraNear;
      float cameraCoef = 2.0 * cameraNear;
      
      float unpackDepth( const in vec4 rgba_depth ) 
      {
        const vec4 bit_shift = vec4( 1.0 / ( 256.0 * 256.0 * 256.0 ), 1.0 / ( 256.0 * 256.0 ), 1.0 / 256.0, 1.0 );
        float depth = dot( rgba_depth, bit_shift );
        return depth;
      }
      
      float readDepth( const in vec2 coord ) 
      {
        return cameraCoef / ( cameraFarPlusNear - unpackDepth( texture2D( tDiffuse, coord ) ) * cameraFarMinusNear );
      }
      /*
      float compareDepths( const in float depth1, const in float depth2, inout int far ) 
      {
        float garea = 2.0;                         // gauss bell width
        float diff = ( depth1 - depth2 ) * 100.0; // depth difference (0-100)
  
        // reduce left bell width to avoid self-shadowing
  
        if ( diff < gDisplace ){
          garea = diffArea;
        } else {
         far = 1;
        }
  
        float dd = diff - gDisplace;
        float gauss = pow( EULER, -2.0 * dd * dd / ( garea * garea ) );
        return gauss;
      }*/
      
       void main()
      {
        float depth = readDepth( vUv );
        float depthClampled = clamp( depth, 0.0, 1.0 );
        
        gl_FragColor = vec4(depthClampled, depthClampled, depthClampled,1);
      }
      
      """
       

      




  outlineShader_ = () =>
    outline = {

          uniforms: {

          "linewidth":  { type: "f", value: 0.3 },

          },

          vertex_shader: [

            "uniform float linewidth;",

            "void main() {",

              "vec4 mvPosition = modelViewMatrix * vec4( position, 1.0 );",
              "vec4 displacement = vec4( normalize( normalMatrix * normal ) * linewidth, 0.0 ) + mvPosition;",
              "gl_Position = projectionMatrix * displacement;",

            "}"

          ].join("\n"),

          fragment_shader: [

            "void main() {",

              "gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );",

            "}"

          ].join("\n")

        }
    testMaterial = new THREE.ShaderMaterial
          uniforms: outline.uniforms,
          vertexShader: outline.vertexShader,
          fragmentShader: outline.fragmentShader,
          color: 0x0000FF
          transparent:false
      return testMaterial
  
  outlineShader=()=>
      vertexShader = 
      "void main(){"+
          "float offset = 2.0;"+
          "vec4 pos = modelViewMatrix * vec4( position + normal * offset, 1.0 );"+
          "gl_Position = projectionMatrix * pos;"+
      "}\n"
      
      fragmentShader =
      "void main(){"+
          "gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );"+
      "}\n"
      
      console.log  "THREE.ShaderLib",THREE.ShaderLib   
      testMaterial = new THREE.ShaderMaterial
          uniforms: THREE.ShaderLib['basic'].uniforms,
          vertexShader: vertexShader,
          fragmentShader: fragmentShader,
          color: 0x0000FF
          transparent:false
      return testMaterial
      
      
   return {"colorInvertShader":colorInvertShader, "depthExtractShader":depthExtractShader}
