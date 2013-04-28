# peristaltic pump
# Simonk Kirkby
# tigger@interthingy.com
# 20130427

class Pump extends Part
  constructor:(options)->
    @defaults = {
      lobes: 5,
      pipe_od: 5,
      pipe_id: 4,
      pump_radius:50,
      res: 50,
      clearance:1,
      base_thickness:5,
      wall_thickness:5,
      rotor_thickness: 20,
      bolt_diameter:3,
      bolt_length: 20,
      roller_outer:12,
      roller_inner:3,
      roller_thickness:10,
      explode:0,
      layout:1
    }
    options = @injectOptions(@defaults,options)
    super options
    # layout 1 shows assembly 0 make a single part for printing
    if @layout
      # the base and shroud
      b = new Base_assembly(options)
      b.translate([0,0,@rotor_thickness*@explode])
      
      #the rotor assembly
      ra = new Rotor_assembly(options)
      ra.color([0.4,0.0,0.4])
      ra.translate([0,0,@base_thickness+@clearance])
      ra.translate([0,0,@rotor_thickness*3*@explode])
      
      # the coupling 
      co = new Coupling(options)
      co.color([0.6,0.6,0.6])
      co.translate([0,0,@base_thickness+@clearance])
      co.translate([0,0,@rotor_thickness*2*@explode])
         
      # the piping 
      pif = new Pipe_form(options)
      pif.translate([0,0,@base_thickness+@clearance])
      
      # Add all the parts into the pump
      @add(pif)
      @add(b)
      @add(ra)
      @add(co)
      
    else
      @explode = 0
      # all the individual parts
      ba = new Base(options)
      lr = new Lower_rotor(options)
      ur = new Upper_rotor(options)
      co = new Coupling(options)
      rp = new Roller_print(options)
      # place them 
      ba.translate([-@wall_thickness,-@wall_thickness,0])
      co.translate([-@wall_thickness,-@wall_thickness,0])
      lr.translate([0,@pump_radius+@clearance,0])
      ur.translate([@pump_radius+@clearance,0,0])
      rp.translate([@pump_radius+@clearance,@pump_radius+@clearance,0])
      #add them all together
      @union(ba)
      @union(lr)
      @union(ur)
      @union(co)
      @union(rp)
      @color([0.5,0.5,0.5])
      # move the lot
      @translate([-@pump_radius/2,-@pump_radius/2,0])
 
 # Base assembly
 class Base_assembly extends Part
  constructor:(options)->
    @defaults = {
      bolt_spacing: 15.5,
      pilot_hole: 11
    }
    options = @injectOptions(@defaults,options)
    super options
    b = new Base(options)
    @add(b)
    bolt1 = new Caphead({m:3,bolt_length:10})
    bolt1.translate([0,0,@base_thickness-1.25*@bolt_diameter])
    bolt1.translate([0,0,@base_thickness*3*@explode])
    bolt2 = bolt1.clone()
    bolt3 = bolt1.clone()
    bolt4 = bolt1.clone()
    
    bolt1.translate([@bolt_spacing,@bolt_spacing,0])
    bolt2.translate([-@bolt_spacing,@bolt_spacing,0])
    bolt3.translate([@bolt_spacing,-@bolt_spacing,0])
    bolt4.translate([-@bolt_spacing,-@bolt_spacing,0])
    
    @add(bolt1)
    @add(bolt2)
    @add(bolt3)
    @add(bolt4)
    
    
 # Base plate and stepper mountings
 class Base extends Part
  constructor:(options)->
    @defaults = {
      bolt_spacing: 15.5,
      pilot_hole: 11
    }
    options = @injectOptions(@defaults,options)
    super options
    
    block = new Cylinder({$fn:@res,d:@pump_radius+@wall_thickness+2*@clearance,h:@base_thickness})
    base_block = new Cube({size:[@pump_radius+@wall_thickness+2*@clearance,@pump_radius/2+@wall_thickness,@base_thickness],center:[true,false,false]})
    block.union(base_block)
    # the bolt holes
    #bolt_hole1 = new Cylinder({r:@bolt_radius,h:@base_thickness*2})
    bolt_hole1 = new Caphead({m:3,bolt_length:10}).cutout
    bolt_hole1.translate([0,0,@base_thickness-1.25*@bolt_diameter])
    bolt_hole2 = bolt_hole1.clone()
    bolt_hole3 = bolt_hole1.clone()
    bolt_hole4 = bolt_hole1.clone()
    
    bolt_hole1.translate([@bolt_spacing,@bolt_spacing,0])
    bolt_hole2.translate([-@bolt_spacing,@bolt_spacing,0])
    bolt_hole3.translate([@bolt_spacing,-@bolt_spacing,0])
    bolt_hole4.translate([-@bolt_spacing,-@bolt_spacing,0])
    
    block.subtract(bolt_hole1)
    block.subtract(bolt_hole2)
    block.subtract(bolt_hole3)
    block.subtract(bolt_hole4)
    # the pilot hole
    pilot = new Cylinder({r:@pilot_hole,h:@base_thickness*2})
    block.subtract(pilot)
    # add the shroud
    sh = new Shroud(options)
    block.union(sh)
    @union(block)
 
 # display class for the pipe in place
 class Pipe_form extends Part
  constructor:(options)->
   @defaults = {}
   options = @injectOptions(@defaults,options)
   super options
    # open pip
   open_pipe = new Cylinder({d:@pump_radius-0.1,h:@pipe_od})
   open_pipe_in = new Cylinder({d:@pump_radius-2*@pipe_od,h:@pipe_od})
   open_pipe.subtract(open_pipe_in)
   open_pipe.color([0,0,1,0.77])
   open_pipe.translate([0,0,(@rotor_thickness/2)-@pipe_od/2])
   open_pipe.translate([0,0,@rotor_thickness*4*@explode])
    
   @flat_pipe_size = Math.PI*@pipe_od/2
   flat_pipe = new Cylinder({d:@pump_radius,h:@flat_pipe_size})
   flat_pipe_in = new Cylinder({d:@pump_radius-2*(@pipe_od-@pipe_id),h:@flat_pipe_size})
   flat_pipe.subtract(flat_pipe_in)
   flat_pipe.color([0,1,0,0.77])
   flat_pipe.translate([0,0,(@rotor_thickness/2)-@flat_pipe_size/2])
   flat_pipe.translate([0,0,@rotor_thickness*4*@explode])

   @add(open_pipe)
   @add(flat_pipe)
 
    
 # the upper section of the base and the tube guides
 class Shroud extends Part
  constructor:(options)->
    @defaults = {
      height: 30
    }
    options = @injectOptions(@defaults,options)
    super options
    outer = new Cylinder({$fn:@res,d:@pump_radius+@wall_thickness,h:@rotor_thickness})
    inner = new Cylinder({$fn:@res,d:@pump_radius,h:@rotor_thickness+0.1})
    block = new Cube({size:[@pump_radius+@wall_thickness,@pump_radius/2+@wall_thickness,@rotor_thickness],center:[true,false,false]})
    #block.color([0.5,0.5,0.5])

    # pipe channel
    pipe_base = new Cylinder({d:@pipe_od,h:@pump_radius})
    pipe_slot = new Cube({size:[@pipe_od,@rotor_thickness,@pump_radius],center:[true,false,false]})
    
    pipe_base.union(pipe_slot)
    pipe_base.rotate([-90,180,0])
    pipe_base2 = pipe_base.clone()
    pipe_base.translate([@pump_radius/2-@pipe_od/2,0,@clearance+@pipe_od*2])
    pipe_base2.translate([-@pump_radius/2+@pipe_od/2,0,@clearance+@pipe_od*2])
    bolt_hole = new Cylinder({d:@bolt_diameter,h:@rotor_thickness/2})
      
    outer.union(block)
    outer.subtract(pipe_base)
    outer.subtract(pipe_base2)
    outer.subtract(inner)
    outer.translate([0,0,@base_thickness])
    @union(outer)
 
    
 # assembled rotor
 class Rotor_assembly extends Part
  constructor:(options)->
    @defaults = {
      rotor_radius: 20,
      height: 30
    }
    options = @injectOptions(@defaults,options)
    super options
    
    be = new Roller(options)
    #@extra = {
    #pipe_flat : 2*(@pipe_od-@pipe_id),
    #bearing_offset : (@pump_radius/2)-(be.roller_outer/2)-@pipe_flat
    #}
    #options = @injectOptions(@extra,options)
    
    lr = new Lower_rotor(options)
    @add(lr)
    
    # calcs
    @pipe_flat = (@pipe_od-@pipe_id)
    @bearing_offset = (@pump_radius/2)-(be.roller_outer/2)-@pipe_flat
    # added components
    for i in [0..@lobes]
      b = new Roller(options)
      b.translate([(@pump_radius/2)-(be.roller_outer/2)-@pipe_flat,0,@rotor_thickness/2-b.roller_thickness/2])
      b.translate([0,0,@rotor_thickness*@explode])
      b.rotate([0,0,(360/@lobes)*i])
      @add(b)
      
      n = new Nut({m:@bolt_diameter})
      n.translate([@bearing_offset,0,0])
      n.translate([0,0,@rotor_thickness*-0.8*@explode])
      n.rotate([0,0,(360/@lobes)*i])
      @add(n)
      
      bo = new Caphead({m:@bolt_diameter,bolt_length:@bolt_length})
      bo.translate([@bearing_offset,0,@rotor_thickness])
      bo.translate([0,0,@rotor_thickness*3.5*@explode])
      bo.rotate([0,0,(360/@lobes)*i])
      @add(bo)

    upr = new Upper_rotor(options)
    upr.rotate([180,0,0])
    upr.translate([0,0,@rotor_thickness])
    upr.translate([0,0,2*@rotor_thickness*@explode])
    @add(upr)

