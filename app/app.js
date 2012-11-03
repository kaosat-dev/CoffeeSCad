// Generated by CoffeeScript 1.3.3
(function() {

  define(function(require) {
    var $, AlertView, CodeEditorView, CsgProcessor, CsgStlExporterMin, GlThreeView, Library, LoadView, MainContentLayout, MainMenuView, ModalRegion, Project, ProjectFile, ProjectView, SaveView, Settings, SettingsView, app, marionette, testcode, _, _ref, _ref1;
    $ = require('jquery');
    _ = require('underscore');
    marionette = require('marionette');
    require('bootstrap');
    CodeEditorView = require("views/codeView");
    MainMenuView = require("views/menuView");
    ProjectView = require("views/projectsview");
    SettingsView = require("views/settingsView");
    MainContentLayout = require("views/mainContentView");
    ModalRegion = require("views/modalRegion");
    _ref = require("views/fileSaveLoadView"), LoadView = _ref.LoadView, SaveView = _ref.SaveView;
    AlertView = require("views/alertView");
    GlThreeView = require("views/glThreeView");
    _ref1 = require("modules/project"), Library = _ref1.Library, Project = _ref1.Project, ProjectFile = _ref1.ProjectFile;
    Settings = require("modules/settings");
    CsgProcessor = require("modules/csg.processor");
    CsgStlExporterMin = require("modules/csg.stlexporter");
    testcode = "class Thingy\n  constructor: (@thickness=10, @pos=[0,0,0], @rot=[0,0,0]) ->\n  \n  render: =>\n    result = new CSG()\n    shape1 = fromPoints([[0,0], [150,50], [0,-50]])\n    shape = shape1.expand(20, 25)\n    shape = shape.extrude({offset:[0, 0, @thickness]}) \n    cyl = new Cylinder({start: [0, 0, -50],end: [0, 0, 50],radius:10, resolution:12})\n    result = shape.subtract(cyl)\n    return result.translate(@pos).rotateX(@rot[0]).\n    rotateY(@rot[1]).rotateZ(@rot[2]).color([1,0.5,0])\n\nthing = new Thingy(35)\nthing2 = new Thingy(25)\n\nres = thing.render().union(thing2.render().mirroredX().color([0.2,0.5,0.6]))\nres= res.rotateX(37)\nres= res.rotateZ(190)\nres= res.translate([0,0,100])\nreturn res";
    app = new marionette.Application({
      root: "/opencoffeescad"
    });
    app.addRegions({
      navigationRegion: "#navigation",
      mainRegion: "#mainContent",
      statusRegion: "#statusBar",
      modal: ModalRegion,
      alertModal: ModalRegion
    });
    app.on("start", function(opts) {
      console.log("App Started");
      return $("[rel=tooltip]").tooltip({
        placement: 'bottom'
      });
    });
    app.on("initialize:after", function() {
      return console.log("after init");
      /*fetch all settings
      */

    });
    app.addInitializer(function(options) {
      var deleteProject, exporter, loadProject, saveProject, stlexport,
        _this = this;
      exporter = new CsgStlExporterMin();
      this.settings = new Settings();
      this.settings.fetch();
      this.lib = new Library();
      this.lib.fetch();
      this.project = new Project({
        name: 'TestProject'
      });
      this.mainPart = new ProjectFile({
        name: "mainPart",
        ext: "coscad",
        content: testcode
      });
      this.project.add(this.mainPart);
      /*
          TODO: replace this hack with an actual reload of the LATEST project
          if @lib.length > 0
            @project = @lib.at(0)
            name = @project.get("name")
            @project = @lib.fetch({id:name})
            @mainPart = @project.pfiles.at(0)
            @project.add @mainPart
          else
            @project = new Project({name:'TestProject'})  
            @mainPart = new ProjectFile
              name: "mainPart"
              ext: "coscad"
              content: testcode    
            @project.add @mainPart
      */

      this.csgProcessor = new CsgProcessor();
      CsgStlExporterMin = require("modules/csg.stlexporter");
      stlexport = function() {
        var blobUrl, stlExp;
        stlExp = new CsgStlExporterMin(_this.mainPart.csg);
        blobUrl = stlExp["export"]();
        return _this.vent.trigger("stlGenDone", blobUrl);
      };
      this.vent.bind("downloadStlRequest", stlexport);
      this.codeEditorView = new CodeEditorView({
        model: this.mainPart,
        settings: this.settings.at(2)
      });
      this.mainMenuView = new MainMenuView({
        collection: this.lib
      });
      this.projectView = new ProjectView({
        collection: this.lib
      });
      this.glThreeView = new GlThreeView({
        model: this.mainPart,
        settings: this.settings.at(1)
      });
      this.mainContentLayout = new MainContentLayout;
      this.mainRegion.show(this.mainContentLayout);
      this.mainContentLayout.edit.show(this.codeEditorView);
      this.mainContentLayout.gl.show(this.glThreeView);
      this.navigationRegion.show(this.mainMenuView);
      this.alertModal.el = alertmodal;
      this.modal.app = this;
      saveProject = function(params) {
        var foundProjects;
        foundProjects = _this.lib.get(params);
        if (foundProjects != null) {
          console.log("project exists");
          _this.project.set("name", params);
          _this.lib.add(_this.project);
        } else {
          console.log("new project");
          _this.project.set("name", params);
          _this.lib.add(_this.project);
        }
        _this.project.save();
        _this.mainPart.save();
        console.log("Saved Elems");
        console.log(_this.project);
        console.log(_this.mainPart);
      };
      loadProject = function(name) {
        var project;
        console.log("Loading part: " + name);
        if (name !== _this.project.get("name")) {
          project = _this.lib.fetch({
            id: name
          });
          _this.project = project;
          _this.mainPart = project.pfiles.at(0);
          _this.project.add(_this.mainPart);
          _this.lib.add(_this.project);
          _this.codeEditorView.switchModel(_this.mainPart);
          _this.glThreeView.switchModel(_this.mainPart);
        } else {
          console.log("Project already loaded");
        }
      };
      deleteProject = function(name) {
        var i, model, _ref2;
        console.log("deleting project " + name);
        _this.project.destroy();
        _this.lib.remove(_this.project);
        _ref2 = _this.project.pfiles.models;
        for (i in _ref2) {
          model = _ref2[i];
          model.destroy();
        }
        localStorage.removeItem(_this.project.pfiles.localStorage.name);
        _this.project = new Project({
          name: 'TestProject'
        });
        _this.mainPart = new ProjectFile();
        _this.project.add(_this.mainPart);
        _this.codeEditorView.switchModel(_this.mainPart);
        _this.glThreeView.switchModel(_this.mainPart);
      };
      this.vent.bind("fileSaveRequest", saveProject);
      this.vent.bind("fileLoadRequest", loadProject);
      this.vent.bind("fileDeleteRequest", deleteProject);
      app.mainMenuView.on("project:new:mouseup", function() {});
      app.mainMenuView.on("file:new:mouseup", function() {
        _this.project = new Project({
          name: 'TestProject'
        });
        _this.mainPart = new ProjectFile();
        _this.project.add(_this.mainPart);
        _this.codeEditorView.switchModel(_this.mainPart);
        return _this.glThreeView.switchModel(_this.mainPart);
      });
      app.mainMenuView.on("file:save:mouseup", function() {
        if (_this.project.isNew2()) {
          _this.modView = new SaveView;
          return _this.modal.show(_this.modView);
        } else {
          console.log("save existing");
          return _this.vent.trigger("fileSaveRequest", _this.project.get("name"));
        }
      });
      app.mainMenuView.on("file:saveas:mouseup", function() {
        _this.modView = new SaveView;
        return _this.modal.show(_this.modView);
      });
      app.mainMenuView.on("file:load:mouseup", function() {
        _this.modView = new LoadView({
          collection: _this.lib
        });
        return _this.modal.show(_this.modView);
      });
      app.mainMenuView.on("settings:mouseup", function() {
        _this.modView = new SettingsView({
          model: _this.settings
        });
        return _this.modal.show(_this.modView);
      });
      return app.glThreeView.fromCsg();
    });
    /*return _.extend app,
      module: (additionalProps)->
        return _.extend
          Views: {}
          additionalProps
    */

    return app;
  });

}).call(this);
