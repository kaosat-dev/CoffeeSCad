define(["jquery", "underscore", "backbone", "backbone-forms"], function($, _, Backbone) {
  var Form, editors;
  Form = Backbone.Form;
  editors = Form.editors;
  return editors.KeyBind = editors.Base.extend({

    tagName: 'input',
    
    defaultValue: '',
    
    previousValue: '',
    
    events: {
      'keyup':    'determineChange',
      'keypress': function(event) {
        var self = this;
        setTimeout(function() {
          self.determineChange();
        }, 0);
      },
      'select':   function(event) {
        this.trigger('select', this);
      },
      'focus':    function(event) {
        this.trigger('focus', this);
      },
      'blur':     function(event) {
        this.trigger('blur', this);
      }
    },
    
    initialize: function(options) {
      editors.Base.prototype.initialize.call(this, options);
      
      var schema = this.schema;
      
      //Allow customising text type (email, phone etc.) for HTML5 browsers
      var type = 'keyBind';
      
      if (schema && schema.editorAttrs && schema.editorAttrs.type) type = schema.editorAttrs.type;
      if (schema && schema.dataType) type = schema.dataType;

      this.$el.attr('type', type);
    },

    /**
     * Adds the editor to the DOM
     */
    render: function() {
      /*this.setValue(this.value);

      return this;*/
      
      
      var self = this,
          value = this.value || [];

      //Create main element
      var $el = $('<div >');//"<div></div>"
      /*var $el = $(Form.templates[this.schema.listTemplate]({
        items: '<b class="bbf-tmp"></b>'
      }));*/
      root = $('<div>')
        
       //Add existing items
      if (Object.keys(value).length) {
        
        _.each(value, function(itemValue, itemKey) {
          console.log(itemValue);
          root.append($('<div class="control-group"><div class="control-label" >'+ itemKey +'</div><div class="controls"> <input type="text" onClick=self.shortCutEntrySelected() value='+ itemValue+ '></input></div></div>'));
          //$("<i class='icon-fixed-width icon-file'></i>")
        });
      } 
      console.log(root);
      $el.append(root);
        
      //Store a reference to the list (item container)
      /*this.$list = $el.find('.bbf-tmp').parent().empty();

      

      //If no existing items create an empty one, unless the editor specifies otherwise
      else {
        if (!this.Editor.isAsync) this.addItem();
      }*/

      this.setElement($el);
      this.$el.attr('id', this.id);
      this.$el.attr('name', this.key);
            
      if (this.hasFocus) this.trigger('blur', this);
      
      return this;
      
    },
    
    determineChange: function(event) {
      var currentValue = this.$el.val();
      var changed = (currentValue !== this.previousValue);
      
      if (changed) {
        this.previousValue = currentValue;
        
        this.trigger('change', this);
      }
    },

    /**
     * Returns the current editor value
     * @return {String}
     */
    getValue: function() {
      return this.$el.val();
    },
    
    /**
     * Sets the value of the form element
     * @param {String}
     */
    setValue: function(value) { 
      this.$el.val(value);
    },
    
    focus: function() {
      if (this.hasFocus) return;

      this.$el.focus();
    },
    
    blur: function() {
      if (!this.hasFocus) return;

      this.$el.blur();
    },
    
    select: function() {
      this.$el.select();
      console.log("selected");
    },
    
    shortCutEntrySelected: function(){
        console.log("shortcut entry selected");
    }

  });
});

/*var log = $('#log')[0],
    pressedKeys = [];

$(document.body).keydown(function (evt) {
    var li = pressedKeys[evt.keyCode];
    if (!li) {
        li = log.appendChild(document.createElement('li'));
        pressedKeys[evt.keyCode] = li;
    }
    $(li).text('Down: ' + evt.keyCode);
    $(li).removeClass('key-up');
});

$(document.body).keyup(function (evt) {
    var li = pressedKeys[evt.keyCode];
    if (!li) {
       li = log.appendChild(document.createElement('li'));
    }
    $(li).text('Up: ' + evt.keyCode);
    $(li).addClass('key-up');
});*/