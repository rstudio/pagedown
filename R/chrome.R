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

  if (.Platform$OS.type == 'windows')
    extra_args = c(extra_args, '--no-sandbox')

  if (!utils::file_test('-x', browser)) stop('The browser is not executable: ', browser)

  # remove hash/query parameters in url
  if (missing(output) && !file.exists(url))
    output = xfun::with_ext(basename(gsub('[#?].*', '', url)), 'pdf')
  output2 = normalizePath(output, mustWork = FALSE)
  if (!dir.exists(d <- dirname(output2)) && !dir.create(d, recursive = TRUE)) stop(
    'Cannot create the directory for the output file: ', d
  )

  # check that work_dir does not exist because it will be deleted at the end
  work_dir2 = normalizePath(work_dir, mustWork = FALSE)
  if (isTRUE(dir.exists(work_dir2))) stop(
    paste('The directory', work_dir, 'already exists.')
  )

  # proxy settings
  proxy = get_proxy()
  behind_proxy = nzchar(proxy)
  if (behind_proxy)
    extra_args = c(chrome_proxy_args(proxy), extra_args)

  if (isTRUE(verbose)) verbose = ''

  headless_ps = processx::process$new(browser, c(
    paste0('--remote-debugging-port=', debug_port),
    paste0('--user-data-dir=', work_dir2),
    extra_args, '--headless', '--no-first-run', '--no-default-browser-check'
  ))

  if (!is_remote_protocol_ok(debug_port, headless_ps, work_dir2)) {
    on.exit(close_chrome(headless_ps, work_dir2))
    stop('A more recent version of Chrome is required. ')
  }

  ws = websocket::WebSocket$new(get_entrypoint(debug_port, headless_ps, work_dir2))
  print_pdf(headless_ps, ws, work_dir2, url, output2, !nzchar(verbose), timeout)

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

chrome_proxy_args = function(
  proxy
) {
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

is_remote_protocol_ok = function(
  debug_port, headless_ps, work_dir, retry_delay = 0.2, max_attempts = 15
) {
  url = sprintf('http://localhost:%s/json/protocol', debug_port)
  for (i in 1:max_attempts) {
    remote_protocol = tryCatch(jsonlite::read_json(url), error = function(e) NULL)
    if (!is.null(remote_protocol))
      break
    else
      if (i < max_attempts)
        Sys.sleep(retry_delay)
      else {
        on.exit(close_chrome(headless_ps, work_dir))
        stop('Cannot connect to headless Chrome. ')
      }
  }

  remote_domains = sapply(remote_protocol$domains, function(x) x$domain)
  if (!all(names(required_commands()) %in% remote_domains))
    return(FALSE)

  remote_commands = sapply(names(required_commands()), function(domain) {
    sapply(
      remote_protocol$domains[remote_domains %in% domain][[1]]$commands,
      function(x) x$name
    )
  })

  remote_events =  sapply(names(required_events()), function(domain) {
    sapply(
      remote_protocol$domains[remote_domains %in% domain][[1]]$events,
      function(x) x$name
    )
  })

  all(mapply(function(x, table) all(x %in% table), required_commands(), remote_commands),
      mapply(function(x, table) all(x %in% table), required_events(), remote_events)
  )
}

get_entrypoint = function(
  debug_port, headless_ps, work_dir
) {
  open_debuggers =
    jsonlite::read_json(sprintf('http://localhost:%s/json', debug_port), simplifyVector = TRUE)
  page = open_debuggers$webSocketDebuggerUrl[open_debuggers$type == 'page']

  if (length(page) == 0) {
    on.exit(close_chrome(headless_ps, work_dir))
    stop(
      'Cannot connect R to Chrome. ',
      'Please retry.'
    )
  }

  page
}

print_pdf <- function(
  headless_ps, ws, work_dir, url, output, verbose, timeout
) {
  later::later(function() if (ws$readyState() < 2) ws$close(), delay = timeout)

  ws$onOpen(function(event) {
    ws$send('{"id":1,"method":"Runtime.enable"}')
  })

  ws$onMessage(function(event) {
    if (isTRUE(verbose))
      cat('Message received from headless Chrome:', event$data, '\n')
    msg = jsonlite::fromJSON(event$data)
    id = msg$id
    method = msg$method

    if (!is.null(msg$error)) {
      cat('Chrome error while rendering the PDF:', event$data, '\n')
      later::later(function() ws$close(), delay = 0.2)
    }

    if (!is.null(id)) switch(
      id,
      # Command #1 received -> calback: command #2 Page.enable
      ws$send('{"id":2,"method":"Page.enable"}'),
      # Command #2 received -> callback: command #3 Runtime.addBinding
      ws$send('{"id":3,"method":"Runtime.addBinding","params":{"name":"pagedownListener"}}'),
      # Command #3 received -> callback: command #4 Page.navigate
      ws$send(sprintf('{"id":4,"method":"Page.navigate","params":{"url":"%s"}}', url)),
      # Command #4 received - No callback
      NULL, {
      # Command #5 received - Test if the html document use the paged.js polyfill
        if (!isTRUE(msg$result$result$value))
          ws$send('{"id":6,"method":"Page.printToPDF","params":{"printBackground":true,"preferCSSPageSize":true}}')
      }, {
      # Command #6 received (printToPDF) -> callback: save to PDF file & close Chrome
        writeBin(jsonlite::base64_dec(msg$result$data), output)
        later::later(function() ws$close(), delay = 0.2)
      }
    )
    if (!is.null(method)) {
      if (method == "Page.domContentEventFired") {
        ws$send('{"id":5,"method":"Runtime.evaluate","params":{"expression":"!!window.PagedPolyfill"}}')
      }
      if (method == "Runtime.bindingCalled")
        ws$send('{"id":6,"method":"Page.printToPDF","params":{"printBackground":true,"preferCSSPageSize":true}}')
    }
  })

  ws$onClose(function(event) {
    later::later(function() close_chrome(headless_ps, work_dir), delay = 0.2)
  })
}

close_chrome = function(headless_ps, work_dir) {
  if (headless_ps$is_alive())
    killed <- headless_ps$kill()
  later::later(function() unlink(work_dir, recursive = TRUE), delay = 0.2)
}

required_commands = function() {
  list(
    Page = c('enable', 'navigate', 'printToPDF'),
    Runtime = c('enable', 'addBinding', 'evaluate')
  )
}

required_events = function() {
  list(
    Page = c('domContentEventFired'),
    Runtime = c('bindingCalled')
  )
}

