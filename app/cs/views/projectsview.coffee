define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  marionette = require 'marionette'
  mF_template = require "text!templates/multiFileView.tmpl"
  sF_template = require "text!templates/singleFileView.tmpl"
  
  class FileView extends marionette.ItemView
    template: sF_template
    tagName: "li"
    
    
  class FilesView extends marionette.CollectionView
    #template: mF_template
    tagName: "ul"
    
    constructor:(options)->
      super options
      @itemView = FileView

 
  return FilesView
