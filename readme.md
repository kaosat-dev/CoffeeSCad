![Coffeescad v0_3_preview](https://raw.github.com/kaosat-dev/CoffeeSCad/dev/coffeescad_v0.3.0_pre.png)

CoffeeSCad
=============

Browser based 3D solid CAD editor, Openscad style, with a Coffeescript based syntax, using only Coffeescript + Javascript

For now it is in an early experimental stage.
live demo here : http://kaosat-dev.github.com/CoffeeSCad/

Feedback, bug reports, ideas and contributions are welcome !

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

 **A** : At this stage, this is nothing but an **early** prototype, so expect things to change a lot for now
 (but I try to keep breaking changes to the scripting itself to a minimum)
 
- **Q** : I am a developper, where is the "meat" of the code ?

 **A** In the *dev branch* , in the src folder
 
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
