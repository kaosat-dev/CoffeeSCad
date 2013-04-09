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

  return DragAndDropRecieverMixin
