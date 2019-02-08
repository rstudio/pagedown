#' Print a web page to PDF using the headless Chrome (experimental)
#'
#' This is a wrapper function to execute the command \command{chrome --headless
#' --print-to-pdf url}. Google Chrome (or Chromium on Linux) must be installed
#' prior to using this function.
#' @param url A URL or local file path to a web page.
#' @param output The (PDF) output filename. For a local web page
#'   \file{foo/bar.html}, the default PDF output is \file{foo/bar.pdf}; for a
#'   remote URL \file{https://www.example.org/foo/bar.html}, the default output
#'   will be \file{bar.pdf} under the current working directory.
#' @param wait The number of seconds to wait for the page to load before
#'   printing to PDF (in certain cases, the page may not be immediately ready
#'   for printing, especially there are JavaScript applications on the page, so
#'   you may need to wait for a longer time).
#' @param browser Path to Google Chrome or Chromium. This function will try to
#'   find it automatically via \code{\link{find_chrome}()} if the path is not
#'   explicitly provided.
#' @param work_dir Name of headless Chrome working directory. If the default
#'   temporary directory doesn't work, you may try to use a subdirectory of your
#'   home directory.
#' @param timeout The number of seconds before canceling the document
#'   generation. Use a larger value if the document takes longer to build.
#' @param extra_args Extra command-line arguments to be passed to Chrome.
#' @param verbose Whether to show verbose websocket connexion to headless
#'   Chrome.
#' @references
#' \url{https://developers.google.com/web/updates/2017/04/headless-chrome}
#' @return Path of the output file (invisibly).
#' @export
chrome_print = function(
  url, output = xfun::with_ext(url, 'pdf'), wait = 2, browser = 'google-chrome',
  work_dir = tempfile(), timeout = 30, extra_args = c('--disable-gpu'), verbose = FALSE
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

  # check that work_dir does not exist because it will be deleted at the end
  if (dir.exists(work_dir)) stop('The directory ', work_dir, ' already exists.')
  work_dir = normalizePath(work_dir, mustWork = FALSE)

  # for windows, use the --no-sandbox option
  extra_args = unique(c(
    extra_args, proxy_args(), if (xfun::is_windows()) '--no-sandbox',
    '--headless', '--no-first-run', '--no-default-browser-check'
  ))

  debug_port = servr::random_port()
  ps = processx::process$new(browser, c(
    paste0('--remote-debugging-port=', debug_port),
    paste0('--user-data-dir=', work_dir), extra_args
  ))
  on.exit({
    if (ps$is_alive()) ps$kill()
    unlink(work_dir, recursive = TRUE)
  }, add = TRUE)

  if (!is_remote_protocol_ok(debug_port, ps)) {
    stop('A more recent version of Chrome is required. ')
  }

  ws = websocket::WebSocket$new(get_entrypoint(debug_port, ps))
  on.exit(if (ws$readyState() < 2) ws$close(), add = TRUE)

  t0 = Sys.time(); token = new.env(parent = emptyenv())
  print_pdf(ps, ws, url, output2, wait, verbose, token)
  while (!isTRUE(token$done)) {
    if (!is.null(e <- token$error)) stop('Failed to generate PDF. Reason: ', e)
    if (as.numeric(difftime(Sys.time(), t0, units = 'secs')) > timeout) stop(
      'Failed to generate PDF in ', timeout, ' seconds (timeout).'
    )
    later::run_now()
  }

  invisible(output)
}

#' Find Google Chrome or Chromium in the system
#'
#' On Windows, this function tries to find Chrome from the registry. On macOS,
#' it returns a hard-coded path of Chrome under \file{/Applications}. On Linux,
#' it searches for \command{chromium-browser} and \command{google-chrome} from
#' the system's \var{PATH} variable.
#' @return A character string.
#' @export
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

