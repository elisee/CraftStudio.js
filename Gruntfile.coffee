module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.initConfig
    jade:
      compile:
        files:
          'build/viewer.html': 'src/viewer.jade'
    coffee:
      compile:
        options: { join: true, sourceMap: true }
        files:
          'build/tmp/craftstudio.js': [ 'src/CraftStudio.coffee', 'src/**/*.coffee' ]
    uglify:
      compile:
        files:
          'build/three.js': [
            'bower_components/threejs/build/three.js'
            'bower_components/threejs/examples/js/shaders/CopyShader.js'
            'bower_components/threejs/examples/js/shaders/SSAOShader.js'
            'bower_components/threejs/examples/js/postprocessing/EffectComposer.js'
            'bower_components/threejs/examples/js/postprocessing/RenderPass.js'
            'bower_components/threejs/examples/js/postprocessing/MaskPass.js'
            'bower_components/threejs/examples/js/postprocessing/ShaderPass.js'
          ]
          'build/craftstudio.js': [ 'build/tmp/craftstudio.js' ]
      beautify:
        options: { beautify: true, mangle: false, compress: false }
        files:
          'build/three.js': [
            'bower_components/threejs/build/three.js'
            'bower_components/threejs/examples/js/shaders/CopyShader.js'
            'bower_components/threejs/examples/js/shaders/SSAOShader.js'
            'bower_components/threejs/examples/js/postprocessing/EffectComposer.js'
            'bower_components/threejs/examples/js/postprocessing/RenderPass.js'
            'bower_components/threejs/examples/js/postprocessing/MaskPass.js'
            'bower_components/threejs/examples/js/postprocessing/ShaderPass.js'
          ]
          'build/craftstudio.js': [ 'build/tmp/craftstudio.js' ]
    watch:
      jade:
        files: [ 'src/**/*.jade' ]
        tasks: [ 'jade' ]
      coffee:
        files: [ 'src/**/*.coffee' ]
        tasks: [ 'coffee', 'uglify:beautify' ]
  
  grunt.registerTask 'default', [ 'jade', 'coffee', 'uglify' ]
  grunt.registerTask 'dev', [ 'jade', 'coffee', 'uglify:beautify', 'watch' ]
