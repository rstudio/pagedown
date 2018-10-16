#' Create a resume in HTML
#'
#' This output format is based on Min-Zhong Lu's HTML/CSS in the Github repo
#' \url{https://github.com/mnjul/html-resume}.
#' @param ...,css,template See \code{\link{html_paged}()}.
#' @return An R Markdown output format.
#' @export
html_resume = function(..., css = 'resume', template = pkg_resource('html', 'resume.html')) {
  html_format(
    ..., css = css, template = template, theme = NULL, .pagedjs= TRUE,
    .dependencies = list(rmarkdown::html_dependency_font_awesome())
  )
}
