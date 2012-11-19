CSG = CSG


ELEC_COLOR =[ 0.5, 0.5, 0.6]

class PingSensor
  #all measurements based on http://www.parallax.com/Portals/0/Downloads/docs/prod/acc/28015-PING-v1.6.pdf
  #usefull
  width:21.3
  length:45.7
  height:3.2
  mount_holes_offset:2.5
  mount_holes_dia:3.1
  
  #visual
  emire_dia: 16.17
  emire_height:12.3
  emire_center_offset:0
  rounding_resolution:16
  
  constructor: (@pos=[0,0,0], @rot=[0,0,0]) ->
    @emire_center_offset=(41.7-@emire_dia)/2
    OpenJsCad.log("Dia is: "+@emire_dia)
    OpenJsCad.log("Center offset is: "+@emire_center_offset)
 
  render: =>
    result = new CSG()
    pcb = CSG.cube({center: [0, 0, 0],radius: [@width/2, @length/2, @height/2]}).translate([0, 0, @height/2]).setColor(0.5, 0.5, 0.6)
    result =result.union(pcb)
    
    for i in [-1,1]
      eyecyl =  CSG.cylinder({start: [0, 0, @height], end: [0, 0, @emire_height+@height],radius: @emire_dia/2,resolution: @rounding_resolution})
      eyecyl= eyecyl.translate([0,i*@emire_center_offset,0]).setColor(0.99, 0.85, 0.0)
      
      holecyl =  CSG.cylinder({start: [0, 0, 0], end: [0, 0, @height],radius: @mount_holes_dia/2,resolution: @rounding_resolution})
      holecyl = holecyl.translate([@width/2*i-i*@mount_holes_offset,@length/2*i-i* @mount_holes_offset,0])
      
      result = result.union(eyecyl).subtract(holecyl)

    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2])


class AdaServoDriver
  width:25.4
  length:62.5
  height:3
  constructor: (@pos=[0,0,0], @rot=[0,0,0]) ->
    
  render: =>
    result = new CSG()
    pcb = CSG.cube({center: [0, 0, @height/2],radius: [@width/2, @length/2, @height/2]}).setColor(ELEC_COLOR)
    return result.translate(@pos).rotateX(@rot[0]).rotateY(@rot[1]).rotateZ(@rot[2])

ping = new PingSensor()
return ping.render()




