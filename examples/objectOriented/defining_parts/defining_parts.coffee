#To make full use of the possibilities of coffeeSCad it is very important to use the "Part" class
#The Part class is a special class that enables the software to get various information about the objects you design:
#Number of parts of a certain type, what parameters were used to create it etc
#This is used , amongst others, by the BOM (bill of materials) system to generate the list of objects used in your project

class CrucialPieceOfHardware extends Part
  constructor:(options)->
    super(options) #you need to pass the parameters to the parent class so they can get registered
    @cb = new Cube({size:20})
    @cb.color([0.1,0.5,0.8])
    @union(@cb)
    

#You usually want to provide meanigfull defaults for your parts as well:

class CoolHardware extends Part
  constructor:(options)->
    defaults = {position:[0,0,0],thickness:5,servoType:"HXT900"}
    #here we merge defaults and the options passed in using the "merge" utility function
    #it takes two objects/hashes, and merges them into one
    {@position, @thickness, @servo} = options = merge(defaults, options)
    super options  #we pass the full options hash (parameters passed in + defaults) to the parent class  
    @cb = new Cube({size:[5,10,@thickness]})
    @cb.color([0.1,0.5,0.8])
    @cb.translate(@position)
    @union(@cb)

# an more compact alternitive to the above:
class CoolHardware2 extends Part
  constructor:(options)->
    @defaults = {position:[0,0,0],thickness:5,servoType:"HXT900"}    
    options = @injectOptions(@defaults, options)
    super options   
    @cb = new Cube({size:[5,10,@thickness]})
    @cb.color([0.1,0.5,0.8])
    @cb.translate(@position)
    @union(@cb)
    
coolHardware = new CoolHardware({thickness:10})
#another instance with default parameters
coolHardware1 = new CoolHardware()

coolHardware2 = new CoolHardware2(thickness:15)

assembly.add(coolHardware)
assembly.add(coolHardware1.translate([20,20,0]))
assembly.add(coolHardware2.translate([-20,20,0]))
#now if you compile this project and go to the bom view, you will see what classes and parameters the system picked up
