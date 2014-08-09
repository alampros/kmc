module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    docco: {
      debug: {
        src: ['lib/**/*.js'],
        options: {
          output: 'docs/'
        }
      }
    }
  });

  //load dev npm tasks
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  grunt.registerTask('default', ['docco']);
}
