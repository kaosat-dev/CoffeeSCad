define (require)->

  class DragAndDropRecieverMixin
    constructor:->
    
    handleDragEnter:(e)->
      # this / e.target is the current hover target.
      #this.classList.add('over');

    handleDragLeave:(e)->
      #this.classList.remove('over');  # this / e.target is previous target element.
    
    handleDrop:(e)->
      # this / e.target is current target element.
      if (e.stopPropagation)
        e.stopPropagation()
      e.preventDefault()
      
      files = e.dataTransfer.files
      for file in files
        console.log "dropped file", file
      
      # See the section on the DataTransfer object.
      return false


    handleDragEnd:(e)->
      # this/e.target is the source node.
      #[].forEach.call(cols, (col)
      #  col.classList.remove('over');
      #);
    
    #All this works, but needs refactoring
    ###
    events:
    'dragover': 'onDragOver'
      'dragenter': 'onDragEnter'
      'dragexit' :'onDragExit'
      'drop':'onDrop'
    ui:
      dropOverlay: "#dropOverlay"
    
    onDragOver:(e)=>
      e.preventDefault()
      e.stopPropagation()
      #console.log "event", e
      #console.log "e.dataTransfer",e.dataTransfer
      #offset = e.dataTransfer.getData("text/plain").split(',');
      dm = @ui.dropOverlay[0]
      #console.log "dm", dm
      dm.style.left = (e.clientX + e.offsetX) + 'px'
      dm.style.top = (e.clientY + e.offsetY) + 'px'
      
      dm.style.left =e.originalEvent.clientX+'px'
      dm.style.top = e.originalEvent.clientY+'px'
      
    onDragEnter:(e)->
      @ui.dropOverlay.removeClass("hide")
    
    onDragExit:(e)=>
      @ui.dropOverlay.addClass("hide")
      
    onDrop:(e)->
      # this / e.target is current target element.
      if (e.stopPropagation)
        e.stopPropagation()
      e.preventDefault()
      
      @ui.dropOverlay.addClass("hide")
      
      files = e.originalEvent.dataTransfer.files
      for file in files
        console.log "dropped file", file
        
        do(file)=>
          name = file.name
          ext = name.split(".").pop()
          if ext == "coffee"
            
            reader = new FileReader()
            reader.onload=(e) =>
              fileContent = e.target.result
              console.log "fileContent",fileContent
            reader.readAsText(file)
           
            #reader.onload = ((fileHandler)->
      # See the section on the DataTransfer object.
      return false
    ###
  return DragAndDropRecieverMixin
