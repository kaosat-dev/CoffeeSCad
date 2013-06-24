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
                #if err and err.code != 'EEXIST'
                  
                  #console.log err
                  #throw err
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

_exec = (cmd,done)->
   exec cmd, done

compileLess = (srcPath)->
  rootdir = srcPath.split(path.sep)[0]
  
  findAndCompileBootstrapMain=(srcPath)=>
    curDirName = path.dirname(srcPath)
    files = fs.readdirSync(curDirName)
    #console.log "files",files
    if "bootstrap.less" in files
      fileName = path.basename(srcPath)
      if fileName != "bootstrap.less"
        splitPath = srcPath.split(path.sep)
        splitPath[splitPath.length-1] = "bootstrap.less"
        srcPath = splitPath.join(path.sep)
      compileBootstrapMain(srcPath,"bootstrap.less")
  
  compileBootstrapMain=(srcPath, fileName) =>
    splitPath = srcPath.split(path.sep)
    outPath = splitPath[1..splitPath.length-2].join(path.sep)
    
    splitBase = __filename.split(path.sep)
    basePath = splitBase[0..splitBase.length-2].join(path.sep)
    
    #console.log "basePath",basePath, "outPath",outPath,"fileName",fileName
    
    inPath = [basePath,srcPath].join(path.sep)
    outPath = [basePath,"assets","css",outPath,fileName.slice(0,-5)+".css"]
    outPath = outPath.join(path.sep)
    ts = new Date()
    ts = "#{twoDigits(ts.getHours())}:#{twoDigits(ts.getMinutes())}:#{twoDigits(ts.getSeconds())}"
    console.log "#{ts} - LESS : #{inPath} to #{outPath}"
    
    _exec "lessc #{inPath} #{outPath}", (e,so,se)->
      console.log "#{ts} - [lessc #{inPath} #{outPath}] OUT> #{so}" if so
      console.log "#{ts} - [lessc #{inPath} #{outPath}] ERR> #{se}" if se
  
  if rootdir == "src"
    findAndCompileBootstrapMain(srcPath)
    
    #fileName = path.basename(srcPath)
    #if fileName is "bootstrap.less"
    #  compileBootstrapMain(srcPath,"bootstrap.less")
      

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
  coffee = spawn 'coffee', ['--bare','-w', '-c', '-o', TGTDIR, SRCDIR]
  #watchTree's match does not work correctly for newly created files hence the hacks below
  watcher = watcher.watchTree("src", {'sample-rate': 2})#,'match':'(.*)[.]tmpl'})
  
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  watcher.on 'filePreexisted', (srcPath,stats)->
    if path.extname(srcPath) == ".tmpl"
      copyTemplate(srcPath)
    if path.extname(srcPath) == ".less"
      fileName = path.basename(srcPath)
      if fileName is "bootstrap.less"
        compileLess(srcPath)
  watcher.on 'fileCreated', (srcPath, stats) ->
    if path.extname(srcPath) == ".tmpl"
      copyTemplate(srcPath)
    if path.extname(srcPath) == ".less"
      compileLess(srcPath)
  watcher.on 'fileModified', (srcPath, stats) ->
    if path.extname(srcPath) == ".tmpl"
      copyTemplate(srcPath)
    if path.extname(srcPath) == ".less"
      compileLess(srcPath)
  watcher.on 'fileDeleted', (srcPath) ->
    if path.extname(srcPath) == ".tmpl"
      deleteTemplate(srcPath)

task 'serve', 'minimal web server for testing', (options) ->
  connect = require('connect')
  servePath = path.resolve('.')
  server = connect.createServer connect.static(servePath)
  console.log "Sever starting: at http://127.0.0.1:8090/"
  server.listen(8090)

task 'serveWatch', 'serve the files and run the watch task', (options) ->
  invoke('serve')
  invoke('watch')

task 'cpTemplates', 'Copy all templates into the correct folders', ->
  glob "src/**/*.tmpl", null, (er, files) ->
    for file in files
      copyTemplate(file)
      
task 'build', 'build all the components', (options) ->
  #--lint
  invoke('cpTemplates')
  build '.coffee', '.js', 'coffee --compile  -o $target_path $source', options
  build '.less', '.css', 'lessc $source $target', options
  
task 'release', 'build, minify , prep for release' , (options) ->
  
  #test buildconf for csg sub package
  buildConf = {
    baseUrl: "app",
    dir: "build",
    #mainConfigFile: "app/main.js",
    modules:[
        {
          name: "modules/core/projects/csg/csg"
        }
      ],
    optimize: "none"
  }
  
  console.log "Building, minifying"
  #full build conf
  buildConf = {
    mainConfigFile: "app/config.js",
    baseUrl: "app",
    out:     'build/main.min.js',
    name: "main",
    optimize: "none" #"uglify",
    #removeCombined:true
  }
  ###
  c = {baseUrl: 'app'
      ,name:    'main.max'
      ,out:     'build/app/main.min.js'
      ,optimize:'uglify'}###
      
  requirejs.optimize(buildConf, console.log)


task 'package_alt', 'package project for node-webkit', (options) ->
  zip = new require('node-zip')()
  
  finder = findit.find("app")
  finder.on 'file', (source, stats) =>
    console.log "file: "+ source
    if path.extname(source) == ".js"
      fs.readFile source, null, (err,data)->
        if (err) 
          return console.log(err)
        console.log(data)
        zip.file(source,data)  
    
  finder.on 'end', ()=>
    console.log "done"  
    data = zip.generate({base64:false,compression:'DEFLATE'})
    fs.writeFile('coffeescad.nw', data, 'binary');
    
  
task 'package' , 'package project for node-webkit', (options) ->
  pkgFile = 'CoffeeSCad.nw'
  zip = spawn('zip', ['-9', '-r', pkgFile, './app', './assets', 'index.html','package.json','favicon.ico','readme.md'])
  ### 
  zip.on 'exit',  (code, signal)->
    zip2 = spawn('zip', ['-9', '-r', '-g',  'toto.zip', './assets', 'index.html'])
    zip2.on 'exit', (code, signal)->
       zip3 = spawn('zip', ['-9', '-r', '-g',  'toto.zip', 'package.json'])
  ### 

 task 'parseExamples' , 'parse the examples folder, generate a json map of the folder structure', (options) ->
  examplesPath = "./examples"
  outputPath = "./examples/examples.json"
    
  dirTree2 = (filename) ->  
    stats = fs.lstatSync(filename)
    info = 
      path: filename.replace(examplesPath, "")
      name: path.basename(filename)
    if stats.isDirectory()
      isProject = false
      children = fs.readdirSync(filename)
      if children.length > 0
        files = []
        subDirs = []
        children.map((child) =>
          childPath = filename + "/" + child
          childStats = fs.lstatSync(childPath)
          if not childStats.isDirectory()
            if path.extname(childPath) == ".coffee"
              isProject=true
              files.push(child)
          else
            subDirs.push(childPath)
        )
        if files.length > 0
          info.files = files
        else if subDirs.length > 0
          info.categories = subDirs.map((subDir)=>
            dirTree2 subDir
          )
       
        if isProject
          info.type = "project"
        else
          info.type = "category"
      info
  
  fs = require("fs")
  path = require("path")
  
  
  #console.log util.inspect(dirTree2(examplesPath), false, null)
  raw = dirTree2(examplesPath)
  jsonified = JSON.stringify(raw)
  console.log raw
  console.log jsonified
  fs.writeFile(outputPath,jsonified)