is_remote_protocol_ok = function(debug_port, ps, max_attempts = 15) {
  url = sprintf('http://127.0.0.1:%s/json/protocol', debug_port)
  for (i in 1:max_attempts) {
    remote_protocol = tryCatch(suppressWarnings(jsonlite::read_json(url)), error = function(e) NULL)
    if (!is.null(remote_protocol)) break
    if (i == max_attempts) stop('Cannot connect to headless Chrome. ')
    Sys.sleep(0.2)
  }

  required_commands = list(
    Page = c('enable', 'navigate', 'printToPDF'),
    Runtime = c('enable', 'addBinding', 'evaluate')
  )

  remote_domains = sapply(remote_protocol$domains, `[[`, 'domain')
  if (!all(names(required_commands) %in% remote_domains))
    return(FALSE)

  required_events = list(
    Page = c('loadEventFired'),
    Runtime = c('bindingCalled')
  )

  remote_commands = sapply(names(required_commands), function(domain) {
    sapply(
      remote_protocol$domains[remote_domains %in% domain][[1]]$commands,
      `[[`, 'name'
    )
  })

  remote_events =  sapply(names(required_events), function(domain) {
    sapply(
      remote_protocol$domains[remote_domains %in% domain][[1]]$events,
      `[[`, 'name'
    )
  })

  all(mapply(function(x, table) all(x %in% table), required_commands, remote_commands),
      mapply(function(x, table) all(x %in% table), required_events, remote_events)
  )
}

get_entrypoint = function(debug_port, ps) {
  open_debuggers = jsonlite::read_json(
    sprintf('http://127.0.0.1:%s/json', debug_port), simplifyVector = TRUE
  )
  page = open_debuggers$webSocketDebuggerUrl[open_debuggers$type == 'page']
  if (length(page) == 0) stop('Cannot connect R to Chrome. Please retry.')
  page
}

print_pdf = function(ps, ws, url, output, wait, verbose, token) {

  ws$onOpen(function(event) {
    ws$send('{"id":1,"method":"Runtime.enable"}')
  })

  ws$onMessage(function(event) {
    if (!is.null(token$error)) return(ws$close())
    if (verbose) message('Message received from headless Chrome: ', event$data)
    msg = jsonlite::fromJSON(event$data)
    id = msg$id
    method = msg$method

    if (!is.null(token$error <- msg$error$message)) return(ws$close())

    if (!is.null(id)) switch(
      id,
      # Command #1 received -> callback: command #2 Page.enable
      ws$send('{"id":2,"method":"Page.enable"}'),
      # Command #2 received -> callback: command #3 Runtime.addBinding
      ws$send('{"id":3,"method":"Runtime.addBinding","params":{"name":"pagedownListener"}}'),
      # Command #3 received -> callback: command #4 Network.Enable
      ws$send('{"id":4,"method":"Network.enable"}'),
      # Command #4 received - callback: command #4 Page.Navigate
      ws$send(sprintf('{"id":5,"method":"Page.navigate","params":{"url":"%s"}}', url)),
      # Command #5 received - check if there is an error when navigating to url
      token$error <- msg$result$errorText,
      {
      # Command #6 received - Test if the html document uses the paged.js polyfill
      # if not, call the binding when fonts are ready
        if (!isTRUE(msg$result$result$value))
          ws$send('{"id":7,"method":"Runtime.evaluate","params":{"expression":"document.fonts.ready.then(() => {pagedownListener(\'\');})"}}')
      },
      # Command #7 received - No callback
      NULL, {
      # Command #8 received (printToPDF) -> callback: save to PDF file & close Chrome
        writeBin(jsonlite::base64_dec(msg$result$data), output)
        token$done = TRUE
      }
    )
    if (!is.null(method)) {
      if (method == "Network.responseReceived") {
        status = as.numeric(msg$params$response$status)
        if (status >= 400) token$error = sprintf(
          "Failed to open %s (HTTP status code: %s)", msg$params$response$url, status
        )
      }
      if (method == "Page.loadEventFired") {
        ws$send('{"id":6,"method":"Runtime.evaluate","params":{"expression":"!!window.PagedPolyfill"}}')
      }
      if (method == "Runtime.bindingCalled") {
        Sys.sleep(wait)
        ws$send('{"id":8,"method":"Page.printToPDF","params":{"printBackground":true,"preferCSSPageSize":true}}')
      }
    }
  })

}
