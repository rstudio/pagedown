#' Create a resume in HTML
#'
#' This output format is based on Min-Zhong Lu's HTML/CSS in the Github repo
#' \url{https://github.com/mnjul/html-resume}. See
#' \url{https://pagedown.rbind.io/html-resume/} for an example.
#' @param ...,css,template,number_sections,fig_caption See
#'   \code{\link{html_paged}()}.
#' @return An R Markdown output format.
#' @export
html_resume = function(
  ..., css = 'resume', template = pkg_resource('html', 'resume.html'),
  number_sections = FALSE, fig_caption = FALSE
) {
  html_format(
    ..., css = css, template = template, theme = NULL, number_sections = number_sections,
    fig_caption = fig_caption, .pagedjs = TRUE,
    .dependencies = list(rmarkdown::html_dependency_font_awesome())
  )
}

# TODO: port this resume style https://github.com/ohrie/relaxed-resume
