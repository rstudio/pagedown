#' Create a paged HTML document suitable for printing
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
#' @return An R Markdown output format.
#' @import stats utils
#' @export
html_paged = function(
  ..., css = c('default-fonts', 'default-page', 'default'), theme = NULL,
  template = pkg_resource('html', 'paged.html'), csl = NULL
) {
  html_format(
    ..., css = css, theme = theme, template = template, .pagedjs = TRUE,
    .pandoc_args = c(
      lua_filters('uri-to-fn.lua', 'loft.lua', 'footnotes.lua'), # uri-to-fn.lua must come before footnotes.lua
      if (!is.null(csl)) c('--csl', csl)
    )
  )
}

#' Create a letter in HTML
#'
#' This output format is similar to \code{html_paged}. The only difference is in
#' the default stylesheets. See \url{https://pagedown.rbind.io/html-letter/} for
#' an example.
#' @param ...,css Arguments passed to \code{\link{html_paged}()}.
#' @return An R Markdown output format.
#' @export
html_letter = function(..., css = c('default', 'letter')) {
  html_paged(..., css = css, fig_caption = FALSE)
}

#' Create a book for Chapman & Hall/CRC
#'
#' This output format is similar to \code{\link{html_paged}}. The only
#' difference is in the default stylesheets.
#' @param ...,css Arguments passed to \code{\link{html_paged}()}.
#' @return An R Markdown output format.
#' @export
book_crc = function(..., css = c('crc-page', 'default-page', 'default', 'crc')) {
  # see https://github.com/rstudio/pagedown/issues/41 that explains why we need a specific crc-page.css file
  html_paged(..., css = css)
}

#' Create an article for the Journal of Statistical Software
#'
#' This output format is similar to \code{\link{html_paged}}.
#' @param ...,css,template,csl,highlight,pandoc_args Arguments passed to \code{\link{html_paged}()}.
#' @return An R Markdown output format.
#' @export
jss_paged = function(
  ..., css = c('jss-fonts', 'jss-page', 'jss'),
  template = pkg_resource('html', 'jss_paged.html'),
  csl = pkg_resource('csl', 'journal-of-statistical-software.csl'),
  highlight = NULL, pandoc_args = NULL
) {
  jss_format = html_paged(
    ..., template = template, css = css,
    csl = csl, highlight = highlight,
    pandoc_args = c(
      lua_filters('jss.lua'),
      '--metadata', 'link-citations=true',
      pandoc_args
    )
  )

  opts_jss = list(
    prompt = TRUE, comment = NA, R.options = list(prompt ='R> ', continue = 'R+ '),
    fig.align = 'center', fig.width = 4.9, fig.height = 3.675,
    class.source = 'r-chunk-code'
  )
  for (i in names(opts_jss)) {
    jss_format$knitr$opts_chunk[[i]] = opts_jss[[i]]
  }

  jss_format
}

pagedown_dependency = function(css = NULL, js = FALSE) {
  list(htmltools::htmlDependency(
    'paged', packageVersion('pagedown'), src = pkg_resource(),
    script = if (js) c('js/config.js', 'js/paged.js', 'js/hooks.js'),
    stylesheet = file.path('css', css), all_files = FALSE
  ))
}

html_format = function(
  ..., css, template, pandoc_args = NULL, .dependencies = NULL,
  .pagedjs = FALSE, .pandoc_args = NULL
) {
  css2 = grep('[.]css$', css, value = TRUE, invert = TRUE)
  css  = setdiff(css, css2)
  check_css(css2)
  html_document2 = function(..., extra_dependencies = list()) {
    bookdown::html_document2(..., extra_dependencies = c(
      extra_dependencies, .dependencies,
      pagedown_dependency(xfun::with_ext(css2, '.css'), .pagedjs)
    ))
  }
  html_document2(
    ..., css = css, template = template, pandoc_args = c(.pandoc_args, pandoc_args)
  )
}
