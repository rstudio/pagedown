#' Create a paged HTML document suitable for printing
#'
#' This is an output format based on
#' \code{bookdown::\link[bookdown]{html_document2}} (which means you can use
#' those Markdown features added by \pkg{bookdown}). The HTML output document is
#' split into multiple pages via a JavaScript library \pkg{paged.js}. These
#' pages contain elements commonly seen in PDF documents, such as page numbers
#' and running headers.
#' @param ... Arguments passed to \code{bookdown::html_document2}.
#' @param css A character vector of CSS file paths. If a path does not contain
#'   the \file{.css} extension, it is assumed to be a built-in CSS file. For
#'   example, \code{default-fonts} means the file
#'   \code{pagedown:::pkg_resource('css', 'default-fonts.css')}. To see all
#'   built-in CSS files, run \code{pagedown:::list_css()}.
#' @param theme The Bootstrap theme. By default, Bootstrap is not used.
#' @param template The path to the Pandoc template to convert Markdown to HTML.
#' @return An R Markdown output format.
#' @import stats utils
#' @export
html_paged = function(
  ..., css = c('default-fonts', 'default'), theme = NULL,
  template = pkg_resource('html', 'paged.html')
) {
  html_format(..., css = css, theme = theme, template = template, .pagedjs = TRUE)
}

pagedown_dependency = function(css = NULL, js = FALSE) {
  list(htmltools::htmlDependency(
    'paged', packageVersion('pagedown'), src = pkg_resource(),
    script = if (js) c('js/config.js', 'js/paged.js', 'js/hooks.js'),
    stylesheet = file.path('css', css), all_files = FALSE
  ))
}

html_format = function(..., css, template, .dependencies = NULL, .pagedjs = FALSE) {
  css2 = grep('[.]css$', css, value = TRUE, invert = TRUE)
  css  = setdiff(css, css2)
  check_css(css2)
  html_document2 = function(..., extra_dependencies = list()) {
    bookdown::html_document2(..., extra_dependencies = c(
      extra_dependencies, .dependencies,
      pagedown_dependency(xfun::with_ext(css2, '.css'), .pagedjs)
    ))
  }
  html_document2(..., css = css, template = template)
}
