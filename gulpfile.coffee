fs   = require 'fs'
gulp = require 'gulp'
$    = do require 'gulp-load-plugins'
es   = require 'event-stream'
runSequence = require 'run-sequence'

{argv}   = require 'yargs'

pkg = JSON.parse fs.readFileSync './package.json'
ssh = JSON.parse fs.readFileSync './secrets/ssh.json'

symlink = (src, dest) ->
  if fs.existsSync dest
    return unless fs.lstatSync(dest).isSymbolicLink()
    fs.unlinkSync dest
  fs.symlink src, dest

gulp.on 'error', (err) ->
  console.log err

gulp.task 'css', ->
  gulp.src 'src/css/app.styl'
    # .pipe $.cached 'css'
    .pipe $.stylus()
    .pipe gulp.dest 'build'
    .pipe $.connect.reload()

gulp.task 'js', ->
  gulp.src ['src/**/*.coffee', '!src/**/*.spec.coffee']
    .pipe $.cached 'js'
    .pipe $.coffee()
    .pipe gulp.dest 'build'
    .pipe $.connect.reload()

gulp.task 'templates', ->
  gulp.src 'src/**/*.jade'
    .pipe $.jade()
    .pipe $.angularTemplates module: pkg.name
    .pipe $.concat 'templates.js'
    .pipe gulp.dest 'build'
    .pipe $.connect.reload()

gulp.task 'lib', ->
  $.bowerFiles()
    .pipe $.using color: 'cyan'
    .pipe $.cached 'lib'
    .pipe gulp.dest 'build/lib'

gulp.task 'static', ->
  gulp.src 'static/**/*'
    .pipe $.symlink 'build'

gulp.task 'index', ['lib', 'css', 'js', 'templates'], ->
  gulp.src 'src/index.jade'
    .pipe $.jade pretty: true
    .pipe $.inject(
      gulp.src([
        'build/lib/jquery/*.{css,js}'
        'build/lib/**/*.{css,js}'
        'build/**/module.js'
        'build/**/*.{css,js}'
        '!build/templates.js'
      ], read: false)
    , ignorePath: 'build')
    .pipe $.inject(
      gulp.src('build/templates.js', read: false),
      ignorePath: 'build'
      starttag: '<!-- inject:templates.js -->'
    )
    .pipe gulp.dest 'build'

gulp.task 'serve', ->
  $.connect.server
    port: argv.port || 8080
    root: 'public'
    livereload: true

gulp.task 'compile', ['index']

gulp.task 'build', ->
  runSequence 'clean', ['compile', 'static'], ->
    symlink 'build', 'public'

gulp.task 'watch', ['clean', 'build'], ->
  gulp.watch 'src/**/*', ['compile']

gulp.task 'clean', ->
  gulp.src [
    'build/**/*'
    'public'
  ]
    .pipe $.clean()

gulp.task 'default', ['build', 'serve', 'watch']
