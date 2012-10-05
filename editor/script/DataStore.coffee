
class OpenCoffeeScad.DataStore
  constructor: ()->
    @webStoreCap = false
    @detect_capabilities()
  
  detect_capabilities:()->
    if localStorage?
      console.log("Brower localstorage support ok")
      @webStoreCap = true
    else
      console.log("Your browser does not support HTML5 localStorage. Try upgrading.")

  save_inBrowser: (fileName=null, data=null) ->
    if @webStoreCap
      try 
        if fileName? and data?
          localStorage.setItem(fileName, data)
          @addToSaves_inBrowser(fileName)

      catch e
        console.log("Error: #{e}")
        if e == QUOTA_EXCEEDED_ERR 
          console.log("Quota exceeded!") #data wasn't successfully saved due to quota exceed so throw an error
    else
      console.log("Unable to save , browser has no localstorage support")

  load_fromBrower:(fileName=null) ->
    try
      data = ""
      if fileName?
        data = localStorage.getItem(fileName)
      return data
      console.log(data)
    catch e
      console.log("Unable to load data, sorry")
      
  listSaves_fromBrowser:()->
    try
      data = localStorage.getItem("files")
      if data?
        data = data.split(" ")
      else
        data = []
      console.log("Retrieved saves: #{data}")
      return data
      
    catch e
      console.log("Unable to load files list, sorry")
      
   addToSaves_inBrowser:(filename)->
     saves = localStorage.getItem("files")
     if not saves?
       saves= []
     else
      saves = saves.split(" ")
     console.log("present saves: #{saves}, adding file #{filename}")
     #filename= "MyProject"
     if filename in saves
        console.log("NOT adding")
     else
        saves.push(filename)
     saves = saves.join(" ")
     console.log("saving files: #{saves}")
     localStorage.setItem("files", saves)
    
  delete_fromBrowser:(fileName=null)->
    if fileName?
      localStorage.removeItem(fileName)
