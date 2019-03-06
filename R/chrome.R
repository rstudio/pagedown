#' Print a web page to PDF or capture a screenshot using the headless Chrome
#'
#' Print an HTML page to PDF or capture a PNG/JPEG screenshot through the Chrome
#' DevTools Protocol. Google Chrome (or Chromium on Linux) must be installed
#' prior to using this function.
#' @param input A URL or local file path to an HTML page, or a path to a local
#'   file that can be rendered to HTML via \code{rmarkdown::\link{render}()}
#'   (e.g., an R Markdown document or an R script).
#' @param output The output filename. For a local web page \file{foo/bar.html},
#'   the default PDF output is \file{foo/bar.pdf}; for a remote URL
#'   \file{https://www.example.org/foo/bar.html}, the default output will be
#'   \file{bar.pdf} under the current working directory. The same rules apply
#'   for screenshots.
#' @param wait The number of seconds to wait for the page to load before
#'   printing (in certain cases, the page may not be immediately ready for
#'   printing, especially there are JavaScript applications on the page, so you
#'   may need to wait for a longer time).
#' @param browser Path to Google Chrome or Chromium. This function will try to
#'   find it automatically via \code{\link{find_chrome}()} if the path is not
#'   explicitly provided.
#' @param format The output format.
#' @param options A list of page options. See
#'   \code{https://chromedevtools.github.io/devtools-protocol/tot/Page#method-printToPDF}
#'    for the full list of options for PDF output, and
#'   \code{https://chromedevtools.github.io/devtools-protocol/tot/Page#method-captureScreenshot}
#'    for options for screenshots. Note that for PDF output, we have changed the
#'   defaults of \code{printBackground} (\code{TRUE}) and
#'   \code{preferCSSPageSize} (\code{TRUE}) in this function.
#' @param selector A CSS selector used when capturing a screenshot.
#' @param box_model The CSS box model used when capturing a screenshot.
#' @param scale The scale factor used for screenshot.
#' @param work_dir Name of headless Chrome working directory. If the default
#'   temporary directory doesn't work, you may try to use a subdirectory of your
#'   home directory.
#' @param timeout The number of seconds before canceling the document
#'   generation. Use a larger value if the document takes longer to build.
#' @param extra_args Extra command-line arguments to be passed to Chrome.
#' @param verbose Level of verbosity: \code{0} means no messages; \code{1} means
#'   to print out some auxiliary messages (e.g., parameters for capturing
#'   screenshots); \code{2} (or \code{TRUE}) means all messages, including those
#'   from the Chrome processes and WebSocket connections.
#' @references
#' \url{https://developers.google.com/web/updates/2017/04/headless-chrome}
#' @return Path of the output file (invisibly).
#' @export
chrome_print = function(
  input, output = xfun::with_ext(input, format), wait = 2, browser = 'google-chrome',
  format = c('pdf', 'png', 'jpeg'), options = list(),
  selector = 'body', box_model = c('border', 'content', 'margin', 'padding'), scale = 1,
  work_dir = tempfile(), timeout = 30, extra_args = c('--disable-gpu'), verbose = 0
) {
  if (missing(browser)) browser = find_chrome() else {
    if (!file.exists(browser)) browser = Sys.which(browser)
  }
  if (!utils::file_test('-x', browser)) stop('The browser is not executable: ', browser)
  if (isTRUE(verbose)) verbose = 2
  if (verbose >= 1) message('Using the browser "', browser, '"')

  if (file.exists(input)) {
    is_html = function(x) grepl('[.]html?$', x)
    url = if (is_html(input)) input else rmarkdown::render(
      input, envir = parent.frame(), encoding = 'UTF-8'
    )
    if (!is_html(url)) stop(
      "The file '", url, "' should have the '.html' or '.htm' extension."
    )
    svr = servr::httd(
      dirname(url), daemon = TRUE, browser = FALSE, verbose = FALSE,
      port = random_port(), initpath = httpuv::encodeURIComponent(basename(url))
    )
    on.exit(svr$stop_server(), add = TRUE)
    url = svr$url
  } else url = input  # the input is not a local file; assume it is just a URL

  format = match.arg(format)
  # remove hash/query parameters in url
  if (missing(output) && !file.exists(input))
    output = xfun::with_ext(basename(gsub('[#?].*', '', url)), format)
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
    '--headless', '--no-first-run', '--no-default-browser-check', '--hide-scrollbars'
  ))

  debug_port = random_port()
  ps = processx::process$new(browser, c(
    paste0('--remote-debugging-port=', debug_port),
    paste0('--user-data-dir=', work_dir), extra_args
  ))
  on.exit({
    if (ps$is_alive()) ps$kill()
    unlink(work_dir, recursive = TRUE)
  }, add = TRUE)

  if (!is_remote_protocol_ok(debug_port))
    stop('A more recent version of Chrome is required. ')

  # a middleman app to send messages from R to the app's websocket, then from
  # there to the above Chrome process (messages come back in the same way); this
  # is mainly to unblock newer CRAN releases of pagedown because the websocket
  # package is not on CRAN (yet)
  app = ws_server(debug_port, browser, extra_args)
  on.exit(app$cleanup(), add = TRUE)

  ws = app$ws

  if ((format == 'pdf') && !all(c(missing(selector), missing(box_model), missing(scale))))
    warning('For "pdf" format, arguments `selector`, `box_model` and `scale` are ignored.', call. = FALSE)

  box_model = match.arg(box_model)

  t0 = Sys.time(); token = new.env(parent = emptyenv())
  print_page(ws, url, output2, wait, verbose, token, format, options, selector, box_model, scale)
  while (!isTRUE(token$done)) {
    if (!app$ps$is_alive()) stop('Chrome launched via httpuv crashed')
    if (!is.null(e <- token$error)) stop('Failed to generate output. Reason: ', e)
    if (as.numeric(difftime(Sys.time(), t0, units = 'secs')) > timeout) stop(
      'Failed to generate output in ', timeout, ' seconds (timeout).'
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
      for (i in c('google-chrome', 'chromium-browser', 'chromium')) {
        if ((res <- Sys.which(i)) != '') break
      }
      if (res == '') stop('Cannot find Chromium or Google Chrome')
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

is_remote_protocol_ok = function(debug_port, max_attempts = 15) {
  url = sprintf('http://127.0.0.1:%s/json/protocol', debug_port)
  for (i in 1:max_attempts) {
    remote_protocol = tryCatch(suppressWarnings(jsonlite::read_json(url)), error = function(e) NULL)
    if (!is.null(remote_protocol)) break
    if (i == max_attempts) stop('Cannot connect to headless Chrome. ')
    Sys.sleep(0.2)
  }

  required_commands = list(
    DOM = c('enable', 'getBoxModel', 'getDocument', 'querySelector'),
    Network = c('enable'),
    Page = c('addScriptToEvaluateOnNewDocument',
             'captureScreenshot',
             'enable',
             'navigate',
             'printToPDF'
    ),
    Runtime = c('enable', 'addBinding', 'evaluate')
  )

  remote_domains = sapply(remote_protocol$domains, `[[`, 'domain')
  if (!all(names(required_commands) %in% remote_domains))
    return(FALSE)

  required_events = list(
    Network = c('responseReceived'),
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

get_entrypoint = function(debug_port) {
  open_debuggers = jsonlite::read_json(
    sprintf('http://127.0.0.1:%s/json', debug_port), simplifyVector = TRUE
  )
  page = open_debuggers$webSocketDebuggerUrl[open_debuggers$type == 'page']
  if (length(page) == 0) stop('Cannot connect R to Chrome. Please retry.')
  page
}

print_page = function(
  ws, url, output, wait, verbose, token, format,
  options = list(), selector, box_model, scale
) {

  ws$onMessage(function(binary, text) {
    if (!is.null(token$error)) return(ws$close())
    if (verbose >= 2) message('Message received from headless Chrome: ', text)
    msg = jsonlite::fromJSON(text)
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
      # Command #4 received -> callback: command #5 Page.addScriptToEvaluateOnNewDocument
      ws$send(
        sprintf('{"id":5,"method":"Page.addScriptToEvaluateOnNewDocument","params":{"source":"%s"}}',
                paste0(readLines(pkg_resource('js', 'chrome_print.js')), collapse = ""))
      ),
      # Command #5 received -> callback: command #6 Page.Navigate
      ws$send(sprintf('{"id":6,"method":"Page.navigate","params":{"url":"%s"}}', url)),
      # Command #6 received - check if there is an error when navigating to url
      token$error <- msg$result$errorText,
      {
      # Command #7 received - Test if the html document uses the paged.js polyfill
      # if not, call the binding when fonts are ready
        if (!isTRUE(msg$result$result$value))
          ws$send('{"id":8,"method":"Runtime.evaluate","params":{"expression":"pagedownReady.then(() => {pagedownListener(\'\');})"}}')
      },
      # Command #8 received - No callback
      NULL,
      # Command #9 received -> callback: command #10 DOM.getDocument
      ws$send('{"id":10,"method":"DOM.getDocument"}'),
      # Command #10 received -> callback: command #11 DOM.querySelector
      ws$send(sprintf(
        '{"id":11,"method":"DOM.querySelector","params":{"nodeId":%i,"selector":"%s"}}',
        msg$result$root$nodeId,
        selector
      )), {
      # Command 11 received -> callback: command #12 DOM.getBoxModel
        if (msg$result$nodeId == 0) {
          token$error <- 'No element in the HTML page corresponds to the `selector` value.'
        } else {
          ws$send(sprintf('{"id":12,"method":"DOM.getBoxModel","params":{"nodeId":%i}}', msg$result$nodeId))
        }
      }, {
      # Command 12 received -> callback: command #13 Page.captureScreenshot
        opts = as.list(options)

        coords = msg$result$model[[box_model]]

        origin = as.list(coords[1:2])
        names(origin) = c('x', 'y')

        dims = as.list(coords[5:6] - coords[1:2])
        names(dims) = c('width', 'height')

        clip = c(origin, dims, list(scale = scale))
        opts = merge_list(list(clip = clip), opts)
        if (verbose >= 1) message(
          'Screenshot captured with the following value for the `options` parameter:\n',
          paste0(deparse(opts), collapse = '\n ')
        )
        opts$format = format

        ws$send(jsonlite::toJSON(list(
          id = 13, params = opts, method = 'Page.captureScreenshot'
        ), auto_unbox = TRUE, null = 'null'))
      }, {
      # Command #13 received (printToPDF or captureScreenshot) -> callback: save to file & close Chrome
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
        ws$send('{"id":7,"method":"Runtime.evaluate","params":{"expression":"!!window.PagedPolyfill"}}')
      }
      if (method == "Runtime.bindingCalled") {
        Sys.sleep(wait)
        opts = as.list(options)
        if (format == 'pdf') {
          opts = merge_list(list(printBackground = TRUE, preferCSSPageSize = TRUE), opts)
          ws$send(jsonlite::toJSON(list(
            id = 13, params = opts, method = 'Page.printToPDF'
          ), auto_unbox = TRUE, null = 'null'))
        } else {
          ws$send('{"id":9,"method":"DOM.enable"}')
        }
      }
    }
  })

  ws$send('{"id":1,"method":"Runtime.enable"}')

}


ws_server = function(port, browser, extra_args) {
  ws_url = get_entrypoint(port)
  ws_con = NULL
  app = list(
    call = function(req) {
      list(status = 200L, headers = list('Content-Type' = 'text/html'), body = sprintf(
        xfun::file_string(pkg_resource('html', 'ws-server.html')), ws_url
      ))
    },
    onWSOpen = function(ws) {
      # return websocket object when created
      ws_con <<- ws
    }
  )
  httpuv_port = random_port()
  server = httpuv::startServer('127.0.0.1', httpuv_port, app)
  ps = processx::process$new(
    command = browser,
    args = unique(c(
      paste0('--user-data-dir=', workdir <- tempfile()),
      paste0('--remote-debugging-port=', random_port()),
      proxy_args(),
      '--disable-gpu',
      if (xfun::is_windows()) '--no-sandbox',
      '--headless',
      '--no-first-run',
      '--no-default-browser-check',
      paste0('http://127.0.0.1:', httpuv_port),
      extra_args
    ))
  )
  while (is.null(ws_con)) {
    if (!ps$is_alive()) {
      # something went wrong with chrome while creating the websocket.
      httpuv::stopServer(server)
      stop('Chrome launched via httpuv crashed before creating websocket')
    }
    httpuv::service()
  }
  list(ws = ws_con, ps = ps, cleanup = function() {
    if (ps$is_alive()) ps$kill()
    httpuv::stopServer(server)
    unlink(workdir, recursive = TRUE)
  })
}
