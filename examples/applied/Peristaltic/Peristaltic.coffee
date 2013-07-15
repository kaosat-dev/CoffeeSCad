include("nema.coffee")
include("pump.coffee")

@config = {
           explode:1, # 0 for assembled pump 1 for exploded view
           layout:0, # 1 for assembled , 0 for single print object
           lobes: 3, # number of rollers
           pipe_od: 5, # outside diameter of pipe
           pipe_id: 4, #inside diamter of pip
           roller_outer: 12, # outerside diameter of the roller
           wall_thickness:10 # thickness of the outer wall
           }
p = new Pump(@config)

assembly.add(p)
if @config.layout
  motor = new NemaMotor()
  motor.translate([0,0,-motor.motorBody_len])
  assembly.add(motor)
