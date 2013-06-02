define (require)->
  
  class FSBase
    constructor:(sep)->
      #params:
      #sep: seperator
      @sep = sep
            
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
    
    join:( paths )->
      #something like path.join()
      if paths[0] == @sep and paths.length == 2
        return paths[0] + paths[1]
      return paths.join( @sep )
    
    split:( path )->
      #split a string based path into a list of path components
      result = path.split( @sep )
      if result[0] == ""
        result[0] = @sep
      return result
    
    getType : ( path ) ->
      result = {name: @basename( path ),
      path : path
      }
      if @isDir( path )
        result.type = 'folder'
      else
        result.type = 'file'
     
      return result
  
  return FSBase