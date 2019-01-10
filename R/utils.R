pkg_resource = function(...) {
  system.file('resources', ..., package = 'pagedown', mustWork = TRUE)
}

lua_filters = function(...) {
  c(rbind("--lua-filter", pkg_resource('lua', c(...))))
}

csl_style = function(csl) {
  if (is.null(csl))
    return(NULL)
  if (length(csl) > 1)
    stop('At most one CSL filename can be supplied.', call. = FALSE)

  with_csl_ext = grepl('[.]csl$', csl)
  if (isTRUE(with_csl_ext))
    return(c('--csl', csl))
  else {
    check_csl(csl)
    return(c('--csl', pkg_resource('csl', paste0(csl, '.csl'))))
  }
}

list_files = function(ext = 'css') {
  files = list.files(pkg_resource(ext), paste0('[.]', ext, '$'), full.names = TRUE)
  setNames(files, gsub(paste0('.', ext, '$'), '', basename(files)))
}

check_file = function(file, ext = 'css') {
  valid = names(list_files(ext))
  if (length(invalid <- setdiff(file, valid)) == 0) return()
  invalid = invalid[1]
  maybe = sort(agrep(invalid, valid, value = TRUE))[1]
  hint = if (is.na(maybe)) '' else paste0('; did you mean "', maybe, '"?')
  stop(
    '"', invalid, '" is not a valid built-in ', toupper(ext), ' filename', if (hint != "") hint else ".",
    " Use `pagedown:::list_files('", ext, "')` to view all built-in ", toupper(ext), " filenames.", call. = FALSE
  )
}

list_css = list_files('css')
check_css = function(file) check_file(file, ext = 'css')

list_csl = list_files('csl')
check_csl = function(file) check_file(file, ext = 'csl')
