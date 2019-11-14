library(testit)

assert('pkg_resource() finds files under the resources dir of the package', {
  (dir.exists(pkg_resource(c('css', 'js'))))

  res = lua_filters('loft.lua', 'footnotes.lua')
  (sum(res == '--lua-filter') == 2)
  (length(res) == 4)
})

assert('check_css() validates CSS file paths', {
  (is.null(check_css(c('default', 'letter'))))
  (has_error(check_css('default2'), silent = TRUE))
})
