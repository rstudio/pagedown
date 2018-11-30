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
#' @param wait The number of seconds to wait before deeming the page to be
#'   ready. Use a larger value if the page takes longer to load completely.
#' @param extra_args Extra command-line arguments to be passed to Chrome.
#' @param verbose Whether to show verbose command-line output.
#' @references
#' \url{https://developers.google.com/web/updates/2017/04/headless-chrome}
#' @return Path of the output file (invisibly).
#' @export
chrome_print = function(
  url, output = xfun::with_ext(url, 'pdf'), browser = 'google-chrome', wait = 10,
  extra_args = c('--disable-gpu'), verbose = FALSE
) {
  if (missing(browser)) browser = find_chrome() else {
    if (!file.exists(browser)) browser = Sys.which(browser)
  }
  if (!utils::file_test('-x', browser)) stop('The browser is not executable: ', browser)

  # remove hash/query parameters in url
  if (missing(output) && !file.exists(url))
    output = xfun::with_ext(basename(gsub('[#?].*', '', url)), 'pdf')
  output2 = normalizePath(output, mustWork = FALSE)
  if (!dir.exists(d <- dirname(output2)) && !dir.create(d, recursive = TRUE)) stop(
    'Cannot create the directory for the output file: ', d
  )

  # proxy settings
  extra_args = c(proxy_args(), extra_args)

  if (isTRUE(verbose)) verbose = ''

  res = system2(browser, c(
    paste0('--virtual-time-budget=', format(wait * 1000, scientific = FALSE)),
    extra_args, '--headless', paste0('--print-to-pdf=', shQuote(output2)), url
  ), stdout = verbose, stderr = verbose)
  if (res != 0) stop(
    'Failed to print the document (for more info, re-run with the argument verbose = TRUE).'
  )

  invisible(output)
}

find_chrome = function() {
  switch(
    .Platform$OS.type,
    windows = {
      res = tryCatch({
        unlist(utils::readRegistry('ChromeHTML\\shell\\open\\command', 'HCR'))
      }, error = function(e) '')
      res = unlist(strsplit(res, '"'))
      res = head(res[file.exists(res)], 1)
      if (length(res) != 1) stop(
        'Cannot find Google Chrome automatically from the Windows Registry Hive. ',
        "Please pass the full path of chrome.exe to the 'browser' argument."
      )
      res
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
  )
}

proxy_args = function() {
  # the order of the variables is important because the first non-empty variable is kept
  val = Sys.getenv(c('https_proxy', 'HTTPS_PROXY', 'http_proxy', 'HTTP_PROXY'))
  val = val[val != '']
  if (length(val) == 0) return()
  c(
    paste0('--proxy-server=', val[1]),
    paste0('--proxy-bypass-list=', paste(no_proxy_urls(), collapse = ';'))
  )
}

no_proxy_urls = function() {
  x = do.call(c, strsplit(Sys.getenv(c('no_proxy', 'NO_PROXY')), '[,;]'))
  x = c('localhost', '127.0.0.1', x)
  unique(x)
}
