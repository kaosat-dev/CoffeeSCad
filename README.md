![Coffeescad v0_3_preview](https://raw.github.com/kaosat-dev/CoffeeSCad/dev/coffeescad_v0.3.0_pre.png)

# THIS PROJECT IS DISCONTINUED !! 
## While I still love the Coffeescript syntax, I only use ES6/ES2015 these days. If you want an up to date, open source browser based cad, please try OpenJSCAD (https://github.com/jscad)
## it is more up to date, and has more features. (I am also an active developper of that project :)

More information about the end of the project: I stopped developing Coffeescad for multiple reasons:
- when I hit the limitations of Coffeescript vs Javascript when dealing with code tracing, analysis and generation with tools like Esprima, Estraverse, etc: This was going to be used to allow visual<=>code selection & editing (select something in the 3d view to select the code that defines it etc).
- I have come to dislike 'Object oriented' code more and more over the past few years, leaning more and more towards simple functions, and all the fantastic possibilities AND simplicity of 'functional' programming.
- Coffeescad was my first serious 'web' based project, things have evolved a lot in the past few years, and so has my knowledge, I would not have made the same choices today 



CoffeeSCad
=============

Browser based 3D solid CAD editor, Openscad style, with a Coffeescript based syntax, using only Coffeescript + Javascript

For now it is in an early experimental stage.

You can find:

 the **old (v0.2)** live demo here : http://kaosat-dev.github.com/CoffeeSCad/
 
 the **new (v0.3+)** live demo here http://coffeescad.net/online/ (this gets regularly updated, and is the final home of CoffeeSCad)


Feedback, bug reports, ideas and contributions are welcome !



Like CoffeeSCad ? Buy me a coffee as they say :)

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=ckaos&url=https://github.com/kaosat-dev/CoffeeSCad&title=CoffeeSCad&language=&tags=github&category=software)


Status update october 7, 2013 
=============================
While it may seem that development has slowed down, (commits in this repository), it is far from being the case:
I am currently busy with some rather radical changes to CoffeeSCad's kernel and overall structure, 
and that is taking a bit long : on the menu :

Structure
- CoffeeSCad is going modular: ie instead of one monolithic application, it will be split up into multiple reusable 
modules: this means that if you are a developer you could mix and match components and create additional
functionality easily , or even create a custom version of CoffeeSCad that fits your needs.

On the features side:
- support for importing geometry from a LOT of formats (stl, amf, obj etc)
- support for including both code and geometry from different locations (local, remote via http/https)
- moving to THREE.js library for not just visual representation
- support for splines & bezier curves via the above mentionned lib
- support for different types of extrusion (long overdue)
- a cleaned up, coherent kernel, that works in the browser , in node.js and on desktop
- LOTS of optimizations and bugfixes
- a lot coherent module system (modules are the files containing the code): this not only concerns how things are done internally, but also error reporting, "include" statements etc
- ground work for slicing integration
- ground work for material definitions
- ground work for visual to code and code to visual

And I am surely forgetting a few things !

Given the amount of changes and improvements, this might take a bit to trickle up to the online version, 
but I am doing my best to keep the wait short !

Cheers !


Important notes regarding browser storage:
=========================================

