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

#' @description The output format \code{poster_jacobs()} mimics the style of the
#'   \dQuote{Jacobs Landscape Poster LaTeX Template Version 1.0} at
#'   \url{https://www.overleaf.com/gallery/tagged/poster}. See
#'   \url{https://pagedown.rbind.io/poster-jacobs/} for an example.
#' @rdname poster_relaxed
#' @export
poster_jacobs = function(
  ..., css = 'poster-jacobs', template = pkg_resource('html', 'poster-jacobs.html')
) {
  poster_relaxed(..., css = css, template = template)
}