# base class for the split rotor 
class Half_rotor extends Part
  constructor:(options)->
    @defaults = {rotor_radius: 20,height: 30}
    options = @injectOptions(@defaults,options)
    super options
    be = new Roller(options)
    # calcs
    @pipe_flat = (@pipe_od-@pipe_id)
    @bearing_offset = (@pump_radius/2)-(be.roller_outer/2)-@pipe_flat
    rotor = new Cylinder({$fn:@res,r:@pump_radius/2-@pipe_od-2*@clearance,h:@rotor_thickness*0.5})
    for i in [0..@lobes]
      bolt_support = new Cylinder({d:@bolt_diameter*2.5,h:@rotor_thickness/2})
      bolt_support.translate([@bearing_offset,0,0])
      bolt_support.rotate([0,0,(360/@lobes)*i])
      rotor.union(bolt_support)
      
      bolt_hole = new Cylinder({d:@bolt_diameter,h:@rotor_thickness/2})
      bolt_hole.translate([@bearing_offset,0,0])
      bolt_hole.rotate([0,0,(360/@lobes)*i])
      rotor.subtract(bolt_hole)
      
      hole = new Cylinder({d:be.roller_outer+@clearance,h:be.roller_thickness})
      hole.translate([@bearing_offset,0,@rotor_thickness*0.5-be.roller_thickness*0.5-@clearance])
      hole.rotate([0,0,(360/@lobes)*i])
      rotor.subtract(hole)
      
    @union(rotor)

