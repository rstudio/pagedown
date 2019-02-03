#' Create business cards
#'
#' This output format is based on an example in the Github repo
#' \url{https://github.com/RelaxedJS/ReLaXed-examples}. See
#' \url{https://pagedown.rbind.io/business-card/} for an example.
#'
#' @param logo Path or URL to a logo.
#' @param width,height Width and height of the card.
#' @param googlefonts Names of Google fonts to be loaded on the card page.
#' @param mainfont Names of fonts to be used for the body text of the card.
#' @return An R Markdown output format.
#' @export
#' @examples pagedown::business_card(googlefonts = 'Lato')
business_card = function(
  logo = NULL, width = '2in', height = '3in',
  googlefonts = 'Montserrat', mainfont = googlefonts
) {
  rmarkdown::output_format(
    list(opts_chunk = list(echo = FALSE)),
    rmarkdown::pandoc_options('html', 'markdown', args = c(
      '--template', rmarkdown::pandoc_path_arg(pkg_resource('html', 'card.html')),
      c(rbind('--variable', c(
        paste0('logo=', logo),
        paste0('googlefonts=', paste(googlefonts, collapse = '|')),
        paste0('mainfont=', paste(mainfont, collapse = ', ')),
        paste0('pagewidth=', width), paste0('pageheight=', height)
      )))
    ))
  )
}
