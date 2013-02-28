define (require)->
  globals = require './globals'
  _CSGDEBUG = globals._CSGDEBUG
  
  class PolygonTreeNode 
    # This class manages hierarchical splits of polygons
    # At the top is a root node which doesn hold a polygon, only child PolygonTreeNodes
    # Below that are zero or more 'top' nodes; each holds a polygon. The polygons can be in different planes 
    # splitByPlane() splits a node by a plane. If the plane intersects the polygon, two new child nodes
    # are created holding the splitted polygon.
    # getPolygons() retrieves the polygon from the tree. If for PolygonTreeNode the polygon is split but 
    # the two split parts (child nodes) are still intact, then the unsplit polygon is returned.
    # This ensures that we can safely split a polygon into many fragments. If the fragments are untouched,
    #  getPolygons() will return the original unsplit polygon instead of the fragments.
    # remove() removes a polygon from the tree. Once a polygon is removed, the parent polygons are invalidated 
    # since they are no longer intact. 
    
    constructor:->
      # constructor creates the root node:
      @parent = null
      @children = []
      @polygon = null
      @removed = false
  
    addPolygons: (polygons) ->
      # fill the tree with polygons. Should be called on the root node only; child nodes must
      # always be a derivate (split) of the parent node.
      throw new Error("Assertion failed")  unless @isRootNode() # new polygons can only be added to root node; children can only be splitted polygons
      @addChild(polygon) for polygon in polygons
    
    remove: ->
      # remove a node
      # - the siblings become toplevel nodes
      # - the parent is removed recursively
      unless @removed
        @removed = true
        if _CSGDEBUG
          throw new Error("Assertion failed")  if @isRootNode() # can't remove root node
          throw new Error("Assertion failed")  if @children.length # we shouldn't remove nodes with children
        
        # remove ourselves from the parent's children list:
        parentschildren = @parent.children
        i = parentschildren.indexOf(this)
        throw new Error("Assertion failed")  if i < 0
        parentschildren.splice i, 1
        
        # invalidate the parent's polygon, and of all parents above it:
        @parent.recursivelyInvalidatePolygon()
  
    isRemoved: ->
      @removed
  
    isRootNode: ->
      not @parent
    
    invert: ->
      # invert all polygons in the tree. Call on the root node
      throw new Error("Assertion failed")  unless @isRootNode() # can only call this on the root node
      @invertSub()
  
    getPolygon: ->
      throw new Error("Assertion failed")  unless @polygon # doesn't have a polygon, which means that it has been broken down
      @polygon
  
    getPolygons: (result) ->
      if @polygon
        
        # the polygon hasn't been broken yet. We can ignore the children and return our polygon:
        result.push @polygon
      else
        # our polygon has been split up and broken, so gather all subpolygons from the children:
        childpolygons = []
        child.getPolygons (childpolygons) for child in @children 
        result.push(polygon) for polygon in childpolygons
        
  
    splitByPlane: (plane, coplanarfrontnodes, coplanarbacknodes, frontnodes, backnodes) ->
      # split the node by a plane; add the resulting nodes to the frontnodes and backnodes array  
      # If the plane doesn't intersect the polygon, the 'this' object is added to one of the arrays
      # If the plane does intersect the polygon, two new child nodes are created for the front and back fragments,
      #  and added to both arrays.
      children = @children
      numchildren = children.length
      if numchildren > 0
        # if we have children, split the children
        child.splitByPlane(plane, coplanarfrontnodes, coplanarbacknodes, frontnodes, backnodes) for child in children
      else
        # no children. Split the polygon:
        polygon = @polygon
        if polygon
          bound = polygon.boundingSphere()
          sphereradius = bound[1] + 1e-4
          planenormal = plane.normal
          spherecenter = bound[0]
          d = planenormal.dot(spherecenter) - plane.w
          if d > sphereradius
            frontnodes.push this
          else if d < -sphereradius
            backnodes.push this
          else
            splitresult = plane.splitPolygon(polygon)
            switch splitresult.type
              when 0 # coplanar front:
                coplanarfrontnodes.push this
              when 1 # coplanar back:
                coplanarbacknodes.push this
              when 2 # front:
                frontnodes.push this
              when 3 # back:
                backnodes.push this
              when 4 # spanning:
                if splitresult.front
                  frontnode = @addChild(splitresult.front)
                  frontnodes.push frontnode
                if splitresult.back
                  backnode = @addChild(splitresult.back)
                  backnodes.push backnode
  
    # PRIVATE methods from here:
    addChild: (polygon) ->
      # add child to a node
      # this should be called whenever the polygon is split
      # a child should be created for every fragment of the split polygon 
      # returns the newly created child
      newchild = new PolygonTreeNode()
      newchild.parent = this
      newchild.polygon = polygon
      @children.push newchild
      newchild
  
    invertSub: ->
      @polygon = @polygon.flipped()  if @polygon
      child.invertSub() for child in @children 
      ###
      @children.map (child) ->
        child.invertSub()
      ###
  
    recursivelyInvalidatePolygon: ->
      if @polygon
        @polygon = null
        @parent.recursivelyInvalidatePolygon()  if @parent
        
  
  
  class Tree 
    # This is the root of a BSP tree
    # We are using this separate class for the root of the tree, to hold the PolygonTreeNode root
    # The actual tree is kept in this.rootnode
    constructor:(polygons) ->
      @polygonTree = new PolygonTreeNode()
      @rootnode = new Node(null)
      @addPolygons polygons  if polygons
  
    invert: ->
      @polygonTree.invert()
      @rootnode.invert()
    
    clipTo: (tree, alsoRemovecoplanarFront) ->
      # Remove all polygons in this BSP tree that are inside the other BSP tree
      # `tree`.
      alsoRemovecoplanarFront = (if alsoRemovecoplanarFront then true else false)
      @rootnode.clipTo tree, alsoRemovecoplanarFront
  
    allPolygons: ->
      result = []
      @polygonTree.getPolygons result
      result
  
    addPolygons: (polygons) ->
      _this = this
      polygontreenodes = polygons.map((p) ->
        _this.polygonTree.addChild p
      )
      @rootnode.addPolygonTreeNodes polygontreenodes
  
  
  class Node 
    # Holds a node in a BSP tree. A BSP tree is built from a collection of polygons
    # by picking a polygon to split along.
    # Polygons are not stored directly in the tree, but in PolygonTreeNodes, stored in
    # this.polygontreenodes. Those PolygonTreeNodes are children of the owning
    # Tree.polygonTree
    # This is not a leafy BSP tree since there is
    # no distinction between internal and leaf nodes.
    constructor: (parent) ->
      @plane = null
      @front = null
      @back = null
      @polygontreenodes = []
      @parent = parent
  
    invert: ->
      # Convert solid space to empty space and empty space to solid space.
      @plane = @plane.flipped()  if @plane
      @front.invert()  if @front
      @back.invert()  if @back
      temp = @front
      @front = @back
      @back = temp
  
    clipPolygons_recursive: (polygontreenodes, alsoRemovecoplanarFront) ->
      # clip polygontreenodes to our plane
      # calls remove() for all clipped PolygonTreeNodes
      if @plane
        backnodes = []
        frontnodes = []
        coplanarfrontnodes = (if alsoRemovecoplanarFront then backnodes else frontnodes)
        plane = @plane
        
        node.splitByPlane(plane, coplanarfrontnodes, backnodes, frontnodes, backnodes) for node in polygontreenodes when not(node.isRemoved())
        console.log "backnodes #{backnodes.length}"
        console.log "frontnodes #{frontnodes.length}"

        @front.clipPolygons_recursive frontnodes, alsoRemovecoplanarFront  if @front and (frontnodes.length > 0)
        numbacknodes = backnodes.length
        if @back and (numbacknodes > 0)
          @back.clipPolygons_recursive backnodes, alsoRemovecoplanarFront
        else
          # there's nothing behind this plane. Delete the nodes behind this plane:
          console.log "remvoving #{numbacknodes} elements"
          for i in [0...numbacknodes]
            #console.log "removing at #{i}"
            #console.log backnodes[i]
            backnodes[i].remove()
    
    @clipPolygons=(currentNode,polygontreenodes, alsoRemovecoplanarFront)->
      # clip polygontreenodes to our plane
      # calls remove() for all clipped PolygonTreeNodes
      # iterative approach to avoid too much recursion errors
      stack = []
      stack.push([currentNode,polygontreenodes])
      while stack.length > 0
        [currentNode,treeNodes] = stack.pop()
        
        if currentNode.plane
          backnodes = []
          frontnodes = []
          coplanarfrontnodes = (if alsoRemovecoplanarFront then backnodes else frontnodes)
          plane = currentNode.plane
          node.splitByPlane(plane, coplanarfrontnodes, backnodes, frontnodes, backnodes) for node in treeNodes when not(node.isRemoved())
          
          front = currentNode.front
          numFrontNodes = frontnodes.length
          if front and (numFrontNodes > 0)
            stack.push([front,frontnodes]) 
          
          back = currentNode.back
          numBackNodes = backnodes.length
          if back and (numBackNodes > 0)
            stack.push([back,backnodes])
          else
            # there's nothing behind this plane. Delete the nodes behind this plane:
            for i in [0...numBackNodes]
              backnodes[i].remove()
    
    clipTo: (tree, alsoRemovecoplanarFront) ->
      # Remove all polygons in this BSP tree that are inside the other BSP tree
      # `tree`.
      Node.clipPolygons(tree.rootnode, @polygontreenodes, alsoRemovecoplanarFront) if @polygontreenodes.length > 0
      
      @front.clipTo tree, alsoRemovecoplanarFront  if @front
      @back.clipTo tree, alsoRemovecoplanarFront  if @back
  
    clipTo_recursive: (tree, alsoRemovecoplanarFront) ->
      #WARNING: issue with too much recursion here, see above method for iterative implementation
      # Remove all polygons in this BSP tree that are inside the other BSP tree
      # `tree`.
      tree.rootnode.clipPolygons_recursive @polygontreenodes, alsoRemovecoplanarFront  if @polygontreenodes.length > 0
      @front.clipTo tree, alsoRemovecoplanarFront  if @front
      @back.clipTo tree, alsoRemovecoplanarFront  if @back
  
    addPolygonTreeNodes: (polygontreenodes) ->
      return  if polygontreenodes.length is 0
      _this = this
      unless @plane
        bestplane = polygontreenodes[0].getPolygon().plane
        #      
        #      var parentnormals = [];
        #      this.getParentPlaneNormals(parentnormals, 6);
        #//parentnormals = [];      
        #      var numparentnormals = parentnormals.length;
        #      var minmaxnormal = 1.0;
        #      polygontreenodes.map(function(polygontreenode){
        #        var plane = polygontreenodes[0].getPolygon().plane;
        #        var planenormal = plane.normal;
        #        var maxnormaldot = -1.0;
        #        parentnormals.map(function(parentnormal){
        #          var dot = parentnormal.dot(planenormal);
        #          if(dot > maxnormaldot) maxnormaldot = dot;  
        #        });
        #        if(maxnormaldot < minmaxnormal)
        #        {
        #          minmaxnormal = maxnormaldot;
        #          bestplane = plane;
        #        }
        #      });
        #
        @plane = bestplane
      frontnodes = []
      backnodes = []
      polygonTreeNode.splitByPlane _this.plane, _this.polygontreenodes, backnodes, frontnodes, backnodes for polygonTreeNode in polygontreenodes
        
      if frontnodes.length > 0
        @front = new Node(this)  unless @front
        @front.addPolygonTreeNodes frontnodes
      if backnodes.length > 0
        @back = new Node(this)  unless @back
        @back.addPolygonTreeNodes backnodes
  
    getParentPlaneNormals: (normals, maxdepth) ->
      if maxdepth > 0
        if @parent
          normals.push @parent.plane.normal
          @parent.getParentPlaneNormals normals, maxdepth - 1

  return {
    "PolygonTreeNode":PolygonTreeNode
    "Tree": Tree
    "Node": Node 
  }
