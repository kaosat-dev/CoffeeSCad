# Create an intermediate language that is easy to parse and step-debug.

# Example usage:
#  coffee nodes_to_json.coffee test/binary_search.coffee | coffee builder.coffee -
#

handle_data = (data) ->
  program = JSON.parse data
  transcompile(program)
  

data = []

transcompile = (program) ->
  data = []
  for stmt in program
    Build stmt

  data.join('\n')

Build = (ast) ->
  name = the_key_of(ast)

  if name == 'expressions'
      method = AST.Block
    else
      method = AST[name]

  if method
    node = ast[name]
    return method node

  console.log ast
  throw "#{name} not supported yet"

TAB = ''

PUT = (s, f) ->
  if window?
      data.push(TAB + s)
  else
      console.log TAB, s

  if f
    INDENT()
    f()
    DEDENT()

INDENT = -> TAB += '  '
DEDENT = -> TAB = TAB[0...TAB.length - 2]

AST =
  Arr: (ast) ->
    PUT "ARR", ->
      for object in ast.objects
        Build object

  Assign: (ast) ->
    context = ast.context || '='

    PUT "ASSIGN #{context}", ->
      Build ast.variable
      Build ast.value
    return

  Block: (ast) ->
    code = ast.expressions
    code ?= ast

    for stmt in code
      Build stmt
    
  Call: (ast) ->
    if ast.isSuper
      PUT "SUPER", ->
        PUT "ARGS", ->
          for arg in ast.args
            Build arg
    else
      stmt = if ast.isNew
        "NEW"
      else
        "CALL"
      PUT stmt, ->
        Build ast.variable
        PUT "ARGS", ->
          for arg in ast.args
            Build arg
      
  Class: (ast) ->
    class_name = ast.variable.Value.base.Literal.value
    PUT "CLASS", ->
      PUT class_name

      PUT "PARENTS", ->
        if ast.parent
          Build ast.parent

      # slightly broken, trying to lump properties together, and
      # skipping over other statements for now
      methods = []
      expressions = ast.body.Block.expressions
      for expression in expressions
        if expression.Value
          for method in expression.Value.base.Obj.properties
            methods.push method

      PUT "METHODS", ->
        for method in methods
          PUT method.Assign.variable.Value.base.Literal.value
          Build method.Assign.value
    return
    
  Code: (ast) ->
    name = if ast.bound
      'BOUND_CODE'
    else
      'CODE'
    PUT name, ->
      PUT 'PARAMS', ->
        for param in ast.params
          param = param.Param
          if param.name.Literal
            name = param.name.Literal.value
            autoassign = false
          else
            name = "#{param.name.Value.properties[0].Access.name.Literal.value}"
            autoassign = true
          if param.splat
            name += "..."
          PUT "PARAM", ->
            PUT name
            PUT "FEATURES", ->
              PUT "autoassign" if autoassign
            if param.value
              Build param.value
      PUT "DO", ->
        Build ast.body

  Existence: (ast) ->
    PUT "EXISTENCE", ->
      Build ast.expression

  For: (ast) ->
    if ast.object
      PUT "FOR_OF", ->
        PUT "VARS", ->
          PUT ast.index.Literal.value
          PUT ast.name.Literal.value if ast.name
        Build ast.source
        PUT "DO", ->
          Build ast.body
    else
      PUT "FOR_IN", ->
        if ast.name.Literal
          PUT ast.name.Literal.value
        else
          PUT "Punting on arrays for now"
        Build ast.source
        PUT "DO", ->
          Build ast.body
      
  If: (ast) ->
    PUT "IF", ->
      PUT "COND", ->
        Build ast.condition
      PUT "DO", ->
        Build ast.body
      if ast.elseBody
        PUT "DO", ->
          Build ast.elseBody
    return
    
  In: (ast) ->
    name = if ast.negated
      "NOT_IN"
    else
      "IN"
    PUT name, ->
      Build ast.object
      Build ast.array
    
  Literal: (ast) ->
    value = ast.value
    literal = ->
      if value == 'false' || value == 'true' || value == 'undefined' || value == 'undefined'
        return PUT "VALUE #{value}"
      if value == 'break'
        return PUT "BREAK"
      if value == 'continue'
        return PUT "CONTINUE"
      c = value.charAt(0)
      if c == "'" || c == '"'
        return PUT "STRING #{value}"
      if value.match(/\d+/) != null
        float = parseFloat(value)
        return PUT "NUMBER #{float}"
      if value.charAt(0) == '/'
        return PUT "REGEX #{value}"
      PUT "EVAL #{value}"
    literal()
       
  Obj: (ast) ->
    PUT "OBJ", ->
      for property in ast.properties
        if property.Assign
          name = property.Assign.variable.Value.base.Literal.value
          PUT "KEY_VALUE", ->
            PUT name
            Build property.Assign.value
        else
          PUT "KEY", ->
            Build property

  Op: (ast) ->
    is_chainable = (op) ->
      op in ['<', '>', '>=', '<=', '===', '!==']
    
    op = ast.operator
    
    if op == '++'
      if ast.flip
        PUT "INCR_POST", ->
          Build ast.first
      else
        PUT "INCR_PRE", ->
          Build ast.first
      return
    if op == '--'
      if ast.flip
        PUT "DECR_POST", ->
          Build ast.first
      else
        PUT "DECR_PRE", ->
          Build ast.first
      return
    
    if op == 'new'
      class_name = ast.first.Value.base.Literal.value
      PUT "NEW_BARE", ->
        PUT class_name
      return
    
    if ast.second
      if is_chainable(op) && the_key_of(ast.first) == "Op" && is_chainable(ast.first.Op.operator)
        PUT "OP_BINARY &&", ->
          Build ast.first
          PUT "OP_BINARY #{op}", ->
            Build ast.first.Op.second
            Build ast.second
        return
          
      PUT "OP_BINARY #{op}", ->
        Build ast.first
        Build ast.second
      return
    else
      PUT "OP_UNARY #{op}", ->
        Build ast.first
      return
    throw "unknown op #{op}"

  Parens: (ast) ->
    body = ast.body
    if body.Block?
      body = body.Block
    if body.expressions
      PUT "PARENS", ->
        return Build body
    else
      return Build body

  Range: (ast) ->
    if ast.exclusive
      stmt = "RANGE_EXCLUSIVE"
    else
      stmt = "RANGE_INCLUSIVE"
    PUT stmt, ->
      if ast.from
        Build ast.from
      else
        PUT "LITERAL 0"
      if ast.to
        Build ast.to

  Return: (ast) ->
    PUT "RETURN", ->
      if ast.expression
        Build ast.expression
      else
        PUT "VALUE undefined"

  Splat: (ast) ->
    PUT "SPLAT", ->
      Build ast.name

  Switch: (ast) ->
    PUT "SWITCH", ->
      Build ast.subject
      for case_ast in ast.cases
        PUT "CASE", ->
          Build case_ast.cond
          Build case_ast.block
      if ast.otherwise
        PUT "OTHERWISE", ->
          Build ast.otherwise
    
  Throw: (ast) ->
    PUT "THROW", ->
      Build ast.expression
    
  Try: (ast) ->
    PUT "TRY", ->
      PUT "DO", ->
        Build ast.attempt
      PUT "CATCH", ->
        catch_var = ast.error.Literal.value
        PUT catch_var
        Build ast.recovery
      if ast.ensure
        PUT "FINALLY", ->
          Build ast.ensure
      
  Value: (ast) ->
    if ast.properties.length == 0
      Build ast.base
    else
      properties = ast.properties
      last_property = properties[properties.length - 1]   
      priors = properties.slice(0, properties.length - 1)
      
      prior = -> AST.Value
          base: ast.base
          properties: priors
      if last_property.Access?
        name = if last_property.Access.soak
          "ACCESS_SOAK"
        else
          "ACCESS"
          
        PUT name, ->
          if last_property.Access.proto
            PUT "PROTO", ->
              prior()
          else
            prior()
          PUT last_property.Access.name.Literal.value
      else if last_property.Index?
        PUT "INDEX", ->
          prior()
          Build last_property.Index.index
      else if last_property.Slice?
        PUT "SLICE", ->
          prior()
          Build last_property.Slice.range
      else
        throw "yo"
      return

  While: (ast) ->
    PUT "WHILE", ->
      PUT "COND", ->
        Build ast.condition
      PUT "DO", ->
        Build ast.body

the_key_of = (ast) ->
  # there is just one key
  for key of ast
    return key
      
pp = (obj, description) ->
  util = require 'util'
  util.debug "-----"
  util.debug description if description?
  util.debug JSON.stringify obj, null, "  "

if window?
  window.CoffeeCoffee.transcompile = transcompile
else
  # assume we're running node side for now
  fs = require 'fs'
  [fn] = process.argv.splice 2, 1
  if fn == '-'
    data = ''
    stdin = process.openStdin()
    stdin.on 'data', (buffer) ->
      data += buffer.toString() if buffer
    stdin.on 'end', ->
      handle_data(data)
  else
    data = fs.readFileSync(fn).toString()
    handle_data(data)