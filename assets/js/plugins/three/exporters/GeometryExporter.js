/**
 * @author mrdoob / http://mrdoob.com/
 */

THREE.GeometryExporter = function () {};

THREE.GeometryExporter.prototype = {

	constructor: THREE.GeometryExporter,

	parse: function ( geometry ) {

		var output = {
			metadata: {
				version: 4.0,
				type: 'geometry',
				generator: 'GeometryExporter'
			}
		};

		var vertices = [];

		for ( var i = 0; i < geometry.vertices.length; i ++ ) {

			var vertex = geometry.vertices[ i ];
			vertices.push( vertex.x, vertex.y, vertex.z );

		}

		var faces = [];
		var uvs = [[]];
		var normals = [];
		var normalsHash = {};
		var colors = [];
		var colorsHash = {};
		

		for ( var i = 0; i < geometry.faces.length; i ++ ) {

			var face = geometry.faces[ i ];

			var isTriangle = face instanceof THREE.Face3;
			var hasMaterial = false; // face.materialIndex !== undefined;
			var hasFaceUv = false; // geometry.faceUvs[ 0 ][ i ] !== undefined;
			var hasFaceVertexUv = false; // geometry.faceVertexUvs[ 0 ][ i ] !== undefined;
			var hasFaceNormal = face.normal.length() > 0;
			var hasFaceVertexNormal = face.vertexNormals[ 0 ] !== undefined;
			var hasFaceColor = false; // face.color;
			var hasFaceVertexColor = face.vertexColors[ 0 ] !== undefined;

			var faceType = 0;

			faceType = setBit( faceType, 0, ! isTriangle );
			faceType = setBit( faceType, 1, hasMaterial );
			faceType = setBit( faceType, 2, hasFaceUv );
			faceType = setBit( faceType, 3, hasFaceVertexUv );
			faceType = setBit( faceType, 4, hasFaceNormal );
			faceType = setBit( faceType, 5, hasFaceVertexNormal );
			faceType = setBit( faceType, 6, hasFaceColor );
			faceType = setBit( faceType, 7, hasFaceVertexColor );

			faces.push( faceType );

			if ( isTriangle ) {

				faces.push( face.a, face.b, face.c );

			} else {

				faces.push( face.a, face.b, face.c, face.d );

			}

			if ( hasMaterial ) {

				faces.push( face.materialIndex );

			}

			/*
			if ( hasFaceUv ) {

				var uv = geometry.faceUvs[ 0 ][ i ];
				uvs[ 0 ].push( uv.u, uv.v );

			}
			*/

			/*
			if ( hasFaceVertexUv ) {

				var uvs = geometry.faceVertexUvs[ 0 ][ i ];

				if ( isTriangle ) {

					faces.push(
						uvs[ 0 ].u, uvs[ 0 ].v,
						uvs[ 1 ].u, uvs[ 1 ].v,
						uvs[ 2 ].u, uvs[ 2 ].v
					);

				} else {

					faces.push(
						uvs[ 0 ].u, uvs[ 0 ].v,
						uvs[ 1 ].u, uvs[ 1 ].v,
						uvs[ 2 ].u, uvs[ 2 ].v,
						uvs[ 3 ].u, uvs[ 3 ].v
					);

				}

			}
			*/

			if ( hasFaceNormal ) {

				var faceNormal = face.normal;
				faces.push( getNormalIndex( faceNormal.x, faceNormal.y, faceNormal.z ) );

			}

			if ( hasFaceVertexNormal ) {

				var vertexNormals = face.vertexNormals;

				if ( isTriangle ) {

					faces.push(
						getNormalIndex( vertexNormals[ 0 ].x, vertexNormals[ 0 ].y, vertexNormals[ 0 ].z ),
						getNormalIndex( vertexNormals[ 1 ].x, vertexNormals[ 1 ].y, vertexNormals[ 1 ].z ),
						getNormalIndex( vertexNormals[ 2 ].x, vertexNormals[ 2 ].y, vertexNormals[ 2 ].z )
					);

				} else {

					faces.push(
						getNormalIndex( vertexNormals[ 0 ].x, vertexNormals[ 0 ].y, vertexNormals[ 0 ].z ),
						getNormalIndex( vertexNormals[ 1 ].x, vertexNormals[ 1 ].y, vertexNormals[ 1 ].z ),
						getNormalIndex( vertexNormals[ 2 ].x, vertexNormals[ 2 ].y, vertexNormals[ 2 ].z ),
						getNormalIndex( vertexNormals[ 3 ].x, vertexNormals[ 3 ].y, vertexNormals[ 3 ].z )
					);

				}

			}
			if ( hasFaceVertexColor ) {
			    var vertexColors = face.vertexColors;

                if ( isTriangle ) {

                    faces.push(
                        getColorIndex( vertexColors[ 0 ].r, vertexColors[ 0 ].g, vertexColors[ 0 ].b ),
                        getColorIndex( vertexColors[ 1 ].r, vertexColors[ 1 ].g, vertexColors[ 1 ].b ),
                        getColorIndex( vertexColors[ 2 ].r, vertexColors[ 2 ].g, vertexColors[ 2 ].b )
                    );

                } else {

                    faces.push(
                        getColorIndex( vertexColors[ 0 ].r, vertexColors[ 0 ].g, vertexColors[ 0 ].b ),
                        getColorIndex( vertexColors[ 1 ].r, vertexColors[ 1 ].g, vertexColors[ 1 ].b ),
                        getColorIndex( vertexColors[ 2 ].r, vertexColors[ 2 ].g, vertexColors[ 2 ].b ),
                        getColorIndex( vertexColors[ 3 ].r, vertexColors[ 3 ].g, vertexColors[ 3 ].b )
                    );

                }
			    
			}

		}

		function setBit( value, position, enabled ) {

			return enabled ? value | ( 1 << position ) : value & ( ~ ( 1 << position) );

		}

		function getNormalIndex( x, y, z ) {

			var hash = x.toString() + y.toString() + z.toString();

			if ( normalsHash[ hash ] !== undefined ) {

				return normalsHash[ hash ];

			}

			normalsHash[ hash ] = normals.length / 3;
			normals.push( x, y, z );

			return normalsHash[ hash ];

		}
		
		
		function getColorIndex( r, g, b ) {

            var hash = r.toString() + g.toString() + b.toString();

            if ( colorsHash[ hash ] !== undefined ) {
                return colorsHash[ hash ];
            }

            colorsHash[ hash ] = colors.length / 3;
            color = "rgb("+Math.floor(r*255)+","+ Math.floor(g*255)+","+Math.floor(b*255)+")";
            colors.push( color );
            //rgb(255,0,0)

            return colorsHash[ hash ];

        }

		output.vertices = vertices;
		output.normals = normals;
		output.colors = colors;
		output.uvs = uvs;
		output.faces = faces;

		//

		return output;

	}

};