define (require) ->
  THREE = require 'three'


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
   return outlineShader