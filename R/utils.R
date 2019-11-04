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

merge_list = function(x, y) {
  x[names(y)] = y
  x
}

to_json = function(x, ..., auto_unbox = TRUE, null = 'null') {
  jsonlite::toJSON(x, ..., auto_unbox = auto_unbox, null = null)
}

# don't prefer the port 4321 (otherwise we may see the meaningless error message
# "createTcpServer: address already in use" too often)
random_port = function() servr::random_port(NULL)

`%n%` = knitr:::`%n%`

run_servr = function() {
  # see https://github.com/rstudio/httpuv/issues/250
  later::with_loop(later::global_loop(), httpuv::service(NA))
}
