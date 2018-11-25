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
#' @param work_dir Name of headless Chrome working directory. In order to avoid
#'   Chrome to fail, it is recommended to use a subdirectory of your home
#'   directory.
#' @param timeout The number of seconds before canceling the document
#'   generation. Use a larger value if the document takes longer to build.
#' @param extra_args Extra command-line arguments to be passed to Chrome.
#' @param verbose Whether to show verbose command-line output.
#' @param debug_port Headless Chrome remote debugging port.
#' @references
#' \url{https://developers.google.com/web/updates/2017/04/headless-chrome}
#' @return Path of the output file (invisibly).
#' @export
chrome_print = function(
  url, output = xfun::with_ext(url, 'pdf'), browser = 'google-chrome', work_dir,
  timeout = 60, extra_args = c('--disable-gpu'), verbose = FALSE, debug_port = 9222
) {
  if (missing(browser)) browser = switch(
    .Platform$OS.type,
    windows = {
      extra_args = c(extra_args, '--no-sandbox')
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
  ) else if (!file.exists(browser)) browser = Sys.which(browser)

  if (!utils::file_test('-x', browser)) stop('The browser is not executable: ', browser)

  # remove hash/query parameters in url
  if (missing(output) && !file.exists(url))
    output = xfun::with_ext(basename(gsub('[#?].*', '', url)), 'pdf')
  output2 = normalizePath(output, mustWork = FALSE)
  if (!dir.exists(d <- dirname(output2)) && !dir.create(d, recursive = TRUE)) stop(
    'Cannot create the directory for the output file: ', d
  )

  # proxy settings
  proxy = get_proxy()
  behind_proxy = nzchar(proxy)
  if (behind_proxy)
    extra_args = c(chrome_proxy_args(proxy), extra_args)

  if (isTRUE(verbose)) verbose = ''

  res = system2(browser, c(
    paste0('--remote-debugging-port=', debug_port),
    paste0('--user-data-dir=', work_dir),
    extra_args, '--headless', '--no-first-run', '--no-default-browser-check'
  ), stdout = verbose, stderr = verbose, timeout = timeout)

  if (!is_remote_protocol_ok(debug_port)) stop(
    'A more recent version of Chrome is required. '
  )

  entrypoints = get_entrypoints(debug_port)


  if (res != 0) stop(
    'Failed to print the document to PDF (for more info, re-run with the argument verbose = TRUE).'
  )

  invisible(output)
}

get_proxy = function() {
  # the order of the variables is important
  # because the first non empty variable is kept
  env_var = c('https_proxy', 'HTTPS_PROXY', 'http_proxy', 'HTTP_PROXY')
  values = Sys.getenv(env_var)
  values = values[nzchar(values)]
  if (length(values) > 0)
    values[1]
  else
    ''
}

chrome_proxy_args = function(proxy) {
  proxy_arg = paste0('--proxy-server=', proxy)

  no_proxy_urls = get_no_proxy_urls()
  no_proxy_string = paste(no_proxy_urls, collapse = ';')
  no_proxy_arg = paste0('--proxy-bypass-list=', no_proxy_string)

  c(proxy_arg, no_proxy_arg)
}

get_no_proxy_urls = function() {
  env_var = Sys.getenv(c('no_proxy', 'NO_PROXY'))
  no_proxy = do.call(c, strsplit(env_var, '[,;]'))
  no_proxy = c(default_no_proxy_urls(), no_proxy)
  unique(no_proxy)
}

default_no_proxy_urls = function() {
  c('localhost', '127.0.0.1')
}

is_remote_protocol_ok = function(debug_port, retry_delay = 0.2, max_attempts = 15) {
  url = sprintf('http://localhost:%s/json/protocol', debug_port)
  for (i in 1:max_attempts) {
    remote_protocol = tryCatch(jsonlite::read_json(url), error = function(e) NULL)
    if (!is.null(remote_protocol))
      break
    else
      if (i < max_attempts)
        Sys.sleep(retry_delay)
      else
        stop('Cannot connect to headless Chrome. ')
  }

  required_commands = list(
    Browser = c('close'),
    Page = c('enable', 'navigate'),
    Runtime = c('enable', 'addBinding')
  )

  remote_domains = sapply(remote_protocol$domains, function(x) x$domain)
  if (!all(required_domains %in% remote_domains))
    return(FALSE)

  remote_commands = sapply(names(required_commands), function(domain) {
    sapply(
      remote_protocol$domains[remote_domains %in% domain][[1]]$commands,
      function(x) x$name
    )
  })

  all(mapply(function(x, table) all(x %in% table), required_commands, remote_commands))
}

get_entrypoints = function(debug_port) {
  open_debuggers =
    jsonlite::read_json(sprintf('http://localhost:%s/json', debug_port), simplifyVector = TRUE)
  browser =
    jsonlite::read_json(sprintf('http://localhost:%s/json/version', debug_port), simplifyVector = TRUE)

  adresses = list(
    page_address = open_debuggers$webSocketDebuggerUrl[open_debuggers$type == 'page'],
    browser_address = browser$webSocketDebuggerUrl
  )

  if (any(sapply(adresses, function(x) length(x) == 0))) stop(
    'Cannot connect R to Chrome. ',
    'Please retry.'
  )

  adresses
}

