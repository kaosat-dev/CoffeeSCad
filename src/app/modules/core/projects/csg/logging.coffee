define (require) ->
  log={}
  log.level = 1
  log.DEBUG = 0
  log.INFO = 1
  log.WARN = 2
  log.ERROR = 3
  log.entries = []
  
  
  log.debug = (message)=>
    if log.level <= log.DEBUG
      log.entries.push({lvl:"DEBUG",msg:"#{message}"})
  log.info = (message)=>
    if log.level <= log.INFO
      log.entries.push({lvl:"INFO",msg:"#{message}"})
  log.warn = (message)=>
    if log.level <= log.WARN
      log.entries.push({lvl:"WARN",msg:"#{message}"})
  log.error = (message)=>
    if log.level <= log.ERROR
      log.entries.push({lvl:"ERROR",msg:"#{message}"})
  
  return {"log":log}