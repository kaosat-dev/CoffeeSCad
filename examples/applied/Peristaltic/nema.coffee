# Nemo 17 Pump 
# taken from https://github.com/se5a/CoffeeScad_PartsLibrary

class NemaMotor extends Part
  constructor:(options)->
    @defaults = {
      motorBody_len : 47.5,
      shaft_len : 22,
      shaft_flat: 2, #distance from center of shaft to flat
      motorBody_baselen : 9,
      motorBody_centlen : 31,
      shaft_radius : 2.5,
      motorBody_width : 42,
      motorBody_dradius : 27,
      motorBody_dradiuscent : 25,
      pilotRing_radius : 11,
      pilotRing_height : 2,

      mountingholes_fromcent : 15.5,
      mountingholes_radius : 1.5,
      mountingholes_depth : 4.5
    }
    options = @injectOptions(@defaults,options)
    super options
    
    shaftsub = new Cube(
      {
        size: [@shaft_radius * 2, @shaft_radius * 2, @shaft_len]
        center: [true, false, false]
        
      }).translate([0, @shaft_flat, @motorBody_len + @pilotRing_height])
    shaft = new Cylinder(
      {
        h: @shaft_len
        r: @shaft_radius
        center: [true, true, @motorBody_len + @pilotRing_radius]
      }).color([0.85,0.85,1]).subtract(shaftsub)
    
    motorBody_squaresub_in = new Cube(
      {
        size: [@motorBody_width, @motorBody_width, @motorBody_len]
        center: [true, true, false]
      })
      
    motorBody_squaresub_out = new Cube(
      {
        size: [@motorBody_dradius * 2, @motorBody_dradius * 2, @motorBody_len]       
        center: [true, true, false]
      })
    motorBody_sub = motorBody_squaresub_out.subtract(motorBody_squaresub_in)
    
    motorBody_center = new Cylinder(
      {
        r: @motorBody_dradiuscent
        h: @motorBody_centlen
        center: [true, true, false]
      }).translate([0,0,@motorBody_baselen]).subtract(motorBody_sub)
    motorBody_center.color([0.1, 0.1, 0.05])
    
    motorBody_base = new Cylinder(
      {
        r: @motorBody_dradius
        h: @motorBody_baselen
        center: [true, true, false]
      }).subtract(motorBody_sub)
    motorBody_base.color([0.6, 0.6, 1])
    
    pilotRing_sub = new Cylinder(
      {
        h: @pilotRing_height
        r: @shaft_radius * 1.5
        center: [true, true, @motorBody_len]
      })    
    pilotRing = new Cylinder(
      {
        h: @pilotRing_height
        r: @pilotRing_radius
        center: [true, true, @motorBody_len]
      }).subtract(pilotRing_sub).color([0.5, 0.5, 0.6])
      
    motorBody_mountPlate = new Cylinder(
      {
        r: @motorBody_dradius
        h: @motorBody_len - (@motorBody_baselen + @motorBody_centlen)
        center: [true, true, false]
      }).translate([0,0,@motorBody_baselen + @motorBody_centlen])
    motorBody_mountPlate.subtract(motorBody_sub).union(pilotRing)
    motorBody_mountPlate.color([0.6, 0.6, 1])
    
    mountingholes = new Cylinder(
      {
        h: @mountingholes_depth
        r: @mountingholes_radius
        center: [true, true, @motorBody_len - (@mountingholes_depth / 2) ]
      })
    
    motorBody_mountPlate = motorBody_mountPlate.subtract(
      mountingholes.clone().translate [@mountingholes_fromcent, @mountingholes_fromcent, 0]
    )
    
    motorBody_mountPlate = motorBody_mountPlate.subtract(
      mountingholes.clone().translate [-@mountingholes_fromcent,@mountingholes_fromcent, 0]
    )
    
    motorBody_mountPlate = motorBody_mountPlate.subtract(
      mountingholes.clone().translate [@mountingholes_fromcent, -@mountingholes_fromcent, 0]
    )
    motorBody_mountPlate = motorBody_mountPlate.subtract(
      mountingholes.clone().translate [-@mountingholes_fromcent, -@mountingholes_fromcent, 0]
    )
    
    
    motor = motorBody_center.union([motorBody_base, motorBody_mountPlate, shaft])
    #motor.subtract(motorBody_sub)
    
    @union(motor)



