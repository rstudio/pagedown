#' Create a paged HTML thesis document suitable for printing
#'
#' This is an output format based on \code{bookdown::html_document2} (which
#' means you can use those Markdown features added by \pkg{bookdown}). The HTML
#' output document is split into multiple pages via a JavaScript library
#' \pkg{paged.js}. These pages contain elements commonly seen in PDF documents,
#' such as page numbers and running headers.
#' @param ... Arguments passed to
#'   \code{bookdown::\link[bookdown]{html_document2}}.
#' @param css A character vector of CSS file paths. If a path does not contain
#'   the \file{.css} extension, it is assumed to be a built-in CSS file. For
#'   example, \code{default-fonts} means the file
#'   \code{pagedown:::pkg_resource('css', 'default-fonts.css')}. To see all
#'   built-in CSS files, run \code{pagedown:::list_css()}.
#' @param theme The Bootstrap theme. By default, Bootstrap is not used.
#' @param template The path to the Pandoc template to convert Markdown to HTML.
#' @param csl The path of the Citation Style Language (CSL) file used to format
#'   citations and references (see the \href{https://pandoc.org/MANUAL.html#citations}{Pandoc documentation}).
#' @references \url{https://pagedown.rbind.io}
#' @return An R Markdown thesis output format.
#' @import stats utils
#' @export
thesis_paged = function(
  ..., css = c('thesis-page'),
  template = pkg_resource('html', 'thesis.html')
) {
  html_paged(...,
             css = css,
             template = template)
}

#' @description The output format \code{thesis_minimal} provides a minamal Rmd
#'   file so that power user's can "just go". See
#'   \url{https://pagedown.rbind.io/thesis-paged/} for a bloatted example of
#'   what this template can achieve.
#' @rdname thesis_paged
#' @export
thesis_minimal = function(
  ...
) {
  thesis_paged(...)
}
