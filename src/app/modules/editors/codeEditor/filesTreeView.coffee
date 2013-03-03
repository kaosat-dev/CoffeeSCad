define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  marionette = require 'marionette'
  
  jquery_layout = require 'jquery_layout'
  jquery_ui = require 'jquery_ui'
  
  vent = require 'modules/core/vent'
  
  filesTreeTemplate =  require "text!./filesTreeView.tmpl"
  
  fileTemplate = _.template($(filesTreeTemplate).filter('#fileTmpl').html())
  projectTemplate = _.template($(filesTreeTemplate).filter('#projectTmpl').html())
  rootTemplate = _.template($(filesTreeTemplate).filter('#rootTmpl').html())
  
  class FileView extends Backbone.Marionette.ItemView
    template: fileTemplate
    tagName: "tr"
    ui:
      fileNameColumn:"#fileNameColumn"
      editFileColumn:"#editFileColumn"
      
    events:
      "click .editFile": "onEditFileClicked"
      "click .deleteFile": "onDeleteFileClicked"
      'dblclick .openFile' : "onFileOpenClicked"
    
    constructor:(options)->
      super options
    
    onEditFileClicked:=>
      selector = @ui.fileNameColumn
      _onFileNameEdited= =>
        selector.attr('contentEditable',false)
        selector.removeClass("fileListEditable")
        @ui.editFileColumn.show()
        
        nameWithExt = @ui.fileNameColumn.find('.openFile').text()
        nameWithExt = nameWithExt.split('.')
        name = nameWithExt[0].replace(/^\s+|\s+$/g, '')
        ext = nameWithExt[1].replace(/^\s+|\s+$/g, '')
        @trigger("file:rename",{model:@model,newName:name, newExt:ext})
      
      if selector.attr('contentEditable') is "true"
        _onFileNameEdited()
      else
        selector.attr('contentEditable',true)
        selector.children("a").css('cursor': 'text')
        selector.addClass("fileListEditable")
        @ui.editFileColumn.hide()
        @ui.fileNameColumn.attr("collspan",3)
        selector.focus()
        
        selector.focusout =>
          _onFileNameEdited()
        
     onFileOpenClicked:(ev)=>
      vent.trigger("file:OpenRequest",@model)
     
     onDeleteFileClicked:(ev)=>
       @trigger("file:delete",@model)
    
  class TreeView extends Backbone.Marionette.CompositeView
    itemView: FileView
    template: projectTemplate
    
    itemViewContainer: "tbody"
    #className : "table"
      
    ui:
      newFileColumn: "#newFileColumn"
      newFileInput: "#newFileInput"
    
    events:
      'dblclick .openFile' : "onFileOpenClicked"
      'click .addFile'     : "onFileAddClicked"
    
    constructor:(options)->
      super options
      #@collection = @model.nodes
      console.log "@model"
      console.log @model
      console.log "@collection"
      console.log @collection
      @on("itemview:file:delete", @onFileDeleteRequest)
      @on("itemview:file:rename", @onFileRenameRequest)
    
    onFileOpenClicked:(ev)=>
      console.log @model.get("name")
      vent.trigger("file:OpenRequest",@model)
    
    onFileAddClicked:(ev)=>
      nameWithExt = @ui.newFileInput.val()
      #TODO: correct validation
      nameWithExt = nameWithExt.split('.')
      console.log "nameWithExt: #{nameWithExt}"
      ext = ""
      if nameWithExt.length > 1
        name = nameWithExt[0].replace(/^\s+|\s+$/g, '')
        ext = nameWithExt[1].replace(/^\s+|\s+$/g, '')
      else
        name =  nameWithExt[0]
      
      found = @collection.find (file)=>
        return file.get('name') == name and file.get('ext') == ext
      
      if found
        console.log "#{name}.#{ext} already exists"
        @ui.newFileColumn.addClass("error")
        @ui.newFileColumn.popover
          placement:"top"
          content:"#{name}.#{ext} already exists"
          template:'<div class="popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title" style="display: none"></h3><div class="popover-content"><p></p></div></div></div>'
        @ui.newFileColumn.popover("show")
      else 
        @model.createFile
          name:name
          ext:ext
        @ui.newFileInput.val("")
        @ui.newFileColumn.removeClass("error")
        @ui.newFileColumn.popover("destroy")
        
     onFileDeleteRequest:(childView, projectFile)=>
       #TODO: better validation needed
       #NO deletion of main file possible
       fileName = projectFile.get("name") 
       if fileName is @model.get("name")
         bootbox.animate(false)
         bootbox.alert("you cannot delete the main file in a project")
         ###bootbox.alert
          str:"you cannot delete the main file in a project"
          backdrop: false###
       else
        bootbox.animate(false)
        bootbox.dialog "Are you sure you want to delete this file?", [
          label: "Ok"
          class: "btn-inverse"
          callback: =>
            @collection.remove(projectFile)
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
       
        #@model.remove(fileName)
        
      onFileRenameRequest:(childView,msg)=>
        model= msg.model
        name = msg.newName
        ext = msg.newExt
        
        found = @collection.find (file)=>
          return file.get('name') == name and file.get('ext') == ext
        
        selector = childView.$el
        if found
          console.log "#{name}.#{ext} already exists"
          selector.addClass("error")
          selector.popover
            placement:"right"
            content:"#{name}.#{ext} already exists"
            template:'<div class="popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title" style="display: none"></h3><div class="popover-content"><p></p></div></div></div>'
          selector.popover("show")
          #selector.find('.openFile').text("""#{model.get("name")}.#{model.get("ext")}""")
          selector.find('.openFile').html("""<i class="icon-file"></i> #{model.get("name")}.#{model.get("ext")}</a>""")
          
          setTimeout (=> selector.popover('destroy')), 2000
          
        else 
          model.set("name",name)
          model.set("ext",ext)
          selector.popover("destroy")
        
           
    
  class TreeRoot extends Backbone.Marionette.CompositeView
    template: rootTemplate
    itemView: FileView
    tagName: "table"
    className: "filesTree"
    
    constructor:(options)->
      super options
    
    onRender:->
      @$el.addClass("align-left")
  
  return TreeView
