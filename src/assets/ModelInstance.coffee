class CraftStudio.ModelInstance
  constructor: (@model) ->
    @geometry = createGeometry @model.boxCount

    @material =  new THREE.MeshPhongMaterial
      color: new THREE.Color 0xffffff
      map: @model.texture
      alphaTest: 0.01
      side: THREE.DoubleSide
      transparent: model.transparent == true
      blending: THREE.NormalBlending

    @resetPose()

  dispose: ->
    @model = null
    @geometry.dipose()
    @geometry = null
    @material.dispose()
    @material = null
    return

  resetPose: -> @setPose null, 0

  rootMatrix = new THREE.Matrix4()
  setPose: (modelAnimation, frame) ->
    boxIndex = 0

    for box in @model.rootBoxes
      boxIndex += poseBoxRecurse @geometry, boxIndex, box, rootMatrix, @material.map, modelAnimation, frame

    @geometry.attributes.position.needsUpdate = true
    @geometry.attributes.normal.needsUpdate = true
    @geometry.attributes.uv.needsUpdate = true
    return

  createGeometry = (boxCount) ->
      geometry = new THREE.BufferGeometry()
      geometry.dynamic = true
      geometry.attributes =
        index: { itemSize: 1, array: new Uint16Array( boxCount * 36 ) }
        position: { itemSize: 3,  array: new Float32Array( boxCount * 72 ) }
        normal: { itemSize: 3, array: new Float32Array( boxCount * 72 ) }
        uv: { itemSize: 2, array: new Float32Array( boxCount * 48 ) }
      
      # Split indices in groups for GPU submission
      bufChunkDivider = 6 # FIXME: Why 6, past me? because quad?
      bufChunkSize = Math.floor( (0xffff + 1) / bufChunkDivider)
      indices = geometry.attributes.index.array
      
      quads = boxCount * 6
      triangles = quads * 2

      for i in [0...quads]
        indices[i * 6 + 0] = (i * 4 + 0) % (bufChunkSize * bufChunkDivider)
        indices[i * 6 + 1] = (i * 4 + 1) % (bufChunkSize * bufChunkDivider)
        indices[i * 6 + 2] = (i * 4 + 2) % (bufChunkSize * bufChunkDivider)
        indices[i * 6 + 3] = (i * 4 + 0) % (bufChunkSize * bufChunkDivider)
        indices[i * 6 + 4] = (i * 4 + 2) % (bufChunkSize * bufChunkDivider)
        indices[i * 6 + 5] = (i * 4 + 3) % (bufChunkSize * bufChunkDivider)
      
      geometry.offsets = []
      offsets = (triangles * 3) / (bufChunkSize * bufChunkDivider / 4 * 6)
      
      for i in [0...offsets]
        offset = 
          index: i * bufChunkSize * bufChunkDivider
          start: i * bufChunkSize * bufChunkDivider / 4 * 6
          count: Math.min( bufChunkSize * bufChunkDivider / 4 * 6, (triangles * 3) - (i * bufChunkSize * bufChunkDivider / 4 * 6) )
        
        geometry.offsets.push offset
      
      geometry

  leftTopBack       = new THREE.Vector3()
  rightTopBack      = new THREE.Vector3()
  rightBottomBack   = new THREE.Vector3()
  leftBottomBack    = new THREE.Vector3()
  rightTopFront     = new THREE.Vector3()
  leftTopFront      = new THREE.Vector3()
  leftBottomFront   = new THREE.Vector3()
  rightBottomFront  = new THREE.Vector3()

  v1 = new THREE.Vector3()
  v2 = new THREE.Vector3()

  frontNormal       = new THREE.Vector3()
  backNormal        = new THREE.Vector3()
  rightNormal       = new THREE.Vector3()
  bottomNormal      = new THREE.Vector3()
  leftNormal        = new THREE.Vector3()
  topNormal         = new THREE.Vector3()

  poseBoxRecurse = (geometry, boxIndex, box, parentMatrix, texture, modelAnimation, frame) ->
    if modelAnimation?
      position = box.position.clone().add modelAnimation.getPositionDelta box.name, frame
      orientation = new THREE.Quaternion().multiplyQuaternions modelAnimation.getOrientationDelta( box.name, frame ), box.orientation
    else
      position = box.position
      orientation = box.orientation

    origin = box.offsetFromPivot.clone().applyQuaternion(orientation).add position
    boxMatrix = new THREE.Matrix4().makeRotationFromQuaternion(orientation).setPosition origin
    boxMatrix.multiplyMatrices parentMatrix, boxMatrix

    # Vertex positions
    leftTopBack       .copy( box.vertexCoords[0] ).applyMatrix4 boxMatrix
    rightTopBack      .copy( box.vertexCoords[1] ).applyMatrix4 boxMatrix
    rightBottomBack   .copy( box.vertexCoords[2] ).applyMatrix4 boxMatrix
    leftBottomBack    .copy( box.vertexCoords[3] ).applyMatrix4 boxMatrix
    rightTopFront     .copy( box.vertexCoords[4] ).applyMatrix4 boxMatrix
    leftTopFront      .copy( box.vertexCoords[5] ).applyMatrix4 boxMatrix
    leftBottomFront   .copy( box.vertexCoords[6] ).applyMatrix4 boxMatrix
    rightBottomFront  .copy( box.vertexCoords[7] ).applyMatrix4 boxMatrix

    # Face normals
    frontNormal       .crossVectors( v1.subVectors( leftBottomFront, leftTopFront ), v2.subVectors( rightTopFront, leftTopFront ) ).normalize()
    backNormal        .crossVectors( v1.subVectors( rightBottomBack, rightTopBack ), v2.subVectors( leftTopBack, rightTopBack ) ).normalize()
    rightNormal       .crossVectors( v1.subVectors( rightBottomFront, rightTopFront ), v2.subVectors( rightTopBack, rightTopFront ) ).normalize()
    bottomNormal      .crossVectors( v1.subVectors( leftBottomBack, leftBottomFront ), v2.subVectors( rightBottomFront, leftBottomFront ) ).normalize()
    leftNormal        .crossVectors( v1.subVectors( leftBottomBack, leftTopBack ), v2.subVectors( leftTopFront, leftTopBack ) ).normalize()
    topNormal         .crossVectors( v1.subVectors( leftTopFront, leftTopBack ), v2.subVectors( rightTopBack, leftTopBack) ).normalize()

    # Setup faces
    positions = geometry.attributes.position.array
    normals = geometry.attributes.normal.array

    setupFace positions, normals, boxIndex * 24 + 0 * 4, rightTopFront, leftTopFront, leftBottomFront, rightBottomFront, frontNormal      # Front
    setupFace positions, normals, boxIndex * 24 + 1 * 4, leftTopBack, rightTopBack, rightBottomBack, leftBottomBack, backNormal           # Back
    setupFace positions, normals, boxIndex * 24 + 2 * 4, rightTopBack, rightTopFront, rightBottomFront, rightBottomBack, rightNormal      # Right
    setupFace positions, normals, boxIndex * 24 + 3 * 4, rightBottomFront, leftBottomFront, leftBottomBack, rightBottomBack, bottomNormal # Bottom
    setupFace positions, normals, boxIndex * 24 + 4 * 4, leftTopFront, leftTopBack, leftBottomBack, leftBottomFront, leftNormal           # Left
    setupFace positions, normals, boxIndex * 24 + 5 * 4, rightTopBack, leftTopBack, leftTopFront, rightTopFront, topNormal                # Top

    # UVs
    faceOffsets = [
      [ box.size.z, box.size.z ] # Front
      [ box.size.z * 2 + box.size.x, box.size.z ] # Back
      [ box.size.z + box.size.x, box.size.z ] # Right
      [ box.size.z + box.size.x, 0 ] # Bottom
      [ 0, box.size.z ] # Left
      [ box.size.z, 0 ] # Top
    ]

    faceSizes = [
      [ box.size.x, box.size.y ] # Front
      [ box.size.x, box.size.y ] # Back
      [ box.size.z, box.size.y ] # Right
      [ box.size.x, box.size.z ] # Bottom
      [ box.size.z, box.size.y ] # Left
      [ box.size.x, box.size.z ] # Top
    ]

    uvs = geometry.attributes.uv.array
    for i in [0...6]
      uvs[ (boxIndex * 6 + i) * 8 + 0 * 2 + 0 ] = ( faceOffsets[i][0] + box.texOffset[0] + faceSizes[i][0] ) / texture.image.width
      uvs[ (boxIndex * 6 + i) * 8 + 0 * 2 + 1 ] = 1 - ( faceOffsets[i][1] + box.texOffset[1] + 0 ) / texture.image.height

      uvs[ (boxIndex * 6 + i) * 8 + 1 * 2 + 0 ] = ( faceOffsets[i][0] + box.texOffset[0] + 0 ) / texture.image.width
      uvs[ (boxIndex * 6 + i) * 8 + 1 * 2 + 1 ] = 1 - ( faceOffsets[i][1] + box.texOffset[1] + 0 ) / texture.image.height

      uvs[ (boxIndex * 6 + i) * 8 + 2 * 2 + 0 ] = ( faceOffsets[i][0] + box.texOffset[0] + 0 ) / texture.image.width
      uvs[ (boxIndex * 6 + i) * 8 + 2 * 2 + 1 ] = 1 - ( faceOffsets[i][1] + box.texOffset[1] + faceSizes[i][1] ) / texture.image.height

      uvs[ (boxIndex * 6 + i) * 8 + 3 * 2 + 0 ] = ( faceOffsets[i][0] + box.texOffset[0] + faceSizes[i][0] ) / texture.image.width
      uvs[ (boxIndex * 6 + i) * 8 + 3 * 2 + 1 ] = 1 - ( faceOffsets[i][1] + box.texOffset[1] + faceSizes[i][1] ) / texture.image.height

    # Recurse
    boxIndex++
    boxCount = 1
    for childBox in box.children
      childBoxCount = poseBoxRecurse geometry, boxIndex, childBox, boxMatrix, texture, modelAnimation, frame
      boxIndex += childBoxCount
      boxCount += childBoxCount

    boxCount

  setupFace = (positions, normals, offset, pos0, pos1, pos2, pos3, normal) ->
    positions[ (offset + 0) * 3 + 0] = pos0.x
    positions[ (offset + 0) * 3 + 1] = pos0.y
    positions[ (offset + 0) * 3 + 2] = pos0.z
    
    positions[ (offset + 1) * 3 + 0] = pos1.x
    positions[ (offset + 1) * 3 + 1] = pos1.y
    positions[ (offset + 1) * 3 + 2] = pos1.z
    
    positions[ (offset + 2) * 3 + 0] = pos2.x
    positions[ (offset + 2) * 3 + 1] = pos2.y
    positions[ (offset + 2) * 3 + 2] = pos2.z
    
    positions[ (offset + 3) * 3 + 0] = pos3.x
    positions[ (offset + 3) * 3 + 1] = pos3.y
    positions[ (offset + 3) * 3 + 2] = pos3.z
    
    normals[ (offset + 0) * 3 + 0] = normal.x
    normals[ (offset + 0) * 3 + 1] = normal.y
    normals[ (offset + 0) * 3 + 2] = normal.z
    
    normals[ (offset + 1) * 3 + 0] = normal.x
    normals[ (offset + 1) * 3 + 1] = normal.y
    normals[ (offset + 1) * 3 + 2] = normal.z
    
    normals[ (offset + 2) * 3 + 0] = normal.x
    normals[ (offset + 2) * 3 + 1] = normal.y
    normals[ (offset + 2) * 3 + 2] = normal.z
    
    normals[ (offset + 3) * 3 + 0] = normal.x
    normals[ (offset + 3) * 3 + 1] = normal.y
    normals[ (offset + 3) * 3 + 2] = normal.z
    return

