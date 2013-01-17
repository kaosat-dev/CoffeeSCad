function anonymous() {
var Thinga, WobblyBobbly, thinga1, thinga2, wobble, wobble2, wobble3,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

console.log(toto);

try {
  console.log(options.toto);
} catch (error) {
  console.log("options.toto does not work");
}

try {
  console.log(toto);
} catch (error) {
  console.log("toto does not work");
}

Thinga = (function(_super) {

  __extends(Thinga, _super);

  function Thinga(options) {
    var c;
    Thinga.__super__.constructor.call(this, options);
    this.cb = new Cube({
      size: [50, 100, 50]
    });
    c = new Cylinder({
      h: 300,
      r: 20
    }).color([0.8, 0.5, 0.2]);
    this.union(this.cb.color([0.2, 0.8, 0.5]));
    this.subtract(c.translate([10, 0, -150]));
  }

  return Thinga;

})(Part);

WobblyBobbly = (function(_super) {

  __extends(WobblyBobbly, _super);

  function WobblyBobbly(options) {
    var defaults;
    defaults = {
      pos: [0, 0, 0],
      rot: [0, 0, 0]
    };
    options = merge(defaults, options);
    this.pos = options.pos, this.rot = options.rot;
    WobblyBobbly.__super__.constructor.call(this, options);
    this.union(new Cube({
      size: [50, 100, 50],
      center: this.pos
    }).rotate(this.rot));
  }

  return WobblyBobbly;

})(Part);

thinga1 = new Thinga();

thinga2 = new Thinga();

project.add(thinga1.translate([-150, 0, 0]));

wobble = new WobblyBobbly({
  rot: [5, 25, 150],
  pos: [-100, 150, 10]
});

wobble2 = new WobblyBobbly({
  pos: [0, 10, 20]
});

wobble3 = new WobblyBobbly({
  pos: [-100, 10, 20]
});

project.add(wobble);

project.add(wobble2);

project.add(wobble3);
return main({toto:24});
} 