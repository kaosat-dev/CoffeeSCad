define(["jquery", "underscore", "backbone", "backbone-forms"], function($, _, Backbone) {
  var Form, editors;
  Form = Backbone.Form;
  editors = Form.editors;
  return editors.BooleanSelect = editors.Select.extend({
    initialize: function(options) {
      options.schema.options = [
        {
          val: "1",
          label: "Yes"
        }, {
          val: "",
          label: "No"
        }
      ];
      return editors.Select.prototype.initialize.call(this, options);
    },
    getValue: function() {
      return !!editors.Select.prototype.getValue.call(this);
    },
    setValue: function(value) {
      value = (value ? "1" : "");
      return editors.Select.prototype.setValue.call(this, value);
    }
  });
});