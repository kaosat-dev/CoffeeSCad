#logging is quite practical for debugging/informational purposes
cubeSize =20
cube = new Cube({size:cubeSize}).color([0.9,0.5,0.1])
assembly.add(cube)

#here we set the logging level (good practice tip: it feels right at home
#  in a seperate config file
log.level=log.DEBUG
log.debug("cubeSize: #{cubeSize}")

#available log levels:
#log.DEBUG
#log.INFO
#log.WARN
#log.ERROR
