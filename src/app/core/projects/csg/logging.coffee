define (require) ->
  log={}
  log.level = 1
  log.DEBUG = 0
  log.INFO = 1
  log.WARN = 2
  log.ERROR = 3
  log.entries = []
  
  #TODO: fix line number : currently this returns the line number in THIS file, not the caller
  
  log.debug = (message)=>
    if log.level <= log.DEBUG
      lineNumber = (new Error()).lineNumber
      log.entries.push({lvl:"DEBUG",msg:"#{message}",line:lineNumber})
  log.info = (message)=>
    if log.level <= log.INFO
      lineNumber = (new Error()).lineNumber
      log.entries.push({lvl:"INFO",msg:"#{message}",line:lineNumber})
  log.warn = (message)=>
    if log.level <= log.WARN
      lineNumber = (new Error()).lineNumber
      log.entries.push({lvl:"WARN",msg:"#{message}",line:lineNumber})
  log.error = (message,)=>
    if log.level <= log.ERROR
      lineNumber = (new Error()).lineNumber
      log.entries.push({lvl:"ERROR",msg:"#{message}",line:lineNumber})
  
  return {"log":log}