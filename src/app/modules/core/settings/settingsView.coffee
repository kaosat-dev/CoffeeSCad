define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  bootstrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'forms'
  forms_bstrap= require 'forms_bootstrap'
  
  s_template  = require "text!./settings.tmpl"
  sh_template = require "text!./settingsHeader.tmpl"
  sha_template = require "text!./settingsHeaderAll.tmpl"
  sc_template = require "text!./settingsContent.tmpl"
  sca_template = require "text!./settingsContentAll.tmpl"
  
  reqRes = require 'modules/core/reqRes'#request response system , see backbone marionnette docs
  
  
  class SettingsView extends Backbone.Marionette.Layout
    template: s_template
    regions: 
      tabHeaders: "#tabHeaders"
      tabContent: "#tabContent"
    ui:
      tabHeaders: "#tabHeaders"
      tabContent: "#tabContent"
    events:
      "mouseup .applySettings": "applySettings"
      
    applySettings:(ev)=>
      for index, form of @tabContent.currentView.forms
        form.commit()
      @model.save()
    
    constructor:(options) ->
      super options
      @app = require 'app'
    
    onRender:()=>
      results = reqRes.request("foo")
      console.log reqRes
      console.log "GOT REQUEST RESULT"
      console.log results
      console.log reqRes
      
      #show tab nav
      sHeaderView = new SettingHeader
        collection: @model
      @tabHeaders.show sHeaderView
      #show tab panes
      sContentView = new SettingContent
        collection: @model
      @tabContent.show sContentView

      $(@ui.tabHeaders).find('li:first').addClass('active')
      defaultItem = $(@ui.tabContent).find('div .tab-pane:first')#:eq(1)
      defaultItem.addClass('active')
      defaultItem.removeClass('fade')
 
  #-------------------------------------------------------------------#   
  class GeneralSettingsForm extends Backbone.Form

    constructor:(options)->
      if not options.schema
        options.schema=
          maxRecentFilesDisplay: 
            type:'Number'
            title: 'Max recent files to display'
          theme:
            type:'Select'
            options : ["slate", "spacelab"]
            
      super options
      
  class GeneralSettingsWrapper extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new GeneralSettingsForm
        model: @model
       
    render:()=>
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
      return @el    
      
  class SettingHeaderItemView extends Backbone.Marionette.ItemView
    template: sh_template
    tagName: "li"
  
  class SettingHeader extends Backbone.Marionette.CompositeView
    itemView: SettingHeaderItemView
    tagName: "ul"
    template: sha_template
    itemViewContainer: "#settingsHeaderUl"
    ui:
      globalContainer: "#settingsHeaderUl"
    
    constructor:(options) ->
      super options
      
    onRender:()=>
      $(@ui.globalContainer).find('li:first').tab('show')

  ####

  class SettingContentItemView extends Backbone.Marionette.ItemView
    template: sc_template
    
    onRender:()=>
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
    
  class SettingContent extends Backbone.Marionette.CompositeView
    itemView: SettingContentItemView
    template: sca_template
    itemViewContainer: "#settingsContentAll"
    
    constructor:(options) ->
      super options
      @forms = []
      @specificViews =   
        "GeneralSettings":  GeneralSettingsWrapper
        #"KeyBindings"   :   KeyBindingsWrapper
              
    getItemView: (item) =>
      view = SettingContentItemView
      if item?
        try
          if @specificViews.hasOwnProperty(item.constructor.name)
            view = @specificViews[item.constructor.name]
        catch error 
          console.log "error: #{error}"
      return view
      
    onRender:()=>
      for index, childView of @children
        if childView.wrappedForm?
          @forms.push(childView.wrappedForm)
 
  return SettingsView