# modify the half roter for the lower
class Lower_rotor extends Part
  constructor:(options)->
    @defaults = {rotor_radius: 20,height: 30}
    options = @injectOptions(@defaults,options)
    super options
    
    # coupling for subtraction
    co = new Coupling(options).cutout
    rotor = new Half_rotor(options)
    rotor.subtract(co)
    be = new Roller(options)
    @pipe_flat = (@pipe_od-@pipe_id)
    @bearing_offset = (@pump_radius/2)-(be.roller_outer/2)-@pipe_flat
    for i in [0..@lobes]
      n = new Nut({m:@bolt_diameter}).cutout
      n.translate([@bearing_offset,0,0])
      n.rotate([0,0,(360/@lobes)*i])
      rotor.subtract(n)
    @union(rotor)

# modify the half rotor for the upper
# the coupling is rotated around 
# base part is in position for printing 
class Upper_rotor extends Part
  constructor:(options)->
    @defaults = {rotor_radius: 20,height: 30}
    options = @injectOptions(@defaults,options)
    super options
    
    # coupling for subtraction
    co = new Coupling(options).cutout
    co.rotate([180,0,0])
    co.translate([0,0,@rotor_thickness])
    rotor = new Half_rotor(options)
    rotor.subtract(co)
    @union(rotor)
    
