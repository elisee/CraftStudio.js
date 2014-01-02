class CraftStudio.ModelAnimation
  constructor: (modelAnimDef) ->
    @duration = modelAnimDef.duration
    @holdLastKeyframe = modelAnimDef.holdLastKeyframe
    @nodeAnimations = {}

    for nodeName, nodeAnimData of modelAnimDef.nodeAnimations
      @nodeAnimations[nodeName] = nodeAnim =
        positionKeys: []
        orientationKeys: []

      for frame, delta of nodeAnimData.position
        nodeAnim.positionKeys.push frame: parseInt(frame), delta: new THREE.Vector3 delta[0], delta[1], delta[2]

      for frame, delta of nodeAnimData.rotation
        quaternionDelta = new THREE.Quaternion().setFromEuler new THREE.Euler THREE.Math.degToRad(delta[0]), THREE.Math.degToRad(delta[1]), THREE.Math.degToRad(delta[2])
        nodeAnim.orientationKeys.push frame: parseInt(frame), delta: quaternionDelta

    return

  getPositionDelta: (nodeName, frame) ->
    nodeAnim = @nodeAnimations[nodeName]
    return new THREE.Vector3() if ! nodeAnim?

    keyframes = getNearestKeyframes nodeAnim.positionKeys, frame, @holdLastKeyframe
    return new THREE.Vector3() if ! keyframes?

    factor = computeFrameInterpolationFactor keyframes.previous.frame, keyframes.next.frame, frame, @duration
    keyframes.previous.delta.clone().lerp keyframes.next.delta, factor

  getOrientationDelta: (nodeName, frame) ->
    nodeAnim = @nodeAnimations[nodeName]
    return new THREE.Quaternion() if ! nodeAnim?

    keyframes = getNearestKeyframes nodeAnim.orientationKeys, frame, @holdLastKeyframe
    return new THREE.Quaternion() if ! keyframes?

    factor = computeFrameInterpolationFactor keyframes.previous.frame, keyframes.next.frame, frame, @duration
    keyframes.previous.delta.clone().slerp keyframes.next.delta, factor

  getNearestKeyframes = (keyframes, frame, holdLastKeyframe) ->
    if keyframes.length > 0 and keyframes[ keyframes.length - 1 ].frame <= frame
      return {
        previous: keyframes[keyframes.length - 1]
        next: if holdLastKeyframe then keyframes[keyframes.length - 1] else keyframes[0]
      }
    
    for i in [0...keyframes.length]
      if keyframes[i].frame > frame
        nextIndex = i
        if nextIndex == 0 and holdLastKeyframe
          nextIndex = keyframes.length - 1
        
        return {
          previous: keyframes[(i + keyframes.length - 1 ) % keyframes.length]
          next: keyframes[nextIndex]
        }
    
    null

  computeFrameInterpolationFactor = (previousFrame, nextFrame, frame, duration) ->
    factor = 0
    
    if (nextFrame % duration) != (previousFrame % duration) or nextFrame > previousFrame
      length = nextFrame - previousFrame
      length += duration if length < 0
      frame += duration if frame < previousFrame
      factor = ( frame - previousFrame ) / length
    
    factor
