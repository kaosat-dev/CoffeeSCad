define (require)->
  
  union = (csg)->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
    else
      csgs = [csg]
    result = @
    i = 0
    while i < csgs.length
      islast = (i is (csgs.length - 1))
      result = result.unionSub(csgs[i], islast, islast)
      i++
      
  scale = (f, csg) ->
    csgs = undefined
    if csg instanceof Array
      csgs = csg
    else
      csgs = [csg]
    for csg in csgs
      csg.transform Matrix4x4.scaling(f)
