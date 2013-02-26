define (require)->
  
  class Material
    #root material class: only contains "color" properties for now
    constructor:(options)->
      #options = options or {}
      defaults = {color:[1,1,1]}#"#FFFFFF"}
      {@color} = defaults
  
  class BaseMaterial extends Material
    #basic material class
    constructor:(options)->
      super options
      
  return {"Material": Material, "BaseMaterial":BaseMaterial}
    
    
