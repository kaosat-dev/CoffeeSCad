
class OpenCoffeeScad.DataStoreManager
  constructor: (@debug=false)->
    @LocalStore = new OpenCoffeeScad.LocalStore()
    @fsStore = new OpenCoffeeScad.FsStore()
    @gistStore = new OpenCoffeeScad.GistStore()
    @stores = {"local":@LocalStore, "fs":@fsStore, "gist":@gistStore}
    
    store.detect_capabilities() for store in @stores
  
  save_file: (store="local", fileName=null, data=null)->
    if fileName? and data?
      @stores[store].save_file(fileName, data)
  
  load_file:(store="local", fileName=null)->
    if fileName?
      @stores[store].load_file(fileName)
  
  get_files:(store="local")->
    @stores[store].get_files()

  delete_file:(store="local", fileName=null)->
    if fileName?
      @stores[store].delete_file(fileName)
      

class OpenCoffeeScad.DataStore
  constructor: (@debug=false)->
    @available=false
  save_file:(fileName=null, data=null)->
    throw "Save_file NotImplemented"
  load_file:(fileName=null)->
    throw "load_file NotImplemented"
  get_files:()->
    throw "get_files NotImplemented"
  delete_file:()->
    throw "delete_file NotImplemented"    
  clear_files:()->
    throw "clear_files NotImplemented"
 
  get_projects:()->
    throw "NotImplemented"


class OpenCoffeeScad.LocalStore extends OpenCoffeeScad.DataStore
  constructor: (debug=false)->
    super(debug)
  
  detect_capabilities:()->
    if window.localStorage?
        console.log("Brower localstorage support ok")
        @available = true
      else
        console.log("Your browser does not support HTML5 localStorage. Try upgrading.")
    
  save_file:(fileName=null, data=null)->
    if @debug
      console.log("saving to local storage")
    if @available
      try 
        localStorage.setItem(fileName, data)
        @_addToSaves(fileName)
      catch e
        console.log("Error: #{e}")
        if e == QUOTA_EXCEEDED_ERR 
          console.log("Quota exceeded!") #data wasn't successfully saved due to quota exceed so throw an error
    else
      console.log("Unable to save , browser has no localstorage support")
    
    
  load_file:(fileName=null) ->
    try
      data = ""
      data = localStorage.getItem(fileName)
      return data
    catch e
      console.log("Unable to load data, sorry")
      
  get_files:()->
    try
      data = localStorage.getItem("files")
      if data?
        data = data.split(" ")
      else
        data = []
      if @debug
        console.log("Retrieved saves: #{data}")
      return data
    catch e
      console.log("Unable to load files list, sorry")
  
  delete_file:(fileName)->
    localStorage.removeItem(fileName)
    
  clear_files:()->
    window.localStorage.clear()
 
  _addToSaves:(filename)->
     saves = localStorage.getItem("files")
     if not saves?
       saves= []
     else
      saves = saves.split(" ")
     if not filename in saves
        saves.push(filename)
     saves = saves.join(" ")
     if @debug
       console.log("saving files: #{saves}")
     localStorage.setItem("files", saves)


class OpenCoffeeScad.FsStore extends OpenCoffeeScad.DataStore
  constructor: (debug=false)->
    super(debug)
    
  detect_capabilities:()->  
    window.requestFileSystem  = window.requestFileSystem || window.webkitRequestFileSystem
    if window.requestFileSystem?
      @available=true
    else
      console.log("Your browser does not support the HTML5 FileSystem API. Please try the Chrome browser instead.")

      
  save_file:(fileName=null, data=null)->
    if @debug
      console.log("saving to fs")
    ###    
    generateOutputFileFileSystem:() ->
      # create a random directory name:
      dirname = "OpenJsCadOutput1_"+ parseInt(Math.random()*1000000000, 10)+"."+extension
      extension = @extensionForCurrentObject()
      filename = @filename+"."+extension
  
      window.requestFileSystem(TEMPORARY, 20*1024*1024, (fs)->
          fs.root.getDirectory(dirname, {create: true, exclusive: true}, (dirEntry) ->
              @outputFileDirEntry = dirEntry
              dirEntry.getFile(filename, {create: true, exclusive: true}, (fileEntry)->
                   fileEntry.createWriter((fileWriter)->
                      fileWriter.onwriteend = (e)->
                        @hasOutputFile = true
                        @downloadOutputFileLink.href = fileEntry.toURL()
                        @downloadOutputFileLink.type = @mimeTypeForCurrentObject()
                        @downloadOutputFileLink.innerHTML = @downloadLinkTextForCurrentObject()
                        @enableItems()
                        if(@onchange) @onchange()
  
                      fileWriter.onerror = (e)-> 
                        throw new Error('Write failed: ' + e.toString())
  
                      blob = @currentObjectToBlob()
                      fileWriter.write(blob)      
  
                    (fileerror) -> 
                      OpenJsCad.FileSystemApiErrorHandler(fileerror, "createWriter")
               (fileerror) -> 
                  OpenJsCad.FileSystemApiErrorHandler(fileerror, "getFile('"+filename+"')")
            (fileerror) -> 
              OpenJsCad.FileSystemApiErrorHandler(fileerror, "getDirectory('"+dirname+"')") 
        (fileerror)->
          OpenJsCad.FileSystemApiErrorHandler(fileerror, "requestFileSystem")
     ###   
    
  load_file:(fileName=null)->
    
  get_files:()->
    
  delete_file:()->
    
  clear_files:()->
    
  _onInitFs:(fs) ->  
     console.log("Opened file system: #{fs.name}")

   
class OpenCoffeeScad.GistStore extends OpenCoffeeScad.DataStore
  constructor: (debug=false)->
    super(debug)
    @currentUser= "kaosat-dev"
    
  detect_capabilities:()->
    @available=true
    
  save_file:(fileName=null, data=null)->
    if @debug
      console.log("saving to gist repo")
    
  load_file:(fileName=null)->
    GistsOfK33g = new Gh3.Gists(new Gh3.User("kaosat-dev"))

    oneGist = new Gh3.Gist({id:"3842893"})
    
    oneGist.fetchContents( (err, res)->
      if err
        console.log("error #{err} fetching gist")
        #throw Error
      console.log("oneGist : ", oneGist)
      console.log("Files : ", oneGist.files)
      
      myFile = oneGist.getFileByName("file2.coffee")
      console.log("myFile: #{myFile}")
      console.log(myFile.content)
      console.log("Gist files: #{oneGist.files}")
      )

      #oneGist.eachFile(function (file) {
            #console.log(file.filename, file.language, file.type, file.size);
      #console.log(oneGist.getFileByName("use.thing.js").content);
    
  get_files:()->
  delete_file:()->
  clear_files:()->
    
  get_projects:(userName=null)->
    if userName?
      gists = new Gh3.Gists(new Gh3.User(userName))

