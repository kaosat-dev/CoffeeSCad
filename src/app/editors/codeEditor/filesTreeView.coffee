define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  require 'bootstrap'
  require 'marionette'
  require 'modelbinder'
  require 'pickysitter'
  jquery_layout = require 'jquery_layout'
  
  vent = require 'core/messaging/appVent'
  
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
      'dblclick .openFile' : "onFileSelected"
    
    triggers:
      "click #fileNameColumn": "selected"
    
    constructor:(options)->
      super options
      selectable = new Backbone.PickySitter.Selectable(@)
      _.extend(this, selectable)
      
      @on("selected", ()=>@$el.addClass("info"))
      @on("deselected",()=>@$el.removeClass("info"))
        
      @bindings = 
        name: [{selector: "[name=fileName]"}]
        
      @modelBinder = new Backbone.ModelBinder()
      #FIXME: weird, this hack is needed, because no auto re-render is taking place
      @model.on 'change', ()=>@render()
    
    
    onEditFileClicked:=>
      selector = @ui.fileNameColumn
      _onFileNameEdited= =>
        selector.attr('contentEditable',false)
        selector.removeClass("fileListEditable")
        @ui.editFileColumn.show()
        
        name = @ui.fileNameColumn.find('.openFile').text()
        name = name.replace(/^\s+|\s+$/g, '')
        @trigger("file:rename",{model:@model,newName:name})
        selector.off "focusout",_onFileNameEdited
      
      if selector.attr('contentEditable') is "true"
        _onFileNameEdited()
      else
        selector.attr('contentEditable',true)
        selector.children("a").css('cursor': 'text')
        selector.addClass("fileListEditable")
        @ui.editFileColumn.hide()
        @ui.fileNameColumn.attr("collspan",3)
        selector.focus()
        
        selector.on "focusout",_onFileNameEdited
        
     onFileSelected:(ev)=>
      vent.trigger("file:selected",@model)
     
     onDeleteFileClicked:(ev)=>
       @trigger("file:delete",@model)
     
     onRender:=>
       @modelBinder.bind(@model, @el, @bindings)
    
     onClose:=>
       @modelBinder.unbind()
    
  class TreeView extends Backbone.Marionette.CompositeView
    itemView: FileView
    template: projectTemplate
    
    itemViewContainer: "tbody"
    className : "table table-hover table-condensed"
      
    ui:
      newFileColumn: "#newFileColumn"
      newFileInput: "#newFileInput"
    
    events:
      #'dblclick .openFile' : "onFileOpenClicked"
      'click .addFile'     : "onFileAddClicked"
    
    constructor:(options)->
      super options
      @on("itemview:file:delete", @onFileDeleteRequest)
      @on("itemview:file:rename", @onFileRenameRequest)
      @on("itemview:selected" ,  @onFileViewSelected)
      
      singleSelect = new Backbone.PickySitter.SingleSelect(@itemViewContainer)
      _.extend(this, singleSelect)
      
      #FIXME: weird, this hack is needed, because no auto re-render is taking place
      #@model.on 'change', ()=>@render()
      @modelBinder = new Backbone.ModelBinder()
      @bindings = 
        name: [{selector: "[name=projectName]"}]
        
    onRender:->
      @modelBinder.bind(@model, @el, @bindings)
      
    #onFileOpenClicked:(ev)=>
    #  vent.trigger("file:OpenRequest",@model)
    
    onFileViewSelected:(childView)=>
      @select(childView)
    
    onFileAddClicked:(ev)=>
      name = @ui.newFileInput.val()
      #TODO: correct validation
      name = name.replace(/^\s+|\s+$/g, '')
      
      found = @collection.find (file)=>
        return file.name == name
      
      if found
        console.log "#{name} already exists"
        @ui.newFileColumn.addClass("error")
        @ui.newFileColumn.popover
          placement:"top"
          content:"#{name} already exists"
          template:'<div class="popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title" style="display: none"></h3><div class="popover-content"><p></p></div></div></div>'
        @ui.newFileColumn.popover("show")
      else 
        @model.addFile
          name:name
        @ui.newFileInput.val("")
        @ui.newFileColumn.removeClass("error")
        @ui.newFileColumn.popover("destroy")
        
     onFileDeleteRequest:(childView, projectFile)=>
       #TODO: better validation needed
       #NO deletion of main file possible
       fileName = projectFile.name
         
       if fileName.split('.')[0] is @model.name
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
            #@collection.remove(projectFile)
            projectFile.destroy()
        ,
          label: "Cancel"
          class: "btn-inverse"
          callback: ->
        ]
        
      onFileRenameRequest:(childView,msg)=>
        model= msg.model
        name = msg.newName
        
        found = @collection.find (file)=>
          return file.name == name
        
        selector = childView.$el
        if found
          selector.addClass("error")
          selector.popover
            placement:"right"
            content:"#{name} already exists"
            template:'<div class="popover"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title" style="display: none"></h3><div class="popover-content"><p></p></div></div></div>'
          selector.popover("show")
          #selector.find('.openFile').text("""#{model.get("name")}.#{model.get("ext")}""")
          selector.find('.openFile').html("""<i class="icon-file"></i> #{model.name}</a>""")
          setTimeout (=> 
            selector.popover('destroy')
            selector.removeClass("error")), 2000
        else 
          model.name = name
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
