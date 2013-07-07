/**
 * original @author stemkoski / http://github.com/stemkoski
 * modified by @kaosat-dev / http://github.com/kaosat-dev
 * Blend three textures additively
 * texel1 + texel2
 * + vec4(0.5, 0.75, 1.0, 1.0)
 */

THREE.AdditiveBlendShader = {

    uniforms: {
    
        "tDiffuse1": { type: "t", value: null },
        "tDiffuse2": { type: "t", value: null },
        "tDiffuse3": { type: "t", value: null },
        "normalThreshold": { type: "f", value: 0.1 },
        "depthThreshold": { type: "f", value: 0.05 },
        "strengh"  : { type: "f", value: 0.4 },
        "color"    : { type: "c", value: new THREE.Color( 0x000002 ) }
    },

    vertexShader: [

        "varying vec2 vUv;",

        "void main() {",

            "vUv = uv;",
            "gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",

        "}"

    ].join("\n"),

    fragmentShader: [

        "uniform sampler2D tDiffuse1;",
        "uniform sampler2D tDiffuse2;",
        "uniform sampler2D tDiffuse3;",
        "uniform float normalThreshold;",
        "uniform float depthThreshold;",
        "uniform float strengh;",
        "uniform vec3 color;",

        "varying vec2 vUv;",

        "void main() {",

            "vec4 colorTexel = texture2D( tDiffuse1, vUv );",
            "vec4 normalTexel = texture2D( tDiffuse2, vUv );",
            "vec4 depthTexel = texture2D( tDiffuse3, vUv );",
            "gl_FragColor = colorTexel;",
            "if( normalTexel.r >= normalThreshold || depthTexel.r >=depthThreshold) {",
            "gl_FragColor= colorTexel*(1.0-strengh) + vec4(color[0], color[1], color[2],1);",
            "}",
            
        "}"

    ].join("\n")

};