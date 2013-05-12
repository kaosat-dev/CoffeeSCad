require.config
  deps: ["requireLib", "main"]
  
  config: 
    text:
      #env:'node'
      env: 'xhr'
  waitSeconds:200
  
  
  #baseUrl: window.location.protocol + "//" + window.location.host + window.location.pathname.split("/").slice(0, -1).join("/")
  paths:
    #JavaScript folders.
    libs:             "../assets/js/libs"
    plugins:          "../assets/js/plugins"
    vendor:           "../assets/vendor"
    
    #Libraries.
    jquery:           "../assets/js/libs/jquery-1.8.1.min"
    underscore:       "../assets/js/libs/underscore-min"
    backbone:         "../assets/js/libs/backbone"
    bootstrap:        "../assets/js/libs/bootstrap.min"
    #ace:              "../assets/js/libs/ace"
    
    CoffeeScript:     "../assets/js/libs/CoffeeScript"
    three:            "../assets/js/libs/three"
    detector:         "../assets/js/libs/detector"
    stats:            "../assets/js/libs/Stats"
    utils:            "../assets/js/libs/utils"
    
    dropbox:          "../assets/js/libs/dropbox"
    github:           "../assets/js/libs/github"
    
    XMLWriter:        "../assets/js/libs/XMLWriter-1.0.0"
    
    
    #plugins
    #jquery_hotkeys:   "../assets/js/plugins/jquery.hotkeys"
    jquery_ui:        "../assets/js/plugins/jquery-ui-1.10.1.custom"
    jquery_layout:    "../assets/js/plugins/jquery.layout-latest"
    jquery_jstree:    "../assets/js/plugins/jquery.jstree"
    jquery_sscroll:   "../assets/js/plugins/jquery.slimscroll"
    
    bootbox:          "../assets/js/plugins/bootbox.min"
    contextMenu:      "../assets/js/plugins/bootstrap-contextmenu"
    notify:           "../assets/js/plugins/bootstrap-notify"
    
    coffeelint:       "../assets/js/plugins/coffeelint"
    
    ### 
    coffee_synhigh:   "../assets/js/libs/codeMirror/mode/coffeescript/coffeescript"
    
    foldcode:         "../assets/js/plugins/codemirror/fold/foldcode"
    indent_fold:      "../assets/js/plugins/codemirror/fold/indent-fold"
    search:           "../assets/js/plugins/codemirror/search/search"
    search_cursor:    "../assets/js/plugins/codemirror/search/searchcursor"
    match_high:       "../assets/js/plugins/codemirror/search/match-highlighter"
    dialog:           "../assets/js/plugins/codemirror/dialog/dialog"
    hint:             "../assets/js/plugins/codemirror/hint/show-hint"
    jsHint:           "../assets/js/plugins/codemirror/hint/coffeescad-hint"
    closeBrackets:    "../assets/js/plugins/codemirror/edit/closeBrackets/closeBrackets"
    matchBrackets:    "../assets/js/plugins/codemirror/edit/matchBrackets/matchBrackets"###
    
    marionette:       "../assets/js/plugins/backbone.marionette.min"
    eventbinder:      "../assets/js/plugins/backbone.eventbinder.min"
    wreqr:            "../assets/js/plugins/backbone.wreqr.min"
    babysitter:       "../assets/js/plugins/backbone.babysitter.min"
    pickysitter:      "../assets/js/plugins/backbone.pickysitter" #select one view, unselect all others
    
    localstorage:     "../assets/js/plugins/backbone.localstorage"
    modelbinder :     "../assets/js/plugins/backbone.ModelBinder.min" #view model binding , very practical
    collectionbinder :"../assets/js/plugins/backbone.CollectionBinder.min"
    "backbone-forms" :           "../assets/js/plugins/backbone.forms"
    forms_bootstrap : "../assets/js/plugins/backbone.forms.bootstrap"
    forms_list      : "../assets/js/plugins/backbone.forms.list"  
    forms_custom    : "../assets/js/plugins/backbone.forms.custom"  
    backbone_nested:  "../assets/js/plugins/backbone.nested.min"
    
    
    three_csg:        "../assets/js/plugins/ThreeCSG"
    combo_cam:        "../assets/js/plugins/CombinedCamera"
    transformControls:"../assets/js/plugins/three/controls/transformControls"
    
    ObjectExport: "../assets/js/plugins/three/exporters/ObjectExport"
    GeometryExporter: "../assets/js/plugins/three/exporters/GeometryExporter"
    MaterialExporter: "../assets/js/plugins/three/exporters/MaterialExporter"
    ObjectParser: "../assets/js/plugins/three/parsers/ObjectParser"
    
    CopyShader:       "../assets/js/plugins/three/CopyShader"
    EffectComposer:   "../assets/js/plugins/three/EffectComposer"
    RenderPass:       "../assets/js/plugins/three/RenderPass"
    ShaderPass:       "../assets/js/plugins/three/ShaderPass"
    DotScreenShader :   "../assets/js/plugins/three/DotScreenShader"
    DotScreenPass :   "../assets/js/plugins/three/DotScreenPass"
    FXAAShader: "../assets/js/plugins/three/FXAAShader"
    EdgeShader: "../assets/js/plugins/three/EdgeShader"
    EdgeShader2: "../assets/js/plugins/three/EdgeShader2"
    VignetteShader: "../assets/js/plugins/three/VignetteShader"
    BlendShader : "../assets/js/plugins/three/BlendShader"
    AdditiveBlendShader : "../assets/js/plugins/three/AdditiveBlendShader"
    
    
  shim:
    #any AMD compliant lib should NOT need shims
    underscore:
      deps: []
      exports: '_'
    bootstrap:
      deps:    ["jquery"]
      exports:  "bootstrap"
    bootbox:
      dep: ["bootstrap"]
    contextMenu:
      dep: ["bootstrap"]
    notify:
      dep:["bootstrap"]
      
    'backbone':
      deps:    ["jquery","underscore"]
      exports:  "Backbone"
    marionette:
      deps:    ["jquery", "backbone","eventbinder","wreqr"]
      exports:  "marionette"
    localstorage:
      deps:    ["backbone","underscore"]
      exports:  "localstorage"
    #forms:  
    #  deps:    ["backbone","underscore"]
    #  exports:  "backbone-forms"
    #forms_bootstrap:
    #  deps: ["backbone-forms"]
    #forms_list:
    #  deps: ["forms"]
    #forms_custom:
    #  deps: ["forms"]
    #  exports:  "forms"
    
    backbone_nested:
      deps:["backbone"]
    
    #CoffeeScript:
    #  exports:  "CoffeeScript"
    coffeelint:
      deps:    ["CoffeeScript"]
    
    ###    
    CodeMirror:
      exports:  "CodeMirror"
    foldcode:
      deps:    ["CodeMirror"]
    indent_fold:
      deps:    ["CodeMirror","foldcode"]
    coffee_synhigh:
      deps:    ["CodeMirror"]
    jsHint:
      deps:    ["CodeMirror","hint"]
    search:
      deps:    ["CodeMirror"]
    search_cursor:
      deps:    ["CodeMirror"]
    dialog:
      deps:    ["CodeMirror"]
    match_high:
      deps:    ["CodeMirror","search","search_cursor"]
    hint:
      deps:    ["CodeMirror"]
    closeBrackets: 
      deps:    ["CodeMirror"]
    matchBrackets:
      deps:    ["CodeMirror"]###

    three: 
      exports : "THREE"
    three_csg: 
      deps:    ["three"]
      exports : "THREE.CSG"
    combo_cam: 
      deps:    ["three"]
      exports : "combo_cam"
    transformControls:
      deps: ["three"]
    detector: 
      exports : "Detector"
    stats:
      exports : "Stats"
    utils: 
      deps:    ["jquery"]
      exports : "normalizeEvent"
    ObjectExport:
      deps:["three","GeometryExporter","MaterialExporter"]  
    GeometryExporter:
      deps:["three"]
    MaterialExporter:
      deps:["three"]
    
    ObjectParser:
      deps:["three"]
      
    
    CopyShader:
      deps:    ["three"]
    EffectComposer:
      deps:    ["CopyShader","ShaderPass","RenderPass"]
    RenderPass:
      deps:    ["CopyShader"]
    ShaderPass:
      deps:    ["CopyShader"]
    DotScreenShader:
      deps:    ["CopyShader"]
    DotScreenPass :
      deps:    ["CopyShader","DotScreenShader"]
    FXAAShader :
      deps:["CopyShader"] 
    EdgeShader:
      deps:["CopyShader"] 
    EdgeShader2:
      deps:["CopyShader"] 
    VignetteShader:
      deps:["CopyShader"]
    BlendShader:
      deps:["three"]
    AdditiveBlendShader:
      deps:["three"]
      
      
      
      
    jquery_ui:
      deps:    ["jquery"]
      exports : "jquery_ui"   
    jquery_layout:
      deps:    ["jquery"]
      exports : "jquery_layout"
    jquery_jstree:
      deps: ["jquery"]
      exports: "jquery_jstree"
    jquery_sscroll:
      deps: ["jquery","jquery_ui"]
      exports: "jquery_sscroll"
      
    dropbox: 
      deps:    ["jquery"]
      exports : "Dropbox"
    
    github: 
      deps:    ["jquery"]
      exports : "Github"
    XMLWriter:
      exports: "XMLWriter"
      