class Coupling extends Part
  constructor:(options)->
    @defaults = {
      bot_rad:8,
      top_rad:4,
      sides:6,
      shaft:5,
      shaft_len:16
    }
    options = @injectOptions(@defaults,options)
    super options
    coup = new Cylinder({$fn:@sides,h:@rotor_thickness,r1:@bot_rad,r2:@top_rad})
    bot = new Cylinder({r:@bot_rad,h:@base_thickness})
    coup.union(bot)
    
    # cutout for subtraction 
    @cutout = coup.clone()
    
    sub_shaft = new Cylinder({d:@shaft,h:@shaft_len})
    coup.subtract(sub_shaft)
    
    # for viewing internals
    #slice = new Cube({size:50,center:[true,false,false]})
    #coup.subtract(slice)
    
    @union(coup)

class Nut extends Part
  constructor:(options)->
    @defaults = {m:3}
    options = @injectOptions(@defaults,options)
    super options
    nut_outer = new Cylinder({$fn:6,h:@m*0.8,d:1.8*@m})
    # subobject for subtraction
    @cutout = nut_outer.clone()
    nut_inner = new Cylinder(d:@m,h:2*@m,center=[true,true,true])
    nut_outer.subtract(nut_inner)
    nut_outer.color([0.4,0.4,0.4])
    @union(nut_outer)
    
class Caphead extends Part
  constructor:(options)->
    @defaults = {m:3,bolt_length:20}
    options = @injectOptions(@defaults,options)
    super options
    
    shaft = new Cylinder({d:@m,h:@bolt_length})
    shaft.translate([0,0,-@bolt_length])
    # for external access
    head_height = 1.25*@m
    head = new Cylinder({d:1.5*@m,h:head_height})
    
    shaft.union(head)
    # object for cutout
    @cutout = shaft.clone()
    
    hex = new Cylinder({$fn:6,h:@m,d:0.8*@m})
    hex.translate([0,0,0.25*@m])
    shaft.subtract(hex)
    shaft.color([0.4,0.4,0.4])
    @union(shaft)

# Roller
# if you want to use bearings change the dimensions 
class Roller extends Part
  constructor:(options)->
    @defaults = {
      roller_outer: 12,
      roller_inner: 3,
      roller_thickness: 10
    }
    options = @injectOptions(@defaults,options)
    super options 
    o = new Cylinder({r:@roller_outer/2,h:@roller_thickness})
    i = new Cylinder({r:@roller_inner/2,h:@roller_thickness*2})
    o.subtract(i)
    o.color([0.4,0.4,0.4])
    @union(o)

# lay out the rollers for printing
class Roller_print extends Part
  constructor:(options)->
    @defaults = {spacing:3
    }
    options = @injectOptions(@defaults,options)
    super options
    for i in [0..@lobes]
      r = new Roller(options)
      r.translate([@roller_outer+2*@clearance,0,0])
      r.rotate([0,0,(360/@lobes)*i])
      @union(r)

      
