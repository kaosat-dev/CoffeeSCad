function main() 
{
  var cube = CSG.cube({center: [0, 0, 0],
  radius: [10, 1, 1]});
  var sphere = CSG.sphere({radius: 10, resolution: 16}).translate([5, 5, 5]);
  return cube.union(sphere);
}