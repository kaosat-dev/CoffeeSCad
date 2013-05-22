define (require)->
  
  class FSBase
    constructor:->
      
    mkdir:(path)->
      #make directory(ies) : if a full path, generates all the intermediate directories if
      #they don't exist
      throw new Error("Not implemented")
    
    readdir:(path)->
      #list contents of directory
      throw new Error("Not implemented")
    
    rmdir:(path)->
      #delete directory
      throw new Error("Not implemented")
      
    writefile:(path, content, options)->
      #write content to file in path
      throw new Error("Not implemented")
    
    readfile:(path)->
      #read file given by path
      throw new Error("Not implemented")
    
    rmfile:(path)->
      #delete file specified by path
      throw new Error("Not implemented")
    
    #
    mv:(src, dst)->
      #move file or folder from src to dst
      throw new Error("Not implemented")

    #    
    stat:(path)->
      #get stats for file in path
      throw new Error("Not implemented")
      
    exists:(path)->
      #returns true if path exists , false otherwise
      throw new Error("Not implemented")
    
    watch:(path)->
      #start watch a file or directory
      throw new Error("Not implemented")
    
    unwatch:(path)->
      #stop watching a file or directory 
      throw new Error("Not implemented")

  return FSBase