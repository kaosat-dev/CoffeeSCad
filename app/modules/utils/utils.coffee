define (require) ->

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

  return {"getBlobBuilder":getBlobBuilder ,"getWindowURL":getWindowURL,"textToBlobUrl":textToBlobUrl,"revokeBlobUrl":revokeBlobUrl}
