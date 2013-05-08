define (require) ->
  CoffeeScript = require 'CoffeeScript'
  
  wrap = (expressions) ->
    expressions = expressions.map (expression) ->
      wrap_obj(expression)
      
  wrap_obj = (expression) ->
    expression.children = undefined
    keys = [
      'array',
      'attempt',
      'base',
      'body',
      'condition',
      'elseBody',
      'error',
      'ensure',
      'expression',
      'first',
      'from',
      'index',
      'name',
      'object',
      'otherwise',
      'parent',
      'range',
      'recovery',
      'second',
      'source',
      'subject',
      'to',
      'value',
      'variable',
      ]
    for key in keys
      if expression[key]
        expression[key] = wrap_obj expression[key]
    list_keys = [
      'args',
      'expressions',
      'objects',
      'params',
      'properties',
    ]
    for list_key in list_keys
      if expression[list_key]
        expression[list_key] = wrap expression[list_key]
    if expression.cases
      my_cases = []
      for when_statement in expression.cases
        my_cases.push
          cond: wrap_obj when_statement[0]
          block: wrap_obj when_statement[1]
      expression.cases = my_cases
    name = expression.constructor.name
    if name == 'Obj'
      expression.objects = undefined
    if name && name != 'Array' && name != "String" && name != "Object"
      obj = {}
      obj[name] = expression
      obj
    else
      expression
  
  handle_data = (data) ->
    expressions = CoffeeScript.nodes(data).expressions
    console.log JSON.stringify wrap(expressions), null, "  "
    
  return handle_data
