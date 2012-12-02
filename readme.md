CoffeeSCad
=============

Browser based 3D solid CAD editor, Openscad style, with a Coffeescript based syntax, using only Coffeescript + Javascript

For now it is in an early experimental stage.
live demo here : http://kaosat-dev.github.com/CoffeeSCad/

Feedback, bug reports, ideas and contributions are welcome !


CoffeeSCad was originally built on the great OpenJsCad project but is *not* compatible with it anymore at this point, although a good portion
of the cgs codebase is still the same.

Features
=============
- **parametric editing** in your browser
- **coffeescript syntax**
- **full featured code editor**: *line counts*, syntax coloring, block folding, undo redo etc
- a limited possibility of **"real time" visualisation** of the coffeescad code: type your code, watch the shapes changes!
this is mainly limited by the speed of your machine and the complexity of the csg objects your are working on: beyond a certain complexity
it is not necessarly the best option.


Future Features
===============
- share projects via github (gist)
- better ui 
- library system (I consider this absolutely essential: using other people's creations as "parts libraries" is a key
element
- better, simpler syntax
- bill of materials perhaps even "interactive" assembly guides

Dependencies 
=============
	These are all included , no need to re-add them
	- cgs.js (the modified version from openjscad)
	- require.js
	- jquery
	- underscore.js
	- backbone.js
	- three.js
	- coffeescript.js 
	- twitter bootstrap
	- codemirror
	- various backbone & jquery plugins:
		- backbone.marionette
	 	- ThreeCSG.js
		etc

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

 **A** It is in the **App/CS** (for coffeescript) folder: I am currently developping using the coffeescript "watch" feature 
 to compile the various .coffee files to js ie: 
 	after cloning the project, just go into the OpenCoffeScad folder and type **coffee -co app/ --watch app/cs**
 	(you need to have coffeescript install)
 
Inspiration
=============
- openscad 
- openjscad
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
