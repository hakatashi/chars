require! {
  \gulp
  \gulp-mocha
  \gulp-livescript
}

gulp.task \js:live ->
  gulp.src <[*.ls test/*.ls !Gulpfile.ls]> base: \.
  .pipe gulp-livescript!
  .pipe gulp.dest \.

gulp.task \js <[js:live]>

gulp.task \test <[js]> ->
  gulp.src <[test/test.js]> {-read}
  .pipe gulp-mocha reporter: \spec

gulp.task \default <[js test]>
