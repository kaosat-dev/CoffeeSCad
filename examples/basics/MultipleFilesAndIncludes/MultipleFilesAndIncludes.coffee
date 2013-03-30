#in CoffeeSCad , every project can contain multiple files (you can view it as simple one level folder with files)
#you see the files list on the left, double click on any file to open it in a new tab, or to switch to it if it was already open

#CoffeeSCad also supports "include" statements, to include the code from one file or project into another:

#here we include the file "foobar" (check its contents if you want)
include("fooBar.coffee")

#as you can see we draw the object "myCube"(a gorgeous pink cube , yes sir!) that was not defined here, but in the fooBar.coffee file
assembly.add(myCube)

#you can also include files from other projects
#for that you need to prefix the include statement with the type of storage you want to get the file from:
#includ_e ("browser:OtherProject/someFile.coffee") this will include the file "someFile" from the project OtherProject that is stored in 
#localstorage (inside your browser)

#if you have a dropbox account , and have logging in via CoffeeSCad you can do:
#includ_e ("dropbox:OtherProject/someFile.coffee") to load remote files' content into your project


