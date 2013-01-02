fs            = require 'fs'
{spawn, exec} = require 'child_process'
path          = require 'path'
findit        = require 'findit'
util          = require 'util'
glob          = require 'glob'
{print}       = require 'sys'
mkdirp        = require 'mkdirp'
watcher       = require 'watch-tree-maintained'

requirejs = require 'requirejs'
requirejs.config
  baseUrl: './build/js',
  nodeRequire: require
global.define = require('requirejs');

SRCDIR="./src"
TGTDIR="."
 
find_all = (srcdir, src_prefix) ->
  
mkr = (r) -> new RegExp r.replace /\./, '\\.'

twoDigits = (val) ->
  if val < 10 then return "0#{val}" 
  return val

#######################################

build = (src_extension, targ_extension, command, options) ->
    findit.find(SRCDIR).on 'file', (source, stats) ->
        if path.extname(source) == src_extension
            source_path = path.dirname(source)
            source_file = path.basename(source)
            target_path = source_path.replace(mkr('^' + SRCDIR), TGTDIR)
            target      = path.join(target_path, source_file)
            target_file = path.basename(target)
            fs.mkdir target_path, '0755', (err) ->
                if err and err.code != 'EEXIST'
                    throw err
            cmd = command.replace(/\$source/, source)
                .replace(/\$target_path/, target_path)
                .replace(/\$source_path/, source_path)
                .replace(/\$target_file/, target_file)
                .replace(/\$source_file/, source_file)
                .replace(/\$target/, target)
            exec cmd, (error, stderr, stdout) ->
                if error
                    throw source + ' ' + error
                if options.verbose
                    console.log(stdout)
                if stderr
                    console.log(stderr)


copyTemplate = (src_path)->
  file = src_path
  rootdir = file.split(path.sep)[0]
  if rootdir == "src"
    fileName = path.basename(file)
    splitPath = file.split(path.sep)
    outPath = splitPath[1..splitPath.length-2].join(path.sep)
    
    splitBase = __filename.split(path.sep)
    basePath = splitBase[0..splitBase.length-2].join(path.sep)
    
    inPath = basePath+path.sep+file
    outPath = basePath+path.sep+ outPath+"/"
    #print "Copying #{inPath} to #{outPath}\n\n"
    
    mkdirp outPath, '0755', (err) ->
      if err and err.code != 'EEXIST'
          throw err
      outPath = outPath+ fileName
      cp = spawn 'cp', [inPath, outPath]
      cp.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
      cp.stdout.on 'data', (data) ->
        util.log data.toString()
      ts = new Date()
      ts = "#{twoDigits(ts.getHours())}:#{twoDigits(ts.getMinutes())}:#{twoDigits(ts.getSeconds())}"
      print("#{ts} - copied #{src_path}\n")

deleteTemplate = (src_path)->
  file = src_path
  rootdir = file.split(path.sep)[0]
  fileName = path.basename(file)
  splitPath = file.split(path.sep)
  outPath = splitPath[1..splitPath.length-2].join(path.sep)
  
  splitBase = __filename.split(path.sep)
  basePath = splitBase[0..splitBase.length-2].join(path.sep)
  
  inPath = basePath+path.sep+file
  outPath = basePath+path.sep+ outPath+"/"+ fileName
  fs.unlink outPath,  (err) ->
    if (err) then throw err
    ts = new Date()
    ts = "#{twoDigits(ts.getHours())}:#{twoDigits(ts.getMinutes())}:#{twoDigits(ts.getSeconds())}"
    print("#{ts} - deleted #{src_path}\n")
  
    

task 'test', 'run unit tests',(options) ->
  exec('jasmine-node --coffee --verbose ./src/test/spec/editors', (err, stdout, stderr) ->
        if err
            process.stderr.write(stderr)
        else
            process.stdout.write(stdout)
    )

task 'docs', 'generate api documentation', (options) ->
  #coffeedoc = spawn 'coffeedoc' , []
  exec "coffeedoc --output ./doc/api --parser commonjs ./src/app"
  
task 'watch', 'Watch src/ for changes',(options) ->
  coffee = spawn 'coffee', ['-w', '-c', '-o', TGTDIR, SRCDIR]
  #watchTree's match does not work correctly for newly created files hence the hacks below
  watcher = watcher.watchTree("src", {'sample-rate': 2})#,'match':'(.*)[.]tmpl'})
  
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  watcher.on 'filePreexisted', (srcPath,stats)->
    if path.extname(srcPath) == ".tmpl"
      copyTemplate(srcPath)
  watcher.on 'fileCreated', (srcPath, stats) ->
    if path.extname(srcPath) == ".tmpl"
      copyTemplate(srcPath)
  watcher.on 'fileModified', (srcPath, stats) ->
    if path.extname(srcPath) == ".tmpl"
      copyTemplate(srcPath)
  watcher.on 'fileDeleted', (srcPath) ->
    if path.extname(srcPath) == ".tmpl"
      deleteTemplate(srcPath)

task 'cpTemplates', 'Copy all templates into the correct folders', ->
  glob "**/*.tmpl", null, (er, files) ->
    for file in files
      copyTemplate(file)
      ### 
      rootdir = file.split(path.sep)[0]
      if rootdir == "src"
        fileName = path.basename(file)
        splitPath = file.split(path.sep)
        outPath = splitPath[1..splitPath.length-2].join(path.sep)
        
        splitBase = __filename.split(path.sep)
        basePath = splitBase[0..splitBase.length-2].join(path.sep)
        
        inPath = basePath+path.sep+file
        outPath = basePath+path.sep+ outPath+"/"
        print "Copying #{inPath} to #{outPath}\n\n"
        
        mkdirp outPath, '0755', (err) ->
          if err and err.code != 'EEXIST'
              throw err
        outPath=outPath+ fileName
        cp = spawn 'cp', [inPath, outPath]
        cp.stderr.on 'data', (data) ->
          process.stderr.write data.toString()
        cp.stdout.on 'data', (data) ->
          util.log data.toString()
      ###  
task 'build', 'build all the components', (options) ->
  build '.coffee', '.js', 'coffee --compile --lint -o $target_path $source', options
  build '.less', '.css', 'lessc $source $target', options
  
task 'release', 'build, minify , prep for release' , (options) ->
  c = {baseUrl: 'app'
      ,name:    'main.max'
      ,out:     'build/app/main.min.js'
      ,optimize:'uglify'}
  requirejs.optimize(c, console.log)
