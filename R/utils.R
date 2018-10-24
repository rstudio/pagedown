pkg_resource = function(...) {
  system.file('resources', ..., package = 'pagedown', mustWork = TRUE)
}

lua_filters = function(...) {
  c(rbind("--lua-filter", pkg_resource('lua', c(...))))
}

list_css = function() {
  css = list.files(pkg_resource('css'), '[.]css$', full.names = TRUE)
  setNames(css, gsub('.css$', '', basename(css)))
}

check_css = function(css) {
  valid = names(list_css())
  if (length(invalid <- setdiff(css, valid)) == 0) return()
  invalid = invalid[1]
  maybe = sort(agrep(invalid, valid, value = TRUE))[1]
  hint = if (is.na(maybe)) '' else paste0('; did you mean "', maybe, '"?')
  stop(
    '"', invalid, '" is not a valid built-in CSS filename', if (hint != "") hint else ".",
    " Use `pagedown:::list_css()` to view all built-in CSS filenames.", call. = FALSE
  )
}
