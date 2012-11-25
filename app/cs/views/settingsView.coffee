define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'forms'
  forms_bstrap= require 'forms_bootstrap'
  s_template  = require "text!templates/settings.tmpl"
  sh_template = require "text!templates/settingsHeader.tmpl"
  sha_template = require "text!templates/settingsHeaderAll.tmpl"
  
  sc_template = require "text!templates/settingsContent.tmpl"
  sca_template = require "text!templates/settingsContentAll.tmpl"
  
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
        "GlViewSettings":   GlViewSettingsWrapper
        "EditorSettings":   EditorSettingsWrapper
        "GitHubSettings":   GitHubSettingsWrapper
                    
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
            title: 'Nb of recent files to display (Feature N/A)'
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
  
  #-------------------------------------------------------------------#       
  class GlViewSettingsForm extends Backbone.Form
    #Backbone.Form.editors.List.Modal.ModalAdapter = Backbone.BootstrapModal
    constructor:(options)->
      if not options.schema
        options.schema=
          autoUpdate   : 'Checkbox' 
          
          renderer     :
            type: 'Select'
            options : ["webgl", "canvas"]
          antialiasing : 'Checkbox'
          
          shadows      : 'Checkbox'
          selfShadows  : 
            type:       'Checkbox'
            title:      'Object self shadowing'
          
          showAxes     : 'Checkbox' 
          
          showGrid     : 'Checkbox' 
          gridSize     : 'Number'  
          gridStep     : 'Number'
          gridColor    : 'Text'
          gridOpacity  : 'Number'
          
          showStats    : 'Checkbox'
          position     :
            type: 'Select'
            options: ['diagonal', 'top', 'bottom', 'front', 'back', 'left', 'right', 'center'] 
          
          projection   :
            type: 'Select'
            options: ['perspective', 'orthographic']
          
          center: 'Checkbox'
          
          wireframe    : 'Checkbox'
          
          helpersColor :  'Text'
          
          
      super options
  
  class GlViewSettingsWrapper extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new GlViewSettingsForm
        model: @model
       
    render:()=>
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
      return @el
  #-------------------------------------------------------------------#   
  class EditorSettingsForm extends Backbone.Form

    constructor:(options)->
      if not options.schema
        options.schema=
          startLine    : 'Number'
      super options
  
  class EditorSettingsWrapper extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new EditorSettingsForm
        model: @model
       
    render:()=>
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
      return @el    
      
  #-------------------------------------------------------------------# 
  class GitHubSettingsForm extends Backbone.Form
    
    constructor:(options)->
      if not options.schema
        options.schema=
          'configured'    : 
            type: 'Checkbox'
            title: 'Configured (Feature N/A)'
      super options
  
  class GitHubSettingsWrapper extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new GitHubSettingsForm
        model: @model
       
    render:()=>
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
      return @el     

  return SettingsView