#' Create a paged HTML document suitable for printing
#'
#' This is an output format based on \code{bookdown::html_document2} (which
#' means you can use those Markdown features added by \pkg{bookdown}). The HTML
#' output document is split into multiple pages via a JavaScript library
#' \pkg{paged.js}. These pages contain elements commonly seen in PDF documents,
#' such as page numbers and running headers.
#'
#' When a path or an url is passed to the \code{front_cover} or \code{back_cover}
#' argument, several CSS variables are created. They are named \code{--front-cover}
#' and \code{--back-cover} and can be used as value for the CSS property \code{background-image}.
#' For example, \code{background-image: var(--front-cover);}. When a vector of
#' paths or urls is used as a value for \code{front_cover} or \code{back_cover},
#' the CSS variables are suffixed with an index: \code{--front-cover-1},
#' \code{--front-cover-2}, etc.
#'
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
#' @param front_cover,back_cover Paths or urls to image files to be used
#'   as front or back covers. Theses images are available through CSS variables
#'   (see Details).
#' @references \url{https://pagedown.rbind.io}
#' @return An R Markdown output format.
#' @import stats utils
#' @export
html_paged = function(
  ..., css = c('default-fonts', 'default-page', 'default'), theme = NULL,
  template = pkg_resource('html', 'paged.html'), csl = NULL,
  front_cover = NULL, back_cover = NULL
) {
  html_format(
    ..., css = css, theme = theme, template = template, .pagedjs = TRUE,
    .pandoc_args = c(
      lua_filters('uri-to-fn.lua', 'loft.lua', 'footnotes.lua'), # uri-to-fn.lua must come before footnotes.lua
      if (!is.null(csl)) c('--csl', csl),
      pandoc_chapter_name_args(),
      pandoc_covers_args(front_cover, back_cover)
    ),
    .dependencies = covers_dependencies(front_cover, back_cover)
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
    prompt = TRUE, comment = NA, R.options = list(prompt = 'R> ', continue = 'R+ '),
    fig.align = 'center', fig.width = 4.9, fig.height = 3.675,
    class.source = 'r-chunk-code'
  )
  for (i in names(opts_jss)) {
    jss_format$knitr$opts_chunk[[i]] = opts_jss[[i]]
  }

  jss_format
}

#' Create a paged HTML thesis document suitable for printing
#'
#' This output format is similar to \code{\link{html_paged}}. The only
#' difference is in the default stylesheets and Pandoc template. See
#' \url{https://pagedown.rbind.io/thesis-paged/} for an example.
#' @param ...,css,template Arguments passed to \code{\link{html_paged}()}.
#' @return An R Markdown output format.
#' @export
thesis_paged = function(
  ..., css = c('thesis'), template = pkg_resource('html', 'thesis.html')
) {
  html_paged(..., css = css, template = template)
}

pagedown_dependency = function(css = NULL, js = FALSE, .test = FALSE) {
  paged = if (.test) 'js/paged-latest.js' else c('js/paged.js', 'js/hooks.js')
  list(htmltools::htmlDependency(
    'paged', packageVersion('pagedown'), src = pkg_resource(),
    script = if (js) c('js/config.js', paged),
    stylesheet = file.path('css', css), all_files = .test
  ))
}

html_format = function(
  ..., self_contained = TRUE, anchor_sections = FALSE, mathjax = 'default', css, template, pandoc_args = NULL,
  .dependencies = NULL, .pagedjs = FALSE, .pandoc_args = NULL, .test = FALSE
) {
  if (!identical(mathjax, 'local')) {
    if (identical(mathjax, 'default'))
      mathjax = rmarkdown:::default_mathjax()

    # workaround the rmarkdown warning when self_contained is TRUE
    # see https://github.com/rstudio/pagedown/issues/128#issuecomment-518371613
    if (isTRUE(self_contained) && !is.null(mathjax)) {
      pandoc_args = c(pandoc_args, paste0('--mathjax=', mathjax))
      mathjax = NULL # let rmarkdown believe that we do not use MathJax
    }
  }

  css2 = grep('[.]css$', css, value = TRUE, invert = TRUE)
  css  = setdiff(css, css2)
  check_css(css2)

  pandoc_args = c(
    .pandoc_args,
    pandoc_args,
    # use the pagebreak pandoc filter provided by rmarkdown 1.16:
    if (isTRUE(.pagedjs)) pandoc_metadata_arg('newpage_html_class', 'page-break-after')
  )

  html_document2 = function(..., extra_dependencies = list()) {
    bookdown::html_document2(..., extra_dependencies = c(
      extra_dependencies, .dependencies,
      pagedown_dependency(xfun::with_ext(css2, '.css'), .pagedjs, .test)
    ))
  }
  format = html_document2(
    ..., self_contained = self_contained, anchor_sections = anchor_sections, mathjax = mathjax, css = css,
    template = template, pandoc_args = pandoc_args
  )
  if (isTRUE(.pagedjs)) format$knitr$opts_chunk[['render']] = paged_render(self_contained)
  iframe_file(reset = TRUE)
  format
}

