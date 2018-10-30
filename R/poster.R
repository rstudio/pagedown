#' Create posters in HTML
#'
#' The output format \code{poster_relaxed()} is based on an example in the
#' Github repo \url{https://github.com/RelaxedJS/ReLaXed-examples}. See
#' \url{https://pagedown.rbind.io/poster-relaxed/} for an example.
#' @param ...,css,template,number_sections See \code{\link{html_paged}()}.
#' @return An R Markdown output format.
#' @export
poster_relaxed = function(
  ..., css = 'poster-relaxed', template = pkg_resource('html', 'poster-relaxed.html'),
  number_sections = FALSE
) {
  html_format(
    ..., css = css, template = template, theme = NULL, number_sections = number_sections
  )
}


# TODO: most posters like https://www.overleaf.com/gallery/tagged/poster

# https://www.overleaf.com/latex/templates/landscape-beamer-poster-template/vjpmsxxdvtqk
poster_jacobs = function(..., css = 'poster-jacobs') {
  poster_relaxed(..., css = css)
}
