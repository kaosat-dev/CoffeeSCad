define (require) ->
  csg = require 'csg'
  
  getBlobBuilder = ()-> 
    bb
    if(window.BlobBuilder) then bb = new window.BlobBuilder()
    else if(window.WebKitBlobBuilder) then bb = new window.WebKitBlobBuilder()
    else if(window.MozBlobBuilder)then bb = new window.MozBlobBuilder()
    else throw new Error("Your browser doesn't support BlobBuilder")
    return bb

  getWindowURL = ()->
    if window.URL then return window.URL
    else if window.webkitURL then return window.webkitURL
    else throw new Error("Your browser doesn't support window.URL")

  textToBlobUrl = (txt)-> 
    bb=getBlobBuilder()
    windowURL=getWindowURL()
    bb.append(txt)
    blob = bb.getBlob()
    blobURL = windowURL.createObjectURL(blob)
    if !blobURL 
      throw new Error("createObjectURL() failed") 
    return blobURL

  revokeBlobUrl = (url)->
    if(window.URL) then window.URL.revokeObjectURL(url)
    else if(window.webkitURL)  then window.webkitURL.revokeObjectURL(url)
    else throw new Error("Your browser doesn't support window.URL")

  ################################
  
  getBlob:()=>
    window.URL = window.URL or window.webkitURL
    blob = new Blob(['body { color: red }'], {type: 'text/css'})
    link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = window.URL.createObjectURL(blob)
    document.body.appendChild(link)

  revokeBlobUrl:()=>
    
  class CsgStlExporterMin
    ##A: make blob with data
    ##B: write blob + download link
    
    constructor:(csgObject)->
      console.log csgObject
      @csgObject=csgObject
      app = require 'app'
      #dataView = new DataView(arrayBuffer)
      #blob = new Blob([dataView], { type: mimeString });
      #@csgObject.fixTJunctions().toStlBinary(bb)
    
    export_o:()->
      try
        bb=getBlobBuilder()
        @mimeType = "application/sla"
        @csgObject.fixTJunctions().toStlBinary(bb)
        blob = bb.getBlob(@mimeType)
        console.log blob
      catch error
        console.log "Failed to generate stl blob data: #{error}"
        
      windowURL=getWindowURL()
      @outputFileBlobUrl = windowURL.createObjectURL(blob)
      if not @outputFileBlobUrl then throw new Error("createObjectURL() failed") 
      return @outputFileBlobUrl      
      
    export:()=> 
      try
        bb=getBlobBuilder()
        @mimeType = "application/sla"
        @currentObject = @csgObject.fixTJunctions()
        @raw2(bb)
        console.log "data"
        console.log bb
        blob = bb.getBlob(@mimeType)
        console.log blob
      catch error
        console.log "Failed to generate stl blob data: #{error}"
        
      windowURL=getWindowURL()
      @outputFileBlobUrl = windowURL.createObjectURL(blob)
      if not @outputFileBlobUrl then throw new Error("createObjectURL() failed") 
      return @outputFileBlobUrl      
      
    
    raw2:(blobbuilder)->
      
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
        
      console.log ("Total num tris"+numtriangles)
      
      headerarray = new Uint8Array(80)
      for i in [0...80]
        headerarray[i] = 65
        
      blobbuilder.append(headerarray.buffer)
      ar1 = new Uint32Array(1)
      ar1[0] = numtriangles
      
      blobbuilder.append(ar1.buffer)
      
      buffer = new ArrayBuffer(50)
      byteoffset=0
      @currentObject.polygons.map (p) -> 
        numvertices = p.vertices.length
        for i in [0...numvertices-2]
          float32array = new Float32Array(buffer, 0, 12) 
          normal = p.plane.normal
          float32array[0] = normal._x
          float32array[1] = normal._y
          float32array[2] = normal._z
          arindex = 3
          #console.log("__")
          for v in [0...3]
            #vv = v + (if v>0 then i else 0)#vv=v + ((v > 0)? i:0)
            vv = v + ((if (v > 0) then i else 0))
            #console.log "toto "+ vv
            vertexpos = p.vertices[vv].pos
            float32array[arindex++] = vertexpos._x
            float32array[arindex++] = vertexpos._y
            float32array[arindex++] = vertexpos._z
          uint16array = new Uint16Array(buffer, 48, 1)
          uint16array[0]=0
          
          blobbuilder.append(buffer)
      
    
    export_n1:()=>
      @currentObject = null
      @mimeType = "application/sla"
      
      try
        @currentObject = @csgObject.fixTJunctions()
        data = @raw()
        blob = new Blob(data, {type: @mimeType})
        console.log "stl blob:"
        console.log blob
        console.log "data"
        console.log data
      catch error
        console.log "Failed to generate stl blob data: #{error}"
      
      windowURL=getWindowURL()
      @outputFileBlobUrl = windowURL.createObjectURL(blob)
      if not @outputFileBlobUrl then throw new Error("createObjectURL() failed") 
      return @outputFileBlobUrl   
    
    
    raw:()->
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
        
      console.log ("Total num tris"+numtriangles)
      
      headerarray = new Uint8Array(80)
      for i in [0...80]
        headerarray[i] = 65
        
      #blobbuilder.append(headerarray.buffer)
      blobData.push(headerarray.buffer)
      ar1 = new Uint32Array(1)
      ar1[0] = numtriangles
      
      #blobbuilder.append(ar1.buffer)
      blobData.push(ar1.buffer)
      
      buffer = new ArrayBuffer(50)
      byteoffset=0
      @currentObject.polygons.map (p) -> 
        numvertices = p.vertices.length
        for i in [0...numvertices-2]
          float32array = new Float32Array(buffer, 0, 12) 
          normal = p.plane.normal
          float32array[0] = normal._x
          float32array[1] = normal._y
          float32array[2] = normal._z
          arindex = 3
          #console.log("__")
          for v in [0...3]
            #vv = v + (if v>0 then i else 0)#vv=v + ((v > 0)? i:0)
            vv = v + ((if (v > 0) then i else 0))
            #console.log "toto "+ vv
            vertexpos = p.vertices[vv].pos
            float32array[arindex++] = vertexpos._x
            float32array[arindex++] = vertexpos._y
            float32array[arindex++] = vertexpos._z
          uint16array = new Uint16Array(buffer, 48, 1)
          uint16array[0]=0
          
          #blobbuilder.append(buffer)
          blobData.push(buffer)
      console.log "BLOB data"
      console.log blobData
      return blobData
      
  return CsgStlExporterMin
  ###############################

  class CsgStlExporter
    constructor:()->
      @hasOutputFile
      
    clearOutputFile:()->
      if @hasOutputFile
        @hasOutputFile false
      if @outputFileDirEntry
        @outputFileDirEntry.removeRecursively(()->{})
        @outputFileDirEntry=null
      if @outputFileBlobUrl
        revokeBlobUrl(@outputFileBlobUrl)
        @outputFileBlobUrl = null
      @enableItems()

    generateOutputFile: ()-> 
      @clearOutputFile()
      if(@hasValidCurrentObject)
        try
          @generateOutputFileFileSystem()
        catch e
          @generateOutputFileBlobUrl()

    currentObjectToBlob: ()-> 
      bb=getBlobBuilder()
      mimetype = @mimeTypeForCurrentObject()
      if@currentObject instanceof CSG
        @currentObject.fixTJunctions().toStlBinary(bb)
        mimetype = "application/sla"
      else if @currentObject instanceof CAG
        @currentObject.toDxf(bb)
        mimetype = "application/dxf"
      else
        throw new Error("Not supported")
      blob = bb.getBlob(mimetype)
      return blob

  
    mimeTypeForCurrentObject: ()-> 
      ext = @extensionForCurrentObject()
      #return {
      #  stl: "application/sla",
      #  dxf: "application/dxf",
      #}[ext]
  
    extensionForCurrentObject: ()-> 
      if(@currentObject instanceof CSG)
        extension = "stl"
      else if(@currentObject instanceof CAG)
        extension = "dxf"
      else
        throw new Error("Not supported")
      return extension    
  
    downloadLinkTextForCurrentObject: ()-> 
      ext = @extensionForCurrentObject()
      return "Download "+ext.toUpperCase()
  
    generateOutputFileBlobUrl: ()-> 
      blob = @currentObjectToBlob()
      windowURL=getWindowURL()
      @outputFileBlobUrl = windowURL.createObjectURL(blob)
      if !@outputFileBlobUrl then throw new Error("createObjectURL() failed") 
      @hasOutputFile = true
      @downloadOutputFileLink.href = @outputFileBlobUrl
      @downloadOutputFileLink.innerHTML = @downloadLinkTextForCurrentObject()
      @enableItems()
   
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
  