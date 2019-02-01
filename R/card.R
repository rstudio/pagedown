#' Create business cards
#'
#' This output format is based on an example in the Github repo
#' \url{https://github.com/RelaxedJS/ReLaXed-examples}. See
#' \url{https://pagedown.rbind.io/business-card/} for an example.
#'
#' @return An R Markdown output format.
#' @export
#' @examples pagedown::business_card()
business_card = function() {
  rmarkdown::output_format(
    list(opts_chunk = list(echo = FALSE)),
    rmarkdown::pandoc_options('html', 'markdown', args = c(
      '--template', rmarkdown::pandoc_path_arg(pkg_resource('html', 'card.html')),
      '--variable', 'pagetitle=Business Card'
    ))
  )
}
