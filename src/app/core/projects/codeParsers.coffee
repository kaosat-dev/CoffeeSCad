define (require) ->
  coffeescript = require 'CoffeeScript'
  helpers = require './helpers'
  ###
  Syntax tree parsers #taken from coffeedoc
  ===================
  
  These classes provide provide methods for extracting classes and functions from
  the CoffeeScript AST. Each parser class is specific to a module loading system
  (e.g.  CommonJS, RequireJS), and should implement the `getDependencies`,
  `getClasses` and `getFunctions` methods. Parsers are selected via command line
  option.
  ###
  class BaseParser
      ###
      This base class defines the interface for parsers. Subclasses should
      implement these methods.
      ###
      getNodes: (script) ->
          ###
          Generates the AST from coffeescript source code.  Adds a 'type' attribute
          to each node containing the name of the node's constructor, and returns
          the expressions array
          ###
          tokens = coffeescript.tokens(script)
          
          rootNode = coffeescript.nodes(tokens)
          rootNode.traverseChildren false, (node) ->
              node.type = node.constructor.name
          return [].concat(rootNode.expressions, rootNode)
  
  
  class RequireJSParser extends BaseParser
      getNodes: (script) ->
          nodes = super(script)
          result_nodes = []
          moduleLdrs = ['define', 'require']
          for root_node in nodes
              root_node.traverseChildren false, (node) ->
                  node.type = node.constructor.name
                  node.level = 1
                  if node.type is 'Call' and node.variable.base.value in moduleLdrs
                      for arg in node.args
                          if arg.constructor.name is 'Code'
                              arg.body.traverseChildren false, (node) ->
                                  node.type = node.constructor.name
                                  node.level = 2
                              result_nodes = result_nodes.concat(arg.body.expressions)
                          # TODO: Support objects passed to require or define
          return nodes.concat(result_nodes)
  
      _parseCall: (node, deps) ->
          ### Parse require([], ->) and define([], ->) ###
          mods = []
          args = []
  
          for arg in node.args
              val1 = helpers.getAttr(arg, 'base')
              val2 = helpers.getAttr(arg, 'base.body.expressions[0]')
              if val1.type is 'Arr'
                  mods = this._parseModuleArray(val1)
              else if val2.type is 'Code'
                  args = this._parseFuncArgs(val2)
              else if arg.type is 'Code'
                  args = this._parseFuncArgs(arg)
  
          this._matchArgs(deps, mods, args)
  
      _parseAssign: (node, deps) ->
          ### Parse module = require("path/to/module") ###
          arg = node.value.args[0]
          module_path = this._getModulePath(arg)
          if module_path?
              local_name = helpers.getFullName(node.variable)
              deps[local_name] = module_path
  
      _parseObject: (node, deps) ->
          ### Parse require = {} ###
          obj = node.value.base
          mods = []
          args = []
          for attr in obj.properties
              name = helpers.getAttr(attr, 'variable.base.value')
              val1 = helpers.getAttr(attr, 'value.base')
              val2 = helpers.getAttr(attr, 'value.base.body.expressions[0]')
              if name is 'deps' and val1.type is 'Arr'
                  mods = this._parseModuleArray(val1)
              else if name is 'callback'
                  if val2.type is 'Code'
                      args = this._parseFuncArgs(val2)
                  else if attr.value.type is 'Code'
                      args = this._parseFuncArgs(attr.value)
  
          this._matchArgs(deps, mods, args)
  
      _matchArgs: (deps, mods, args) ->
          ###
          Match the list of modules to the list of local variable names and
          add them to the dependencies object given.
          ###
          index = 0
          for mod in mods
              local_name = if index < args.length then args[index] else mod
              deps[local_name] = mod
              index += 1
  
      _stripQuotes: (str) ->
          return str?.replace(/('|\")/g, '')
  
      _parseFuncArgs: (func) ->
          ###
          Given a node of type 'Code', gathers the names of each of the function
          arguments and return them in an array.
          ###
          args = []
          for arg in func.params
              args.push(arg.name.value)
          return args
  
      _parseModuleArray: (arr) ->
          ###
          Given a node of type 'Arr', gathers the module paths represented by
          each object in the array and returns them in an array.
          ###
          modules = []
          for module in arr.objects
              mod_path = this._getModulePath(module)
              if mod_path?
                  modules.push(mod_path)
          return modules
  
      _getModulePath: (mod) ->
          if mod.type is 'Value'
              return this._stripQuotes(mod.base.value)
          else if mod.type is 'Op' and mod.operator is '+'
              return '.' + this._stripQuotes(mod.second.base.value)
          return null
  
      getDependencies: (nodes) ->
          ###
          This currently works with the following `require` calls:
  
              local_name = require("path/to/module")
              local_name = require(__dirname + "/path/to/module")
  
          The following `require` object assignments:
  
              require = {deps: ["path/to/module"]}
              require = {deps: ["path/to/module"], callback: (module) ->}
  
          And the following `require` and `define` calls:
  
              require(["path/to/module"], (module) -> ...)
              require({}, ["path/to/module"], (module) -> ...)
              define(["path/to/module"], (module) -> ...)
              define('', ["path/to/module"], (module) -> ...)
  
          ###
          deps = {}
          for n in nodes
              if n.type is 'Call' and n.variable.base.value in ['define', 'require']
                  this._parseCall(n, deps)
              else if n.type is 'Assign'
                  if n.value.type is 'Call' and n.value.variable.base.value is 'require'
                      this._parseAssign(n, deps)
                  else if (n.level is 1 and n.variable.base.value is 'require' \
                           and n.value.base.type is 'Obj')
                      this._parseObject(n, deps)
          return deps
  
      getClasses: (nodes) ->
          return (n for n in nodes when n.type == 'Class' \
                  or n.type == 'Assign' and n.value.type == 'Class')
  
      getObjects: (nodes) ->
          return (n for n in nodes when n.type == 'Assign' \
                  and helpers.getAttr(n, 'value.base').type == 'Obj')
  
      getFunctions: (nodes) ->
          return (n for n in nodes \
                  when n.type == 'Assign' and n.value.type == 'Code')

  return {"RequireJSParser" : RequireJSParser}