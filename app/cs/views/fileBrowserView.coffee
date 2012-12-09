define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap = require 'bootstrap'
  marionette = require 'marionette'
  jstree = require 'jquery_jstree'
  dummyTemplate = require "text!templates/dummy.tmpl"
  fileBrowserSingleTemplate= require "text!templates/fileBrowserSingle.tmpl"
  fileBrowserTemplate = require "text!templates/fileBrowser.tmpl"
  
  jquery_ui = require 'jquery_ui'
  
  class FileBrowseRegion extends Backbone.Marionette.Region
    el: "#fileBrowseRegion",

    constructor: ->
      _.bindAll(this)
      @on("view:show", @showModal, @)

    getEl: (selector)->
      $el = $(selector)
      $el.on("hidden", @close)
      return $el

    _showModal:(view)=>
      view.on("close", @hideModal, @)
      @$el.modal({'show':true,'backdrop':false}).addClass('modal-big')
    
    showModal: (view)=>
      $el = @getEl()
      view.isVisible=true
      el = "#fileBrowseRegion"
      $(el).dialog
        title : "Files"#view.model.get("name")
        width: 200
        height: 400
        position: 
          my: "left center"
          at: "left center"
        beforeClose: =>
          view.isVisible=false
          #view.off("close", @hideModal, @)#: unbind this on close
          view.close()
      
    hideModal: ->
      @$el.modal 'hide'
      
  
  class SingleFileView extends Backbone.Marionette.ItemView
    template: fileBrowserSingleTemplate
    tagName: "ul"
    templateHelpers:
      renderFiles:()->
        fileInfo = ""
        fileInfo += "<li class='loadFileDirect'><a href='#' class='loadFileDirect'>mainpart.coscad</a></li>"
        for pfile in @pfiles
          item = "<li class='loadFileDirect'><a href='#'>#{pfile.get('name')}</a></li>" 
          fileInfo += item 
        return fileInfo
    
    constructor:(options)->
      super options
      @app = require 'app'
    
    events: 
      "mouseup .loadFileDirect":    "requestFileLoad"
      
    requestFileLoad:(ev)=>
      fileName = $(ev.currentTarget).html()
      console.log "requesting #{fileName}"
      #@app.vent.trigger("fileLoadRequest", fileName)
  
  class FileBrowserView extends Backbone.Marionette.CollectionView
    itemView: SingleFileView
    #tagName: "li"
    #template:fileBrowserTemplate
    
    constructor:(options) ->
      super options
      @app = require 'app'
    
    onRender:(options)->
      customMenu = (node) =>
        # The default set of all items
        items =
          deleteItem: # The "delete" menu item
            label: "Delete"
            action: ->
              console.log "aie aie"
              console.log $(node)
              if $(node).hasClass("folder")
                delete items.deleteItem
                @render()
        
        # Delete the "delete" menu item
        delete items.deleteItem  if $(node).hasClass("folder")
        items
      
      
      tmp = @$el.jstree 
        "core":
          "animation":0
        "plugins" : ["html_data","ui","contextmenu","themeroller"]
        "contextmenu":
          "items": customMenu
        #
        ###"themes":
          "theme": "default",
          "dots": true,
          "icons": false,
        ###
        ### 
        "html_data" : 
          "data" : """
          <li id='root'>
            <a href='#'>Root node</a>
            <ul><li><a href='#'>Child node</a></li></ul>
            <ul><li><a href='#'>Child node2</a></li></ul>
            <ul>
              <li>
                <a href='#'>Child node2</a>
                <ul>
                  <li><a href='#'>Child node2 sub 1</a></li>
                </ul>
              </li>
            </ul>
          </li>"""
        ###
      #@bindUIElements()
      

      @$el.bind("open_node.jstree close_node.jstree",(e)->
        console.log "tutupouet"
      )
      
      @$el.bind("select_node.jstree",(event, data)=>
        id = $.jstree._focused().get_selected().attr("id")
        fileName = id[7..id.length] 
        @app.vent.trigger("fileLoadRequest", fileName)
      )

  return {FileBrowserView, FileBrowseRegion}