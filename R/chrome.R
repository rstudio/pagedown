#' Print a web page to PDF using the headless Chrome
#'
#' This is a wrapper function to execute the command \command{chrome --headless
#' --print-to-pdf url}. Google Chrome (or Chromium on Linux) must be installed
#' prior to using this function.
#' @param url A URL or local file path to a web page.
#' @param output The (PDF) output filename. For a local web page
#'   \file{foo/bar.html}, the default PDF output is \file{foo/bar.pdf}; for a
#'   remote URL \file{https://www.example.org/foo/bar.html}, the default output
#'   will be \file{bar.pdf} under the current working directory.
#' @param browser Path to Google Chrome or Chromium. This function will try to
#'   find it automatically if the path is not explicitly provided.
#' @param extra_args Extra command-line arguments to be passed to Chrome.
#' @param verbose Whether to show verbose command-line output.
#' @references
#' \url{https://developers.google.com/web/updates/2017/04/headless-chrome}
#' @return Path of the output file (invisibly).
#' @export
chrome_print = function(
  url, output = xfun::with_ext(url, 'pdf'), browser = 'google-chrome',
  extra_args = c('--disable-gpu'), verbose = FALSE
) {
  if (missing(browser)) browser = switch(
    .Platform$OS.type,
    windows = {
      res = tryCatch({
        unlist(utils::readRegistry('ChromeHTML\\shell\\open\\command', 'HCR'))
      }, error = function(e) '')
      res = head(unlist(strsplit(res, '"')), 1)
      if (length(res) != 1) stop(
        'Cannot find Google Chrome automatically from the Windows Registry Hive. ',
        "Please pass the full path of chrome.exe to the 'browser' argument."
      )
    },
    unix = if (xfun::is_macos()) {
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
    } else {
      for (i in c('chromium-browser', 'google-chrome')) {
        if ((res <- Sys.which(i)) != '') break
      }
      if (res == '') stop('Cannot find chromium-browser or google-chrome')
      res
    },
    stop('Your platform is not supported')
  ) else if (!file.exists(browser)) browser = Sys.which(browser)

  if (!utils::file_test('-x', browser)) stop('The browser is not executable: ', browser)

  # remove hash/query parameters in url
  if (missing(output) && !file.exists(url))
    output = xfun::with_ext(basename(gsub('[#?].*', '', url)), 'pdf')

  if (isTRUE(verbose)) verbose = ''
  res = system2(browser, c(
    extra_args, '--headless', paste0('--print-to-pdf=', shQuote(output)), url
  ), stdout = verbose, stderr = verbose)
  if (res != 0) stop(
    'Failed to print the document to PDF (for more info, re-run with the argument verbose = TRUE).'
  )

  invisible(output)
}
