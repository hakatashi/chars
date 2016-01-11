require! {
  \gulp
  \gulp-mocha
  \gulp-babel
  \gulp-livescript
}

gulp.task \js:es6 ->
  gulp.src <[*.es6]> base: \.
  .pipe gulp-babel presets: <[es2015]>
  .pipe gulp.dest \.

gulp.task \js:live ->
  gulp.src <[*.ls test/*.ls !Gulpfile.ls]> base: \.
  .pipe gulp-livescript!
  .pipe gulp.dest \.

gulp.task \js <[js:es6 js:live]>

gulp.task \test <[js]> ->
  gulp.src <[test/test.js]> {-read}
  .pipe gulp-mocha reporter: \spec

gulp.task \default <[js test]>
