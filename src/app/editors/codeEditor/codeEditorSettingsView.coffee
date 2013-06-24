define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  boostrap    = require 'bootstrap'
  marionette  = require 'marionette'
  forms       = require 'backbone-forms'
  
  class CodeEditorSettingsForm extends Backbone.Form
    constructor:(options)->
      if not options.schema
        options.schema=
          startLine    : 'Number'
          fontSize    : {type:'Number', editorAttrs: { step: 0.1, min: 0.5, max: 1.5 } }
          undoDepth    : {type:'Number', editorAttrs: { step: 1, min: 1, max: 100 } }
          
          autoClose : {type:'Checkbox'}
          highlightLine: {type:'Checkbox'}
          showInvisibles:{type:'Checkbox'}
          showIndentGuides:{type:'Checkbox'}
          showGutter:{type:'Checkbox'}
          
          theme: 
            type:'Select'
            options: ["monokai","vibrant_ink","tomorrow_night_eighties","terminal","chaos","solarized_dark","solarized_light","clouds","eclipse","github"]
          
          
          doLint: {type:'Checkbox',title: 'Lint code'}
          
        options.fieldsets=[
          "legend": "General settings"
          "fields": ["fontSize","autoClose","highlightLine","showInvisibles","showIndentGuides","showGutter","theme"]
        ,
          "legend":"Linting"
          "fields": ["doLint"]
          #"fields": ["linting.indentation","linting.max_line_length","linting.no_tabs","linting.no_trailing_whitespace","linting.no_trailing_semicolons"]
        ]
      super options
      
      #TODO: re add "startLine","undoDepth",
      #SmartIndent, not so sure "smartIndent"
      ### linting      :
            type: "Object"
            title:''
            subSchema:
              max_line_length: 
                title : 'Max line length'
                type: 'Object'
                subSchema:
                  value:
                    title:'Max line length' 
                    type: 'Number'
                  level: 
                    title: 'Max line length Error Level'
                    type: 'Select'
                    options : ["ignore","warn", "error"]
              no_tabs:
                title: 'No tabs'
                type: 'Object'
                subSchema:
                  level: 
                    type: 'Select'
                    options : ["ignore","warn", "error"]
              indentation:
                title: "Indentation"
                type: "Object"
                subSchema:
                  value:{type:'Number'}
                  level: 
                    type: 'Select'
                    options : ["ignore","warn", "error"]
              no_trailing_whitespace:
                title: "Trailing whitespaces"
                type: "Object"
                subSchema:
                  level: 
                    type: 'Select'
                    options : ["ignore","warn", "error"]
              no_trailing_semicolons:
                title: "Trailing semicolons"
                type: "Object"
                subSchema:
                  level: 
                    type: 'Select'
                    options : ["ignore","warn", "error"]
                
          ###   
      
  class CodeEditorSettingsView extends Backbone.Marionette.ItemView
    constructor:(options)->
      super options
      @wrappedForm = new CodeEditorSettingsForm
        model: @model
       
    render:()=>
      tmp = @wrappedForm.render()
      @$el.append(tmp.el)
      @$el.addClass("tab-pane")
      @$el.addClass("fade")
      @$el.attr('id',@model.get("name"))
      return @el   
      
  return CodeEditorSettingsView 