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
    window.URL = window.URL or window.webkitURL;
    blob = new Blob(['body { color: red; }'], {type: 'text/css'});
    link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = window.URL.createObjectURL(blob);
    document.body.appendChild(link);

  revokeBlobUrl:()=>
    
  class CsgStlExporterMin
    ##A: make blob with data
    ##B: write blob + download link
    
    constructor:(currentobj)->
      @currentObject=currentobj
      app = require 'app'
      
      #@app.vent.bind("undoRequest", @undo)
      
    
    step1:()->
      @currentObject = null
      @mimeType = "application/sla"
      
      @data = @currentObject.fixTJunctions().toStlBinary(bb)
      
      blob = new Blob([@data], {type: @mimeType});
      return blob
    
    step2:()->
      blob = @step1()
      windowURL=getWindowURL()
      @outputFileBlobUrl = windowURL.createObjectURL(blob)
      if !@outputFileBlobUrl then throw new Error("createObjectURL() failed") 
      @hasOutputFile = true
      @downloadOutputFileLink.href = @outputFileBlobUrl
      @downloadOutputFileLink.innerHTML = "Download "+"stl".toUpperCase()
    
    process:()->
      
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
  