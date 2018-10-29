#' Create a resume in HTML
#'
#' This output format is based on Min-Zhong Lu's HTML/CSS in the Github repo
#' \url{https://github.com/mnjul/html-resume}.
#' @param ...,css,template See \code{\link{html_paged}()}.
#' @references \url{https://rstudio.github.io/pagedown/html-resume.html}
#' @return An R Markdown output format.
#' @export
html_resume = function(..., css = 'resume', template = pkg_resource('html', 'resume.html')) {
  html_format(
    ..., css = css, template = template, theme = NULL,
    .dependencies = list(rmarkdown::html_dependency_font_awesome())
  )
}

# TODO: port this resume style https://github.com/ohrie/relaxed-resume
