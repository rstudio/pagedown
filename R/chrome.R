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
#' @param async Execute \code{chrome_print()} asynchronously? If \code{TRUE},
#'   \code{chrome_print()} returns a \code{\link[promises]{promise}} value (the
#'   \pkg{promises} package has to be installed in this case).
#' @references
#' \url{https://developers.google.com/web/updates/2017/04/headless-chrome}
#' @return Path of the output file (invisibly). If \code{async} is \code{TRUE}, this
#'   is a \code{\link[promises]{promise}} value.
#' @export
chrome_print = function(
  input, output = xfun::with_ext(input, format), wait = 2, browser = 'google-chrome',
  format = c('pdf', 'png', 'jpeg'), options = list(), selector = 'body',
  box_model = c('border', 'content', 'margin', 'padding'), scale = 1, work_dir = tempfile(),
  timeout = 30, extra_args = c('--disable-gpu'), verbose = 0, async = FALSE
) {
  if (missing(browser)) browser = find_chrome() else {
    if (!file.exists(browser)) browser = Sys.which(browser)
  }
  if (!utils::file_test('-x', browser)) stop('The browser is not executable: ', browser)
  if (isTRUE(verbose)) verbose = 2
  if (verbose >= 1) message('Using the browser "', browser, '"')

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
  kill_chrome = function(...) {
    if (verbose >= 1) message('Closing browser')
    if (ps$is_alive()) ps$kill()
    if (verbose >= 1) message('Cleaning browser working directory')
    unlink(work_dir, recursive = TRUE)
  }
  on.exit(kill_chrome(), add = TRUE)

  if (!is_remote_protocol_ok(debug_port, verbose = verbose))
    stop('A more recent version of Chrome is required. ')

  # If !async, use a private event loop to drive the websocket. This is
  # necessary to separate later callbacks relevant to chrome_print, from any
  # other callbacks that have been scheduled before entering chrome_print; the
  # latter must not be invoked while inside of any synchronous function,
  # including chrome_print(async=FALSE).
  #
  # It's also critical that none of the code inside with_temp_loop waits on a
  # promise that originates from outside the with_temp_loop, as it will cause
  # the code inside to hang. And finally, no promise from inside with_temp_loop
  # should escape to the outside either, as with_temp_loop uses a truly "temp"
  # loop--it will be destroyed when with_temp_loop completes.
  #
  # Therefore, if async, it's important NOT to use a private event loop.
  with_temp_loop_maybe <- if (async) identity else later::with_temp_loop

  with_temp_loop_maybe({

    ws = websocket::WebSocket$new(get_entrypoint(debug_port), autoConnect = FALSE)
    ws$onClose(kill_chrome)
    ws$onError(kill_chrome)
    close_ws = function() {
      if (verbose >= 1) message('Closing websocket connection')
      ws$close()
    }

    svr = NULL # init svr variable
    if (file.exists(input)) {
      is_html = function(x) grepl('[.]html?$', x)
      url = if (is_html(input)) input else rmarkdown::render(
        input, envir = parent.frame(), encoding = 'UTF-8'
      )
      if (!is_html(url)) stop(
        "The file '", url, "' should have the '.html' or '.htm' extension."
      )
      svr = servr::httd(
        dirname(url), daemon = TRUE, browser = FALSE, verbose = verbose >= 1,
        port = random_port(), initpath = httpuv::encodeURIComponent(basename(url))
      )
      stop_server = function(...) {
        if (verbose >= 1) message('Closing local webserver')
        svr$stop_server()
      }
      on.exit(stop_server(), add = TRUE)
      ws$onClose(stop_server)
      ws$onError(stop_server)
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

    if ((format == 'pdf') && !all(c(missing(selector), missing(box_model), missing(scale))))
      warning('For "pdf" format, arguments `selector`, `box_model` and `scale` are ignored.', call. = FALSE)

    box_model = match.arg(box_model)

    pr = NULL
    res_fun = function(value) {} # default: do nothing
    rej_fun = function(reason) {} # default: do nothing
    if (async) {
      pr_print = promises::promise(function(resolve, reject) {
        res_fun <<- resolve
        rej_fun <<- function(reason) reject(paste('Failed to generate output. Reason:', reason))
      })
      pr_timeout = promises::promise(function(resolve, reject) {
        later::later(
          ~reject(paste('Failed to generate output in', timeout, 'seconds (timeout).')),
          timeout
        )
      })
      pr = promises::promise_race(pr_print, pr_timeout)
      promises::finally(pr, close_ws)
    }

    t0 = Sys.time(); token = new.env(parent = emptyenv())
    on.exit(close_ws())
    print_page(ws, url, output2, wait, verbose, token, format, options, selector, box_model, scale, res_fun, rej_fun)

    if (async) {
      on.exit()
      return(pr)
    }

    while (!isTRUE(token$done)) {
      if (!is.null(e <- token$error)) stop('Failed to generate output. Reason: ', e)
      if (as.numeric(difftime(Sys.time(), t0, units = 'secs')) > timeout) stop(
        'Failed to generate output in ', timeout, ' seconds (timeout).'
      )
      later::run_now(); if (!is.null(svr)) run_servr()
    }

    invisible(output)
  })
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
      for (i in c('google-chrome', 'chromium-browser', 'chromium', 'google-chrome-stable')) {
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

is_remote_protocol_ok = function(debug_port,
                                 verbose = 0) {
  url = sprintf('http://127.0.0.1:%s/json/protocol', debug_port)
  # can be specify with option, for ex. for CI specificity. see #117
  max_attempts = getOption("pagedown.remote.maxattempts", 20L)
  sleep_time = getOption("pagedown.remote.sleeptime", 0.5)
  if (verbose >= 1) message('Checking the remote connection in ', max_attempts, ' attempts.')
  for (i in seq_len(max_attempts)) {
    remote_protocol = tryCatch(suppressWarnings(jsonlite::read_json(url)), error = function(e) NULL)
    if (!is.null(remote_protocol)) {
      if (verbose >= 1) message('Connected at attempt ', i)
      break
    }
    if (i == max_attempts) stop('Cannot connect to headless Chrome after ', max_attempts, ' attempts')
    Sys.sleep(sleep_time)
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
  options = list(), selector, box_model, scale, resolve, reject
) {
  # init values
  coords = NULL

  ws$onOpen(function(event) {
    ws$send(to_json(list(id = 1, method = "Runtime.enable")))
  })

  ws$onMessage(function(event) {
    if (!is.null(token$error)) {
      ws$close()
      reject(token$error)
      return()
    }
    if (verbose >= 2) message('Message received from headless Chrome: ', event$data)
    msg = jsonlite::fromJSON(event$data)
    id = msg$id
    method = msg$method

    if (!is.null(token$error <- msg$error$message)) {
      ws$close()
      reject(token$error)
      return()
    }

    if (!is.null(id)) switch(
      id,
      # Command #1 received -> callback: command #2 Page.enable
      ws$send(to_json(list(id = 2, method = "Page.enable"))),
      # Command #2 received -> callback: command #3 Runtime.addBinding
      ws$send(to_json(list(
        id = 3, method = "Runtime.addBinding",
        params = list(name = "pagedownListener")
      ))),
      # Command #3 received -> callback: command #4 Network.Enable
      ws$send(to_json(list(id = 4, method  = "Network.enable"))),
      # Command #4 received -> callback: command #5 Page.addScriptToEvaluateOnNewDocument
      ws$send(to_json(list(
        id = 5, method = "Page.addScriptToEvaluateOnNewDocument",
        params = list(source = paste0(readLines(pkg_resource('js', 'chrome_print.js')), collapse = ""))
      ))),
      # Command #5 received -> callback: command #6 Page.Navigate
      ws$send(to_json(list(
        id = 6, method= "Page.navigate", params = list(url = url)
      ))),
      {
        # Command #6 received - check if there is an error when navigating to url
        if(!is.null(token$error <- msg$result$errorText)) {
          reject(token$error)
        }
      },
      {
        # Command #7 received - Test if the html document uses the paged.js polyfill
        # if not, call the binding when HTMLWidgets, MathJax and fonts are ready
        # (see inst/resources/js/chrome_print.js)
        if (!isTRUE(msg$result$result$value)) {
          ws$send(to_json(list(
            id = 8, method = "Runtime.evaluate",
            params = list(expression = "pagedownReady.then(() => {pagedownListener('{\"pagedjs\":false}');})")
          )))
        }
      },
      # Command #8 received - No callback
      NULL,
      # Command #9 received -> callback: command #10 DOM.getDocument
      ws$send(to_json(list(id = 10, method = "DOM.getDocument"))),
      # Command #10 received -> callback: command #11 DOM.querySelector
      ws$send(to_json(list(
        id = 11, method = "DOM.querySelector",
        params = list(nodeId = msg$result$root$nodeId, selector = selector)
      ))),
      {
        # Command 11 received -> callback: command #12 DOM.getBoxModel
        if (msg$result$nodeId == 0) {
          token$error <- 'No element in the HTML page corresponds to the `selector` value.'
          reject(token$error)
        } else {
          ws$send(to_json(list(
            id = 12, method = "DOM.getBoxModel",
            params = list(nodeId = msg$result$nodeId)
          )))
        }
      },
      {
        # Command 12 received -> callback: command #13 Emulation.setDeviceMetricsOverride
        coords <<- msg$result$model[[box_model]]
        device_metrics = list(
          width = ceiling(coords[5]),
          height = ceiling(coords[6]),
          deviceScaleFactor = 1,
          mobile = FALSE
        )
        ws$send(to_json(list(
          id = 13, params = device_metrics, method = 'Emulation.setDeviceMetricsOverride'
        )))
      },
      {
        # Command #13 received -> callback: command #14 Page.captureScreenshot
        opts = as.list(options)

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

        ws$send(to_json(list(
          id = 14, params = opts, method = 'Page.captureScreenshot'
        )))
      },
      {
        # Command #14 received (printToPDF or captureScreenshot) -> callback: save to file & close Chrome
        writeBin(jsonlite::base64_dec(msg$result$data), output)
        resolve(output)
        token$done = TRUE
      }
    )
    if (!is.null(method)) {
      if (method == "Network.responseReceived") {
        status = as.numeric(msg$params$response$status)
        if (status >= 400) {
          token$error = sprintf(
            'Failed to open %s (HTTP status code: %s)', msg$params$response$url, status
          )
          reject(token$error)
        }
      }
      if (method == "Page.loadEventFired") {
        ws$send(to_json(list(
          id = 7, method = "Runtime.evaluate",
          params = list(expression = "!!window.PagedPolyfill")
        )))
      }
      if (method == "Runtime.bindingCalled") {
        Sys.sleep(wait)
        opts = as.list(options)
        payload = jsonlite::fromJSON(msg$params$payload)
        if (verbose >= 1 && payload$pagedjs) {
          message("Rendered ", payload$pages, " pages in ", payload$elapsedtime, " milliseconds.")
        }
        if (format == 'pdf') {
          opts = merge_list(list(printBackground = TRUE, preferCSSPageSize = TRUE), opts)
          ws$send(to_json(list(
            id = 14, params = opts, method = 'Page.printToPDF'
          )))
        } else {
          ws$send(to_json(list(id = 9, method = "DOM.enable")))
        }
      }
    }
  })

  ws$connect()
}
