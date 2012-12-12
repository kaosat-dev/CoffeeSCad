define (require) ->
  csg = require 'csg'
  utils = require "modules/utils"
  
  class CsgStlExporterMin
    #exports the given csg tree to the stl file format (binary only for now)
    
    constructor:(csgObject)->
      @csgObject=csgObject
      @mimeType = "application/sla"
      app = require 'app'
    
    export:()=>
      @currentObject = null
      try
        @currentObject = @csgObject.fixTJunctions()
        data = @_generateBinary()
        blob = new Blob(data, {type: @mimeType})
      catch error
        console.log "Failed to generate stl blob data: #{error}"
      
      windowURL=utils.getWindowURL()
      @outputFileBlobUrl = windowURL.createObjectURL(blob)
      if not @outputFileBlobUrl then throw new Error("createObjectURL() failed") 
      return @outputFileBlobUrl   
    
    _generateBinary:()->
      blobData = []
      
      buffer = new ArrayBuffer(4)
      int32buffer = new Int32Array(buffer, 0, 1)
      int8buffer = new Int8Array(buffer, 0, 4)
      int32buffer[0] = 0x11223344
      if int8buffer[0] != 0x44
        throw new Error("Binary STL output is currently only supported on little-endian (Intel) processors")
        
      numtriangles=0
      @currentObject.polygons.map (p) ->
        numvertices = p.vertices.length
        thisnumtriangles = if numvertices >= 3 then numvertices-2 else 0 
        numtriangles += thisnumtriangles 
        
      headerarray = new Uint8Array(80)
      for i in [0...80]
        headerarray[i] = 65
      blobData.push(headerarray)
      
      ar1 = new Uint32Array(1)
      ar1[0] = numtriangles
      blobData.push(ar1)
      
      for index, polygon of @currentObject.polygons
        numvertices = polygon.vertices.length
        for i in [0...numvertices-2]
          vertexDataArray = new Float32Array(12) 
          normal = polygon.plane.normal
          vertexDataArray[0] = normal._x
          vertexDataArray[1] = normal._y
          vertexDataArray[2] = normal._z
          
          arindex = 3
          for v in [0...3]
            vv = v + ((if (v > 0) then i else 0))
            pos    = polygon.vertices[vv].pos
            vertexDataArray[arindex++] = pos._x
            vertexDataArray[arindex++] = pos._y
            vertexDataArray[arindex++] = pos._z
          
          attribDataArray = new Uint16Array(1)
          attribDataArray[0]=0
            
          blobData.push(vertexDataArray)
          blobData.push(attribDataArray)
          
      return blobData
      
  return CsgStlExporterMin
  ###############################
  ###
  generateOutputFileFileSystem: ()-> 
    
    window.requestFileSystem  = window.requestFileSystem || window.webkitRequestFileSystem
    if(!window.requestFileSystem)
    {
      throw new Error("Your browser does not support the HTML5 FileSystem API. Please try the Chrome browser instead.")
    }
    // create a random directory name:
    dirname = "OpenJsCadOutput1_"+parseInt(Math.random()*1000000000, 10)+"."+extension
    extension = @extensionForCurrentObject()
    filename = @filename+"."+extension
    that = this
    window.requestFileSystem(TEMPORARY, 20*1024*1024, function(fs){
        fs.root.getDirectory(dirname, {create: true, exclusive: true}, function(dirEntry) {
            that.outputFileDirEntry = dirEntry
            dirEntry.getFile(filename, {create: true, exclusive: true}, function(fileEntry) {
                 fileEntry.createWriter(function(fileWriter) {
                    fileWriter.onwriteend = function(e) {
                      that.hasOutputFile = true
                      that.downloadOutputFileLink.href = fileEntry.toURL()
                      that.downloadOutputFileLink.type = that.mimeTypeForCurrentObject() 
                      that.downloadOutputFileLink.innerHTML = that.downloadLinkTextForCurrentObject()
                      that.enableItems()
                      if(that.onchange) that.onchange()
                    }
                    fileWriter.onerror = function(e) {
                      throw new Error('Write failed: ' + e.toString())
                    }
                    blob = that.currentObjectToBlob()
                    fileWriter.write(blob)                
                  }, 
                  function(fileerror){OpenJsCad.FileSystemApiErrorHandler(fileerror, "createWriter")} 
                )
              },
              function(fileerror){OpenJsCad.FileSystemApiErrorHandler(fileerror, "getFile('"+filename+"')")} 
            )
          },
          function(fileerror){OpenJsCad.FileSystemApiErrorHandler(fileerror, "getDirectory('"+dirname+"')")} 
        )         
      }, 
      function(fileerror){OpenJsCad.FileSystemApiErrorHandler(fileerror, "requestFileSystem")}
    )
  ###
  