#original design by Jonathan Sorensen https://github.com/se5a 

class ThumbWheel extends Part
  constructor:(options)->
    @defaults = {total_radius : 30, base_height : 4, knobbles_num : 5,
    knobbles_radius : 5, knobbles_height : 5, centerhole_radius : 1.55,
    centerhex_radus : 3.1, centerhex_height : 2, centerhub_height : 4, centerhub_radius : 4}
    options = @injectOptions(options, @defaults)
    super options
    
    distance_to_knobbles = @total_radius - @knobbles_radius
    angleA = 360 / @knobbles_num
    angleARadians = angleA * (3.14159265359 / 180)
      
    # this function calculates the third side of a triangle from two sides(a,b) and an angle(A)
    get_sideC = (side_a, side_b, angle_A) -> Math.sqrt (Math.pow(side_a, 2) + Math.pow(side_b, 2) - 2 * side_a * side_b * Math.cos(angle_A)) 
    
    #the center hub:
    hub = new Cylinder
      h: @centerhub_height
      r: @centerhub_radius
      center: [0, 0, @centerhub_height / 2]
    
    #the nut-trap:
    hex = new Cylinder
      h: @centerhex_height
      r: @centerhex_radus  
      center: [0, 0, @centerhub_height - @centerhex_height / 2]
      $fn: 6 # This sets the number of sides to six.
      
    nuttrap = new Cylinder
      h: @centerhub_height
      r: @centerhole_radius
      center: [0, 0, @centerhub_height / 2]
    nuttrap = nuttrap.union(hex)
                              
    #the base 
    base = new Cylinder
      h: @base_height
      r: distance_to_knobbles
      center: [0, 0, @base_height / 2]
    
    #the little.... knobs.
    knobble = new Cylinder
      h: @knobbles_height
      r: @knobbles_radius
      center: [0, distance_to_knobbles, @knobbles_height / 2]
    
    #distance between the nobbles:
    knobble_seperation = get_sideC(distance_to_knobbles, distance_to_knobbles, angleARadians)
    
    #the scooped out section between the nobbles:
    scallop = new Cylinder
      h: @base_height
      r: (knobble_seperation - @knobbles_radius) / 2
      center: [0, distance_to_knobbles, @base_height / 2]
    scallop = scallop.rotate [0, 0, angleA / 2]
    
    #carving the object
    base.union(hub)
    base.subtract(nuttrap)
    
    #cutting out the scallops: (using while loop)
    i = 0
    while i < @knobbles_num
      base.subtract(scallop.clone().rotate [0 ,0 , angleA * i])
      i++
    
    #adding the knobs: (using for loop)
    for i in [0..@knobbles_num]
      base.union(knobble.clone().rotate [0 , 0, angleA * i])
    
    @union(base).color([0.7,0.2,0.1])
    
thumbWheel = new ThumbWheel()
assembly.add(thumbWheel)

