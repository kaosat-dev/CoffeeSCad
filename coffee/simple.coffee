CSG = CSG


class Wrapper
  height:0.5
  constructor: (@width=1) ->
    
  render: =>
    cube = CSG.cube({center: [0, 0, 0],radius: [@width, @width, @height]})
    return cube
    

wrap= new Wrapper()
return wrap.render()
