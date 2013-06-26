edgeHighlightShader = 
          uniforms:
              "tDiffuse": { type: "t", value: null }
              "tDepth": { type: "t", value: null }
              "tNormal": { type: "t", value: null }
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

edgeHighlightPass = new THREE.ShaderPass(edgeHighlightShader)