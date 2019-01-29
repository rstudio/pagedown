#' Create business cards
#'
#' This output format is based on an example in the Github repo
#' \url{https://github.com/RelaxedJS/ReLaXed-examples}. See
#' \url{https://pagedown.rbind.io/business-card/} for an example.
#'
#' @param width,height Width and height of the card.
#' @param paperwidth,paperheight Width and height of the paper.
#' @param cols,rows Number of columns and rows per page.
#' @param googlefonts Names of Google fonts to be loaded on the card page.
#' @param mainfont Names of fonts to be used for the body text of the card.
#' @return An R Markdown output format.
#' @export
#' @examples pagedown::business_card(googlefonts = 'Lato')
business_card = function(
  width = '2in', height = '3in',
  paperwidth = '2in', paperheight = '3in',
  cols = 1, rows = 1,
  googlefonts = 'Montserrat', mainfont = googlefonts
) {
  rmarkdown::output_format(
    list(opts_chunk = list(echo = FALSE)),
    rmarkdown::pandoc_options('html', 'markdown', args = c(
      '--template', rmarkdown::pandoc_path_arg(pkg_resource('html', 'card.html')),
      c(rbind('--variable', c(
        paste0('googlefonts=', paste(googlefonts, collapse = '|')),
        paste0('mainfont=', paste(mainfont, collapse = ', ')),
        paste0('cardwidth=', width), paste0('cardheight=', height),
        paste0('pagewidth=', paperwidth), paste0('pageheight=', paperheight),
        paste0('ncols=', cols), paste0('nrows=', rows)
      )))
    ))
  )
}