Recently github changed their pages domain to **".io"** instead of **".com"** (https://github.com/blog/1452-new-github-pages-domain-github-io), and since the localstorage system used to store CoffeeSCad's
data is based on domain , it made them inaccessible!

The files are salvageable however! Here is how you can get your data back, even if it is a tad complicated
- you need to find your browser's **localstorage** folder 
- for google chrome, under linux it is under **/home/USERNAME/.config/google-chrome/Local Storage** 
- find a file called "http_kaosat-dev.github.com_0.localstorage" (or similar) (note that it has the old github adress)
- this is an sqlite3 database that you can open (I use http://sqlitebrowser.sourceforge.net/) 
- if you go to "browse data" inside the program above , there is your data :)

This is really clunky, so sorry again.

In the future it would be much better to use the (newer) version of Coffeescad at 
http://coffeescad.net/online/

That domain will not change so you should be safe, and the newer version also allows you to store data via dropbox as a failsafe.



Contributors
=============
Derrick Oswald
Jim Wygralak


Features
=============
- **parametric editing** in your browser
- **coffeescript syntax**
- **full featured code editor**: *line counts*, syntax coloring, block folding, undo redo etc
- a limited possibility of **"real time" visualisation** of the coffeescad code: type your code, watch the shapes changes!
this is mainly limited by the speed of your machine and the complexity of the csg objects your are working on: beyond a certain complexity
it is not necessarly the best option.
- **automatic bill of materials** generation with json export
- **stl export**
- **optional online storage** using Dropbox


Future Features
===============
- faster visualization and processing 
- desktop version
- better ui 


Dependencies 
=============

	These are all included , no need to re-add them
	
	
[require.js](http://requirejs.org/)

[jquery](http://jquery.com/)

[underscore.js](http://underscorejs.org/)

[backbone.js](http://backbonejs.org/)

[backbone.marionette](http://marionettejs.com/)

[three.js](https://github.com/mrdoob/three.js/)

[coffeescript.js](http://coffeescript.org/)

[twitter bootstrap](http://twitter.github.com/bootstrap/)

[codemirror](http://codemirror.net/)

[jquery-ui](http://jqueryui.com/)

[dropbox-js](https://github.com/dropbox/dropbox-js)
	

Q&A
=============
- **Q** : Why CoffeeScript based?

 **A** : For its clear and simple syntax , mostly: even Openscad code can get messy quite fast, so anything that
can get rid of a lot of curly braces etc is a good fit

- **Q** : Why is it using so many librairies?

 **A** : I have been guilty way too many times of "reinventing the wheel", now I have too little time for that :) 
 
- **Q** : The code is changing a lot, can I use it right now?

 **A** : At this stage, this is nothing but an **early** prototype, so expect things to change , but the overall structure of the app
 is relatively stable, and I try to keep breaking changes to the scripting itself to a minimum.
 
- **Q** : I am a developper, where is the "meat" of the code ?

 **A** In the *dev branch* , in the src folder: you have the **app** and **test** folder for the app itself and unit tests
 The app is organized in a logical and modular way: 
   - you have the application core (core folder)
   - **editors** one folder per widget/modular sub app : code editor, visual editor etc
   - **exporters** one folder per widget/modular sub app for file import/exports only
   - **stores** one folder per storage type: for now dropbox and browser storage are functionnal
 
- **Q** : Can I try CoffeeScad locally ?

 **A** Sure !  If you want to contribute/play around with newer versions locally
 you can use the included CakeFile : 
 - after installing the depencies : type: "npm install -d" to Install the dependencies from the package.json file
 - on Windows rename the Cakefile.windows to Cakefile: "ren Cakefile Cakefile.linux" and "ren Cakefile.windows Cakefile"
 - you need to first at least copy the template files, just type cake cpTemplates from the root folder
   or alternatively compile all the files and copy the templates by typing cake build from the root folder
 - just type cake serveWatch from the root folder to watch/compile the files and launch a small webserver
 - you can then go to  http://127.0.0.1:8090/ in your browser to use the dev version of CoffeeSCad
 
 
Inspiration
=============
- openscad 
- openjscad (coffeescad was originally based on OpenJSCad but became an independant fork along the way and is not compatible with it anymore)
- a lot of webgl demos & tutorials
	- many of the Three.js demos
	- http://workshop.chromeexperiments.com/machines/
	- learning Three.js
- a lot more stuff

Disclaimer
=============
I am not a professionnal js/coffeescript dev. And I do this project for fun, learning, and to have an alternative to Openscad
that has a few features that I required for various Reprap oriented projects: (and that have been discussed a lot lately
in the reprap community)
 - object oriented
 - better code editor (copy, paste, linenumbers etc)
 - etc ?

Licence
=============
MIT licence
