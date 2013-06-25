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
        "tDiffuse3": { type: "t", value: null }
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

        "varying vec2 vUv;",

        "void main() {",

            "vec4 colorTexel = texture2D( tDiffuse1, vUv );",
            "vec4 normalTexel = texture2D( tDiffuse2, vUv );",
            "vec4 depthTexel = texture2D( tDiffuse3, vUv );",
            "gl_FragColor = colorTexel;",
            "if( normalTexel.r >= 0.05 || depthTexel.r >=0.05) {",
            "gl_FragColor= colorTexel*0.8 + vec4(0,0,0,1);",
            "}",
        "}"

    ].join("\n")

};