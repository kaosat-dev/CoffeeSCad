// Backbone.PickySitter, v0.1.0
// Copyright (c)2012 Jeremy McLeod, Isochronous.org
// Distributed under MIT license
// Heavily, heavily based on Backbone.Picky by Derick Bailey// http://github.com/derickbailey/backbone.picky
(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // AMD. Register as an anonymous module.
        define(["underscore", "backbone"], factory);
    }
}(this, function (_, Backbone) {
  Backbone.PickySitter = (function(Backbone, _) {
  
        var PickySitter = {};
  
        // PickySitter.SingleSelect
        // ------------------
        // A single-select mixin for Backbone.BabySitter, allowing a single
        // view to be selected within a ChildViewContainer. Selection of another
        // view within the container causes the previous view to be
        // deselected.
        PickySitter.SingleSelect = function(container) {
            this.container = container;
        };
  
        _.extend(PickySitter.SingleSelect.prototype, {
  
            // Select a view, deselecting any previously
            // selected view
            select: function(view) {
                view = getViewFromIdentifier(this.container, view);
                if(view && this.selected === view) {
                    return;
                }
  
                this.deselect();
  
                this.selected = view;
                this.selected.select();
                this.trigger("selected", view);
            },
  
            // Deselect a view, resulting in no view
            // being selected
            deselect: function(view) {
                if(!this.selected) { return; }
                view = (view) ? getViewFromIdentifier(this.container, view) : this.selected;
  
                if(this.selected !== view) { return; }
  
                this.selected.deselect();
                this.trigger("deselected", this.selected);
                delete this.selected;
            },
  
            getSelected: function() {
                return this.selected || false;
            }
  
        });
  
        // PickySitter.MultiSelect
        // -----------------
        // A mult-select mixin for Backbone.BabySitter, allowing a ChildViewContainer to
        // have multiple views selected, including `selectAll` and `selectNone`
        // capabilities.
        PickySitter.MultiSelect = function(container) {
            this.container = container;
            this.selected = {};
        };
  
        _.extend(PickySitter.MultiSelect.prototype, {
  
            // Select a specified view, make sure the
            // view knows it's selected, and hold on to
            // the selected view.
            select: function(view) {
                view = getViewFromIdentifier(this.container, view);
                if(this.selected[view.cid]) {
                    return;
                }
  
                this.selected[view.cid] = view;
                view.select();
                calculateSelectedLength(this);
            },
  
            // Deselect a specified view, make sure the
            // view knows it has been deselected, and remove
            // the view from the selected list.
            deselect: function(view) {
                view = getViewFromIdentifier(this.container, view);
                if(!this.selected[view.cid]) {
                    return;
                }
  
                delete this.selected[view.cid];
                view.deselect();
                calculateSelectedLength(this);
            },
  
            // Select all views in this container
            selectAll: function() {
                this.each(function(view) {
                    view.select();
                });
                calculateSelectedLength(this);
            },
  
            // Deselect all views in this container
            selectNone: function() {
                if(this.selectedLength === 0) {
                    return;
                }
                this.each(function(view) {
                    view.deselect();
                });
                calculateSelectedLength(this);
            },
  
            // Toggle select all / none. If some are selected, it
            // will select all. If all are selected, it will select
            // none. If none are selected, it will select all.
            toggleSelectAll: function() {
                if(this.selectedLength === this.length) {
                    this.selectNone();
                } else {
                    this.selectAll();
                }
            },
  
            getSelected: function() {
                if(this.selectedLength === this.length) {
                    return false;
                }
                return this.container.where(function(view) {
                    return view.selected === true;
                });
            }
        });
  
        // PickySitter.Selectable
        // ----------------
        // A selectable mixin for Backbone.View, allowing a view to be selected,
        // enabling it to work with PickyView.MultiSelect or on it's own
        PickySitter.Selectable = function(view) {
            this.view = view;
        };
  
        _.extend(PickySitter.Selectable.prototype, {
  
            // Select this model, and tell our
            // collection that we're selected
            select: function() {
                if(this.selected) {
                    return;
                }
  
                this.selected = true;
                this.trigger("selected");
  
                if(this.container) {
                    this.container.select(this);
                }
            },
  
            // Deselect this view, and tell our
            // container that we're deselected
            deselect: function() {
                if(!this.selected) {
                    return;
                }
  
                this.selected = false;
                this.trigger("deselected");
  
                if(this.container) {
                    this.container.deselect(this);
                }
            },
  
            // Change selected to the opposite of what
            // it currently is
            toggleSelected: function() {
                if(this.selected) {
                    this.deselect();
                } else {
                    this.select();
                }
            }
        });
  
        // Helper Methods
        // --------------
        // Calculate the number of selected items in a container
        // and update the container with that length. Trigger events
        // from the container based on the number of selected items.
        var calculateSelectedLength = function(container) {
                container.selectedLength = _.size(container.selected);
  
                var selectedLength = container.selectedLength;
                var length = container.length;
  
                if(selectedLength === length) {
                    container.trigger("select:all", container);
                    return;
                }
  
                if(selectedLength === 0) {
                    container.trigger("select:none", container);
                    return;
                }
  
                if(selectedLength > 0 && selectedLength < length) {
                    container.trigger("select:some", container);
                    return;
                }
            };
  
        var getViewFromIdentifier = function(container, id) {
                // If it's a view, return it immediately
                if(id instanceof Backbone.View || (id.render && id.el)) {
                    return id;
                    // Some type of model
                } else if(id instanceof Backbone.Model || (id.attributes && id.toJSON && id.fetch)) {
                    return container.findByModel(id);
                    // Some type of collection
                } else if(id instanceof Backbone.Collection || (id.models && id.toJSON && id.getByCid)) {
                    return container.findByCollection(id);
                    // Index
                } else if(_.isNumber(id)) {
                    return container.findByIndex(id);
                    // Custom identifier or cid
                } else if(_.isString(id)) {
                    return container.findByCustom(id) || container.findByCid(id);
                } else {
                    return false;
                }
            };
  
        return PickySitter;
  
    })(Backbone, _);
  return Backbone.PickySitter;
}));