paged_render = function(self_contained) {
  function(x, options, ...) {
    if (inherits(x, 'htmlwidget')) {
      class(x) = c('iframehtmlwidget', class(x))
    }
    knitr::knit_print(x, options, ..., self_contained = self_contained)
  }
}

knit_print.iframehtmlwidget = function(x, options, ..., self_contained) {
  class(x) = tail(class(x), -1)
  d = options$fig.path
  if (!dir.exists(d)) {
    dir.create(d, recursive = TRUE)
    d = normalizePath(d)
    if (self_contained) on.exit(unlink(d, recursive = TRUE), add = TRUE)
  }
  f = save_widget(d, x, options)
  src = NULL
  srcdoc = NULL
  if (self_contained) {
    srcdoc = paste0(collapse = '\n', readLines(f))
    file.remove(f)
  } else {
    src = f
  }
  knitr::knit_print(autoscaling_iframe(
    src = src, srcdoc = srcdoc, width = options$out.width.px,
    height = options$out.height.px, extra.attr = options$out.extra
  ))
}

save_widget = function(directory, widget, options) {
  old_wd = setwd(directory)
  on.exit({
    setwd(old_wd)
  }, add = TRUE)
  f = iframe_file()
  htmlwidgets::saveWidget(
    widget = widget, file = f,
    # since chrome_print() does not handle network requests, use a self contained html file
    # In order to use selcontained = FALSE, we should implement a networkidle option in chrome_print()
    selfcontained = TRUE,
    knitrOptions = options
  )
  return(paste0(directory, f))
}

iframe_file = (function() {
  n = 0L
  function(reset = FALSE) {
    if (reset) n <<- -1L
    n <<- n + 1L
    sprintf('iframe%i.html', n)
  }
})()

autoscaling_iframe = function(width = NULL, height = NULL, ..., extra.attr = '') {
  if (length(extra.attr) == 0) extra.attr = ''
  extra.attr = as_html_attrs(extra.attr)
  tag = htmltools::tag(
    'autoscaling-iframe',
    c(extra.attr,
      list(...),
      list(htmltools::p("This browser does not support this feature."))
    )
  )
  width = css_declaration('width', htmltools::validateCssUnit(width))
  height = css_declaration('height', htmltools::validateCssUnit(height))
  tag = do.call(
    htmltools::tagAppendAttributes,
    c(list(tag = tag), list(style = width, style = height))
  )
  htmltools::attachDependencies(
    tag,
    htmltools::htmlDependency(
      'autoscalingiframe', packageVersion('pagedown'), src = pkg_resource(),
      script = 'js/autoscaling_iframe.js', all_files = FALSE
    )
  )
}

as_html_attrs = function(string) {
  doc = xml2::read_html(sprintf('<p %s>', string))
  node = xml2::xml_find_first(doc, './/p')
  xml2::xml_attrs(node)
}

css_declaration = function(property, value) {
  if (is.null(value)) return('')
  paste0(property, ':', value, ';')
}

chapter_name = function() {
  config = bookdown:::load_config()
  chapter_name = config[['chapter_name']] %n% bookdown:::ui_language('chapter_name')
  if (is.null(chapter_name) || identical(chapter_name, '')) return()
  if (!is.character(chapter_name)) stop(
    'chapter_name in _bookdown.yml must be a character string'
  )
  if (length(chapter_name) > 2) stop('chapter_name must be of length 1 or 2')
  chapter_name
}

pandoc_metadata_arg = function(name, value) {
  if (!missing(value) && is.character(value)) {
    value = deparse(value)
  }
  c('--metadata', if (missing(value)) name else paste0(name, '=', value))
}

pandoc_chapter_name_args = function() {
  unlist(lapply(chapter_name(), pandoc_metadata_arg, name = 'chapter_name'))
}

pandoc_covers_args = function(front_cover, back_cover) {
  build_links = function(name, img) {
    if (length(img) == 0) return()
    name = paste(name, seq_along(img), sep = '-')
    links = paste0('<link id="', name,'-pagedown-attachment" rel="attachment" href="', img, '" />')
    links[!file.exists(img)]
  }
  links = c(build_links('front-cover', front_cover), build_links('back-cover', back_cover))
  if (length(links)) {
    writeLines(links, f <- tempfile(fileext = ".html"))
    rmarkdown::includes_to_pandoc_args(rmarkdown::includes(f))
  }
}

covers_dependencies = function(front_cover, back_cover) {
  html_dep = function(name, img) {
    htmltools::htmlDependency(
      name, packageVersion('pagedown'), dirname(path.expand(img)),
      attachment = c(pagedown = basename(img)), all_files = FALSE
    )
  }

  build_deps = function(name, img) {
    if (length(img) == 0) return(list())
    name = paste(name, seq_along(img), sep = '-')
    name = name[file.exists(img)]
    img = img[file.exists(img)]
    mapply(name, img, FUN = html_dep, USE.NAMES = FALSE, SIMPLIFY = FALSE)
  }

  c(build_deps('front-cover', front_cover), build_deps('back-cover', back_cover))
}
