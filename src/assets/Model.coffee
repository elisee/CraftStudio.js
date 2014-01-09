class CraftStudio.Model
  constructor: (modelDef, @texture) ->
    @rootBoxes = []
    @boxesByName = {}
    @boxCount = 0
    @rootBoxes.push( buildBox @, boxDef ) for boxDef in modelDef.tree
    @transparent = modelDef.transparent

  buildBox = (model, boxDef, parentBox) ->
    box = model.boxesByName[ boxDef.name ] =
      name: boxDef.name
      position: new THREE.Vector3 boxDef.position[0], boxDef.position[1], boxDef.position[2]
      orientation: new THREE.Quaternion().setFromEuler new THREE.Euler THREE.Math.degToRad(boxDef.rotation[0]), THREE.Math.degToRad(boxDef.rotation[1]), THREE.Math.degToRad(boxDef.rotation[2])
      offsetFromPivot: new THREE.Vector3 boxDef.offsetFromPivot[0], boxDef.offsetFromPivot[1], boxDef.offsetFromPivot[2]
      size: new THREE.Vector3 boxDef.size[0], boxDef.size[1], boxDef.size[2]
      texOffset: boxDef.texOffset
      parent: parentBox
      children: []

    if boxDef.vertexCoords?
      box.vertexCoords = ( new THREE.Vector3 v[0], v[1], v[2] for v in boxDef.vertexCoords )
    else
      box.vertexCoords = [
        new THREE.Vector3 -box.size.x / 2,  box.size.y / 2, -box.size.z / 2
        new THREE.Vector3  box.size.x / 2,  box.size.y / 2, -box.size.z / 2
        new THREE.Vector3  box.size.x / 2, -box.size.y / 2, -box.size.z / 2
        new THREE.Vector3 -box.size.x / 2, -box.size.y / 2, -box.size.z / 2
        new THREE.Vector3  box.size.x / 2,  box.size.y / 2,  box.size.z / 2
        new THREE.Vector3 -box.size.x / 2,  box.size.y / 2,  box.size.z / 2
        new THREE.Vector3 -box.size.x / 2, -box.size.y / 2,  box.size.z / 2
        new THREE.Vector3  box.size.x / 2, -box.size.y / 2,  box.size.z / 2
      ]

    model.boxCount++
    for childBoxDef in boxDef.children
      box.children.push buildBox model, childBoxDef, box

    box

