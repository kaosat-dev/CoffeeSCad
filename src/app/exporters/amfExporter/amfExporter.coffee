define (require) ->
  utils = require "core/utils/utils"
  marionette = require 'marionette'
  XMLWriter = require 'XMLWriter'
  
  vent = require 'core/messaging/appVent'
  reqRes = require 'core/messaging/appReqRes'
  Project = require 'core/projects/project'
  ModalRegion = require 'core/utils/modalRegion' 
  
  AmfExporterView = require './amfExporterView'
  
  
  class AmfExporter extends Backbone.Marionette.Application
    ###
    Exports the given csg tree to the amf file format (stl successor with multi material support etc)
    see: http://en.wikipedia.org/wiki/Additive_Manufacturing_File_Format
    ###
    constructor:(options)->
      super options
      @vent=vent
      @mimeType = "application/sla"
      @on "start", @onStart
    
    start:(options)->
      @project= options.project ? new Project()
      reqRes.addHandler "amfexportBlobUrl", ()=>
        blobUrl = @export(@project.rootAssembly)
        return blobUrl
          
      @trigger("initialize:before", options)
      @initCallbacks.run(options, this)
      @trigger("initialize:after", options)
      @trigger("start", options)
     
    onStart:()=>
      amfExporterView = new AmfExporterView
        model:@project
      modReg = new ModalRegion({elName:"exporter"})
      modReg.on("closed", @stop)
      modReg.show amfExporterView
    
    stop:->
      console.log "closing amf exporter"
      
    export:(csgObject,mergeAll=false)=>
      try
        try
          if mergeAll
            #merge all children of the csg object
            mergedObj = csgObject.clone()
            for part in csgObject.children
              mergedObj.union(part)
            @csgObject = mergedObj
          else
            @csgObject = csgObject
        catch error
          errorMsg = "Failed to merge csgObject children with error: #{error}"
          console.log errorMsg
          throw new Error(errorMsg) 
          
        @currentObject = null
        try
          @currentObject = @csgObject.fixTJunctions()
          data = @_generateAmf()
          blob = new Blob([data], {type: @mimeType})
        catch error
          errorMsg = "Failed to generate amf blob data: #{error}"
          console.log errorMsg
          console.log error.stack
          throw new Error(errorMsg) 
          
        windowURL=utils.getWindowURL()
        @outputFileBlobUrl = windowURL.createObjectURL(blob)
        if not @outputFileBlobUrl then throw new Error("createObjectURL() failed") 
        return @outputFileBlobUrl
        
      catch error
        @vent.trigger("amfExport:error", error)
        return null
    
    _generateAmf:()->
      console.log "I want to generate AMF"
      unit = "milimeter"
      
      #prepare xml
      xw = new XMLWriter( 'UTF-8', '1.0' )
      xw.writeStartDocument()
      xw.writeStartElement("amf")
      xw.writeAttributeString("unit",unit)
      
      xw.writeStartElement("materials")
      xw.writeEndElement()
      
      processedCSG = @_preProcessCSG(@csgObject)
      
      for part,index in @csgObject.children
        #part.fixTJunctions()
        #object
        xw.writeStartElement("object")
        xw.writeAttributeString("id",index)
        
        #mesh start ----->
        xw.writeStartElement("mesh")
        #TODO: convert object to a set of vertices/ vindexes ?
        xw.writeStartElement("volume")
        
        xw.writeStartElement("triangle")
        xw.writeElementString("v1","0")
        xw.writeEndElement()
        
        @_writeColorNode(xw, part)
        
        xw.writeEndElement()
        #for polygon in part.polygons
          
          
        xw.writeStartElement("vertices")
        @_writeVertexNode(xw, parent)
        xw.writeEndElement()
          
        xw.writeEndElement()
        #mesh end ----->
          
        xw.writeEndElement()
      #close xml
      xw.writeEndElement()
      xw.writeEndDocument()
      
      console.log "AMF"
      amfXml = xw.flush()
      xw.close()
      console.log amfXml
      return amfXml
      ### 
      <?xml version="1.0" encoding="UTF-8"?>
      <amf unit="millimeter">
        <object id="0">
          <mesh>
            <vertices>
              <vertex>
                <coordinates>
                  <x>0</x>
                  <y>1.32</y>
                  <z>3.715</z>
                </coordinates>
              </vertex>
              ...
            </vertices>
            <volume>
              <triangle>
                <v1>0</v1>
                <v2>1</v2>
                <v3>3</v3>
              </triangle>
              ...
            </volume>
          </mesh>
        </object>
      </amf>
      ###
    
    _preProcessCSG:(csg)=>
      #TODO: move this to csg core ?
      flatHierarchy = []
      
      parse=(csg)=>
        for child in csg.children
          #clone = child.clone()
          elem = @_preProcessCSGInner(child)
          flatHierarchy.push(elem)
          parse(child)
          
      parse(csg)
      console.log flatHierarchy
      return flatHierarchy
          
    _preProcessCSGInner:(csg)->
      #get faces and vertices from csg
      polygons = csg.toPolygons()
      remapped = {faces:[],vertices:[]}
      verticesIndex= {}
      fetchVertexIndex = (vertex, index)=>
        x = vertex.pos.x 
        y = vertex.pos.y 
        z = vertex.pos.z
        key = "#{x},#{y},#{z}"
        if not (key of verticesIndex)
          sVertex = {x:x,y:y,z:z}
          result = [index, sVertex]
          verticesIndex[key]= result
          result = [index,sVertex,false]
          return result
        else
          [index, v] = verticesIndex[key]
          return [index, v, true]
        
      vertexIndex = 0
      for polygon, polygonIndex in polygons
        color ={r:1,g:1,b:1,a:1}
        try
          color.r = polygon.shared.color[0]
          color.g = polygon.shared.color[1]
          color.b = polygon.shared.color[2]
        polyVertices = []
        for vertex,vindex in polygon.vertices
          #remapped.vertices.push(vertex)
          [index,v,found] = fetchVertexIndex(vertex,vertexIndex)
          polyVertices.push(index)
          if not found
            remapped.vertices.push(v)
            vertexIndex+=1
            
        srcNormal = polygon.plane.normal
        faceNormal = {x:srcNormal.x,y:srcNormal.z,z:srcNormal.y}#new THREE.Vector3(srcNormal.x,srcNormal.z,srcNormal.y)
        for i in [2...polyVertices.length]
          i1 = polyVertices[0]
          i2 = polyVertices[i-1]
          i3 = polyVertices[i]
          face = {index1:i1, index2:i2, index3:i3, normal:faceNormal,vertexColors:[4]}
          #face = new THREE.Face3(i1,i2,i3,faceNormal)
          face.vertexColors[j] = color for j in [0...3]
          remapped.faces.push face
      return remapped
      
    _writeColorNode:(xw, element)->
      xw.writeStartElement("color")
      xw.writeElementString("r", String(element.material.color[0]))
      xw.writeElementString("g", String(element.material.color[1]))
      xw.writeElementString("b", String(element.material.color[2]))
      xw.writeElementString("a","0")
      xw.writeEndElement()
    
    _writeVertices:(xw, vertices)->
      
    _writeVertexNode:(xw, vertex)->
      xw.writeStartElement("vertex")
      xw.writeStartElement("coordinates")
      
      xw.writeElementString("x","25")
      
      xw.writeEndElement()
      xw.writeEndElement()
    
    _writeTriangleNode:(xw, triangle)->
      xw.writeStartElement("triangle")
      xw.writeElementString("v1","0")
      xw.writeEndElement()
      
      
      
  return AmfExporter
 