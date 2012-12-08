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
        console.log "in render files"
        fileInfo = ""
        console.log @
        console.log @files
        console.log @pfiles.length
        for pfile in @pfiles
          item = "<li><a href='#'>#{pfile.get('name')}</a></li>" 
          fileInfo += item 
        return fileInfo
  
  class FileBrowserView extends Backbone.Marionette.CollectionView
    itemView: SingleFileView
    #tagName: "li"
    #template:fileBrowserTemplate
    
    constructor:(options) ->
      super options
      @app = require 'app'
    
    onRender_:(options)->
      tmp = @$el.jstree 
        "core":
          "animation":0
        "plugins" : ["themes","html_data","ui","contextmenu"]
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
    
      tmp.bind("loaded.jstree", (event, data)=>
        console.log "JSTREE ready")  

      @$el.bind("open_node.jstree close_node.jstree",(e)->
        console.log "tutupouet"
      )
      
      @$el.bind("select_node.jstree",(event, data)->
        console.log "gnark"
        #alert(data.rslt.obj.attr("id")))
      )

  return {FileBrowserView, FileBrowseRegion}