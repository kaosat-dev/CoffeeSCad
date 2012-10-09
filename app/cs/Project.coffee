#project is a top level element
#a project contains files
#a project can reference another project (includes?)

class OpenCoffeeScad.ProjectFile extends Backbone.Model
  defaults:
    name: "MyProject"
    content: ""
  initialize: (options) =>


class OpenCoffeeScad.Project extends Backbone.Collection
  model: OpenCoffeeScad.ProjectFile
  
  initialize: (options) =>
    @all_files_saved=false
  
  export:(format)->
    

    
  
    
