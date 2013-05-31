import os
import zipfile
import logging
import time
import argparse
import shutil

#Dependencies: 
#sudo pip install CoffeeScript
#sudo pip install watchdog
#not sure about these below, cannot confirm their independance of nodejs
#sudo pip install lesscss-python
#sudo pip install lesscss

class Build(object):
    def __init__(self):
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger("BuildTool")
        self.targetDir = "../"
    
    def parseArgs(self):
        parser = argparse.ArgumentParser(description='Build tool for ....')
        parser.add_argument('--package', action='store_true', default=False, help='package the application (for node webkit)')
        parser.add_argument('--watch', action='store_true', default=False, help='watch for change and recompile')
    
        args = parser.parse_args()
        
        if args.package:
            self.packageApp()
        if args.watch:
            self.watchSource()
        
    def zipdir(self, path, zip):
        pathBase = os.path.basename(path)
        for root, dirs, files in os.walk(path):
            for file in files:
                src = os.path.join(root, file)
                dst = pathBase + src.replace(path, "")
                zip.write(src, dst)
                
    def zipFile(self, path, zip):
        zip.write(path, os.path.basename(path))
        
    def packageApp(self):
        self.logger.info('Packaging app for node webkit')
        curPath = os.path.dirname(os.path.realpath(__file__))
        
        packagePath = os.path.join(curPath, self.targetDir, "CoffeeSCad.nw")
        zip = zipfile.ZipFile(packagePath, 'w')
        
        dirsList = ['app','assets']
        for dirName in dirsList:
            dirPath = os.path.join(curPath, self.targetDir, dirName)
            self.zipdir(os.path.abspath(dirPath), zip)
            
        filesList = ['index.html', 'favicon.ico', 'package.json']
        for fileName in filesList:
            filePath = os.path.join(curPath, self.targetDir, fileName)
            self.zipFile(os.path.abspath(filePath), zip)
            
        zip.close()
        self.logger.info('DONE Packaging app for node webkit')
    
    def copyTemplate(self, filePath , sourceFolder, destFolder):
        fileName = os.path.basename(filePath)
        srcDir = os.path.dirname(filePath)
        print("filename", fileName, "srcDir",srcDir)
        
        destDir = srcDir.split(os.path.sep)
        if sourceFolder in destDir:
            sourceIndex = destDir.index(sourceFolder)
            destDir[sourceIndex-1]=destFolder
            destDir = os.path.sep.join(destDir[(sourceIndex-1):])
            
            destPath = os.path.join(destDir, fileName)
            print("destDir", destDir, "destPath",destPath)
            #shutil.copy(filePath, destPath)
    
    def compileCoffee(self, filePath):
        import coffeescript
        with open(filePath,'r') as fileHandler:
            fileContent = "".join(fileHandler.readlines())
            print("coffee file content", fileContent)
            result = coffeescript.compile(fileContent)
            print("Compile result" ,result)
            #with open()
        
    def watchSource(self):
        import watchdog
        from watchdog.observers import Observer
        from watchdog.events import LoggingEventHandler
        
        
        class WatcherEventHandler(watchdog.events.RegexMatchingEventHandler):
          """Handle the different events."""
          
          def __init__(self, regexes=[r".*js", r".*coffee", r".*tmpl"], ignore_regexes=[],
               ignore_directories=False, case_sensitive=False):
              super(WatcherEventHandler,self).__init__(regexes, ignore_regexes, ignore_directories, case_sensitive)
          
          def on_moved(self, event):
            super(WatcherEventHandler, self).on_moved(event)
            
            
            what = 'directory' if event.is_directory else 'file'
            logging.info("Moved %s: from %s to %s", what, event.src_path,
                         event.dest_path)
        
          def on_created(self, event):
            super(WatcherEventHandler, self).on_created(event)
        
            what = 'directory' if event.is_directory else 'file'
            logging.info("Created %s: %s", what, event.src_path)
            if what is 'file':
                if os.path.splitext(event.src_path)[1] is "coffee":
                    print("ooh my, a move of ", event.src_path)
                    self.compileCoffee(event.src_path)
        
          def on_deleted(self, event):
            super(WatcherEventHandler, self).on_deleted(event)
        
            what = 'directory' if event.is_directory else 'file'
            logging.info("Deleted %s: %s", what, event.src_path)
        
          def on_modified(self, event):
            super(WatcherEventHandler, self).on_modified(event)
        
            what = 'directory' if event.is_directory else 'file'
            logging.info("Modified %s: %s", what, event.src_path)
            if what is 'file':
                ext = os.path.splitext(event.src_path)[1]
                print ("file ", ext)
                if ext == ".coffee":
                    print("ooh my, a move of ", event.src_path)
                    self.compileCoffee(event.src_path)
                elif ext == ".tmpl":
                    self.copyTemplate(event.src_path,"src" "app")
        
        
        self.logger.info('Watching app structure for changes')
        logging.basicConfig(level=logging.INFO,
                        format='%(asctime)s - %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
        path= "../app"
        event_handler = WatcherEventHandler()
        event_handler.compileCoffee = self.compileCoffee
        event_handler.copyTemplate = self.copyTemplate
        
        observer = Observer()
        observer.schedule(event_handler, path, recursive=True)
        observer.start()
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            observer.stop()
        observer.join()
        self.logger.info('DONE Watching app structure for changes')
    
    def run(self):
        self.parseArgs()
    
if __name__ == '__main__':
    build = Build()
    build.run()
    
    



