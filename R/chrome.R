#' Print a web page to PDF or capture a screenshot using the headless Chrome
#'
#' Print an HTML page to PDF or capture a PNG/JPEG screenshot through the Chrome
#' DevTools Protocol. Google Chrome or Microsoft Edge (or Chromium on Linux)
#' must be installed prior to using this function.
#' @param input A URL or local file path to an HTML page, or a path to a local
#'   file that can be rendered to HTML via \code{rmarkdown::\link{render}()}
#'   (e.g., an R Markdown document or an R script). If the \code{input} is to be
#'   rendered via \code{rmarkdown::render()} and you need to pass any arguments
#'   to it, you can pass the whole \code{render()} call to
#'   \code{chrome_print()}, e.g., if you need to use the \code{params} argument:
#'   \code{pagedown::chrome_print(rmarkdown::render('input.Rmd', params =
#'   list(foo = 1:10)))}. This is because \code{render()} returns the HTML file,
#'   which can be passed to \code{chrome_print()}.
#' @param output The output filename. For a local web page \file{foo/bar.html},
#'   the default PDF output is \file{foo/bar.pdf}; for a remote URL
#'   \file{https://www.example.org/foo/bar.html}, the default output will be
#'   \file{bar.pdf} under the current working directory. The same rules apply
#'   for screenshots.
#' @param wait The number of seconds to wait for the page to load before
#'   printing (in certain cases, the page may not be immediately ready for
#'   printing, especially there are JavaScript applications on the page, so you
#'   may need to wait for a longer time).
#' @param browser Path to Google Chrome, Microsoft Edge or Chromium. This
#'   function will try to find it automatically via \code{\link{find_chrome}()}
#'   if the path is not explicitly provided and the environment variable
#'   \code{PAGEDOWN_CHROME} is not set.
#' @param format The output format.
#' @param options A list of page options. See
#'   \code{https://chromedevtools.github.io/devtools-protocol/tot/Page#method-printToPDF}
#'    for the full list of options for PDF output, and
#'   \code{https://chromedevtools.github.io/devtools-protocol/tot/Page#method-captureScreenshot}
#'    for options for screenshots. Note that for PDF output, we have changed the
#'   defaults of \code{printBackground} (\code{TRUE}),
#'   \code{preferCSSPageSize} (\code{TRUE}) and when available
#'   \code{transferMode} (\code{ReturnAsStream}) in this function.
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
#' @param outline If not \code{FALSE}, \code{chrome_print()} will add the
#'   bookmarks to the generated \code{pdf} file, based on the table of contents
#'   informations. This feature is only available for output formats based on
#'   \code{\link{html_paged}}. It is enabled by default, as long as the
#'   Ghostscript executable can be detected by \code{\link[tools]{find_gs_cmd}}.
#' @param encoding Not used. This argument is required by RStudio IDE.
#' @references
#' \url{https://developer.chrome.com/blog/headless-chrome/}
#' @return Path of the output file (invisibly). If \code{async} is \code{TRUE},
#'   this is a \code{\link[promises]{promise}} value.
#' @export
chrome_print = function(
  input, output = xfun::with_ext(input, format), wait = 2, browser = 'google-chrome',
  format = c('pdf', 'png', 'jpeg'), options = list(), selector = 'body',
  box_model = c('border', 'content', 'margin', 'padding'), scale = 1, work_dir = tempfile(),
  timeout = 30, extra_args = c('--disable-gpu'), verbose = 0, async = FALSE,
  outline = gs_available(), encoding
) {
  is_rstudio_knit =
    !interactive() && !is.na(Sys.getenv('RSTUDIO', NA)) &&
    !missing(encoding) && length(match.call()) == 3
  if (is_rstudio_knit) verbose = 1

  format = match.arg(format)

  if (missing(browser) && is.na(browser <- Sys.getenv('PAGEDOWN_CHROME', NA))) {
    browser = find_chrome()
  } else {
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

  debug_port = servr::random_port(NULL)
  log_file = if (getOption('pagedown.chrome.log', FALSE)) {
    sprintf('chrome-stderr-%s.log', format(Sys.time(), "%Y-%m-%d_%H-%M-%S"))
  }
  ps = processx::process$new(browser, c(
    paste0('--remote-debugging-port=', debug_port),
    paste0('--user-data-dir=', work_dir), extra_args
  ), stderr = log_file)
  kill_chrome = function(...) {
    if (verbose >= 1) message('Closing browser')
    if (ps$is_alive()) ps$kill()
    if (verbose >= 1) message('Cleaning browser working directory')
    unlink(work_dir, recursive = TRUE)
  }
  on.exit(kill_chrome(), add = TRUE)

  remote_protocol_ok = is_remote_protocol_ok(debug_port, verbose = verbose)
  stream_pdf_available = isTRUE(xfun::attr(remote_protocol_ok, 'stream_pdf_available'))

  if (!remote_protocol_ok)
    stop('A more recent version of Chrome is required. ')

  if (format == 'pdf' && stream_pdf_available)
    options = merge_list(list(transferMode = 'ReturnAsStream'), as.list(options))

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

    ws = websocket::WebSocket$new(get_entrypoint(debug_port, verbose), autoConnect = FALSE)
    ws$onClose(kill_chrome)
    ws$onError(kill_chrome)
    close_ws = function() {
      if (verbose >= 1) message('Closing websocket connection')
      ws$close()
    }

    svr = NULL # init svr variable
    if (file.exists(input)) {
      is_html = function(x) grepl('[.]html?$', x)
      with_msg_maybe = if (is_rstudio_knit) suppressMessages else identity
      url = if (is_html(input)) input else with_msg_maybe(rmarkdown::render(
        input, envir = parent.frame(), encoding = 'UTF-8'
      ))
      if (!is_html(url)) stop(
        "The file '", url, "' should have the '.html' or '.htm' extension."
      )
      svr = servr::httd(
        dirname(url), daemon = TRUE, browser = FALSE, verbose = verbose >= 1,
        port = servr::random_port(NULL), initpath = httpuv::encodeURIComponent(basename(url))
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

    # remove hash/query parameters in url
    if (missing(output) && !file.exists(input))
      output = xfun::with_ext(basename(gsub('[#?].*', '', url)), format)
    output2 = normalizePath(output, mustWork = FALSE)
    # try to remove the file and throw a clear error if it still exists as it may be locked
    if (!suppressWarnings(file.remove(output2)) && xfun::file_exists(output2)) {
      stop(
        "The file '", output, "' cannot be overwritten",
        if (format == "pdf") " (may be locked by a PDF reader?)", "."
      )
    }
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
    on.exit({
      close_ws()
      kill_chrome()
      if (!is.null(svr)) stop_server()
    })
    print_page(ws, url, output2, wait, verbose, token, format, options, selector, box_model, scale, outline, res_fun, rej_fun)

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

    if (is_rstudio_knit) message('\nOutput created: ', basename(output))

    invisible(output)
  })
}

gen_toc_gs = function(toc) {
  to_gs = function(x) {
    stopifnot(setequal(names(x), c('title', 'page', 'children')))
    template = "[/Count %d /Title <%s> /Page %d /OUT pdfmark"
    title = x$title
    page = x$page
    count = length(x$children)
    out = sprintf(template, count, title, page)
    if (any(count > 0L)) {
      children = lapply(x$children, to_gs)
      out = c(out, unlist(children, use.names = FALSE))
    }
    out
  }
  unlist(lapply(toc, to_gs), use.names = FALSE)
}

find_gs = function() {
  gs = tools::find_gs_cmd()
  # according to the doc of tools::find_gs_cmd, gs should always be a string
  unname(gs)
}

gs_available = function() {
  nzchar(find_gs())
}

add_outline = function(input, toc_infos, verbose) {
  gs_content = gen_toc_gs(toc_infos)
  # when TOC doesn't exist, gs_content will be null
  if (is.null(gs_content)) return(invisible(input))
  gs_file = tempfile(); on.exit(unlink(gs_file), add = TRUE)
  writeLines(gs_content, con = gs_file)
  if (!gs_available()) stop(
    'Cannot find GhostScript executable automatically. ',
    "Please pass the full path of the GhostScript executable ",
    "to the environment variable 'R_GSCMD'. ",
    "See ?tools::find_gs_cmd for more details."
  )
  output = tempfile(fileext = '.pdf'); on.exit(unlink(output), add = TRUE)
  input2 = input
  if (!xfun::is_ascii(input2)) {
    # this is needed when input contain non-ASCII characters
    input2 = tempfile(fileext = '.pdf'); on.exit(unlink(input2), add = TRUE)
    file.copy(input, input2)
  }
  args = c('-o', output, '-sDEVICE=pdfwrite', '-dPDFSETTINGS=/prepress', input2, gs_file)
  if (verbose < 2) args = c('-q', args)
  gs_out = system2(find_gs(), shQuote(args))
  if (gs_out == 0) {
    file.copy(output, input, overwrite = TRUE)
  } else {
    warning('GhostScript fails to add the outlines', call. = FALSE)
  }
  invisible(input)
}

#' Find Google Chrome, Microsoft Edge or Chromium in the system
#'
#' On Windows, this function tries to find Chrome or Edge from the registry. On
#' macOS, it returns a hard-coded path of Chrome under \file{/Applications}. On
#' Linux, it searches for \command{chromium-browser} and \command{google-chrome}
#' from the system's \var{PATH} variable.
#' @return A character string.
#' @export
find_chrome = function() {
  switch(
    .Platform$OS.type,
    windows = {
      res = unlist(lapply(c('ChromeHTML', 'MSEdgeHTM'), function(x) {
        res = tryCatch({
          unlist(utils::readRegistry(sprintf('%s\\shell\\open\\command', x), 'HCR'))
        }, error = function(e) '')
        res = unlist(strsplit(res, '"'))
        res = head(res[file.exists(res)], 1)
      }))
      if (length(res) < 1) stop(
        'Cannot find Google Chrome or Edge automatically from the Windows Registry Hive. ',
        "Please pass the full path of chrome.exe or msedge.exe to the 'browser' argument ",
        "or to the environment variable 'PAGEDOWN_CHROME'."
      )
      res[1]
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
  if (verbose >= 1) message('Trying to find headless Chrome in ', max_attempts, ' attempts')
  for (i in seq_len(max_attempts)) {
    remote_protocol = tryCatch(suppressWarnings(jsonlite::read_json(url)), error = function(e) NULL)
    if (!is.null(remote_protocol)) {
      if (verbose >= 1) message('Headless Chrome found at attempt ', i)
      break
    }
    if (i == max_attempts) stop('Cannot find headless Chrome after ', max_attempts, ' attempts')
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
    Runtime = c('enable', 'addBinding', 'evaluate'),
    Target = c('attachToTarget', 'createTarget')
  )

  remote_domains = sapply(remote_protocol$domains, `[[`, 'domain')
  if (!all(names(required_commands) %in% remote_domains))
    return(FALSE)

  required_events = list(
    Inspector = c('targetCrashed'),
    Network = c('responseReceived'),
    Page = c('loadEventFired'),
    Runtime = c('bindingCalled', 'exceptionThrown')
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

  if (!all(mapply(function(x, table) all(x %in% table), required_commands, remote_commands),
      mapply(function(x, table) all(x %in% table), required_events, remote_events)
  ))
    return(FALSE)

  stream_pdf_available = 'transferMode' %in% sapply(
    remote_protocol[['domains']][remote_domains == 'Page'][[1]][['commands']][remote_commands[['Page']] == 'printToPDF'][[1]][['parameters']],
    `[[`, 'name'
  )
  res = TRUE
  attr(res, 'stream_pdf_available') = stream_pdf_available

  res
}

get_entrypoint = function(debug_port, verbose) {
  version_infos = jsonlite::read_json(
    sprintf('http://127.0.0.1:%s/json/version', debug_port), simplifyVector = TRUE
  )
  browser = version_infos$webSocketDebuggerUrl
  if (length(browser) == 0) stop("Cannot find 'Browser' websocket URL. Please retry.")
  if (verbose >= 1)
    message('Browser version: ', version_infos$Browser)
  browser
}

print_page = function(
  ws, url, output, wait, verbose, token, format,
  options = list(), selector, box_model, scale, outline, resolve, reject
) {
  # init values
  session_id = NULL
  coords = NULL
  toc_infos = NULL
  stream_handle = NULL
  con = NULL

  ws$onOpen(function(event) {
    # Create a new Target (tab)
    ws$send(to_json(list(
      id = 1, method = 'Target.createTarget',
      params = list(url = 'about:blank')
    )))
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
      # Command #1 received -> callback: command #2 Target.attachToTarget in flat mode
      ws$send(to_json(list(
        id = 2, method = 'Target.attachToTarget',
        params = list(targetId = msg$result$targetId, flatten = TRUE)
      ))),
      # Command #2 received -> store the sessionId; callback: command #3 Runtime.enable
      {
        session_id <<- msg$result$sessionId
        ws$send(to_json(list(
          id = 3, sessionId = session_id, method = 'Runtime.enable'
        )))
      },
      # Command #3 received -> callback: command #4 Page.enable
      ws$send(to_json(list(
        id = 4, sessionId = session_id, method = 'Page.enable'
      ))),
      # Command #4 received -> callback: command #5 Runtime.addBinding
      ws$send(to_json(list(
        id = 5, sessionId = session_id, method = "Runtime.addBinding",
        params = list(name = "pagedownListener")
      ))),
      # Command #5 received -> callback: command #6 Network.Enable
      ws$send(to_json(list(
        id = 6, sessionId = session_id, method  = 'Network.enable'
      ))),
      # Command #6 received -> callback: command #7 Page.addScriptToEvaluateOnNewDocument
      ws$send(to_json(list(
        id = 7, sessionId = session_id, method = "Page.addScriptToEvaluateOnNewDocument",
        params = list(source = paste0(readLines(pkg_resource('js', 'chrome_print.js')), collapse = ""))
      ))),
      # Command #7 received -> callback: command #8 Page.Navigate
      ws$send(to_json(list(
        id = 8, sessionId = session_id, method= 'Page.navigate',
        params = list(url = url)
      ))),
      {
        # Command #8 received - check if there is an error when navigating to url
        if(!is.null(token$error <- msg$result$errorText)) {
          reject(token$error)
        }
      },
      {
        # Command #9 received - Test if the html document uses the paged.js polyfill
        # if not, call the binding when HTMLWidgets, MathJax and fonts are ready
        # (see inst/resources/js/chrome_print.js)
        if (!isTRUE(msg$result$result$value)) {
          ws$send(to_json(list(
            id = 10, sessionId = session_id, method = "Runtime.evaluate",
            params = list(expression = "pagedownReady.then(() => {pagedownListener('{\"pagedjs\":false}');})")
          )))
        }
      },
      # Command #10 received - No callback
      NULL,
      # Command #11 received -> callback: command #12 DOM.getDocument
      ws$send(to_json(list(id = 12, sessionId = session_id, method = "DOM.getDocument"))),
      # Command #12 received -> callback: command #13 DOM.querySelector
      ws$send(to_json(list(
        id = 13, sessionId = session_id, method = "DOM.querySelector",
        params = list(nodeId = msg$result$root$nodeId, selector = selector)
      ))),
      {
        # Command 13 received -> callback: command #14 DOM.getBoxModel
        if (msg$result$nodeId == 0) {
          token$error <- 'No element in the HTML page corresponds to the `selector` value.'
          reject(token$error)
        } else {
          ws$send(to_json(list(
            id = 14, sessionId = session_id, method = "DOM.getBoxModel",
            params = list(nodeId = msg$result$nodeId)
          )))
        }
      },
      {
        # Command 14 received -> callback: command #15 Emulation.setDeviceMetricsOverride
        coords <<- msg$result$model[[box_model]]
        device_metrics = list(
          width = ceiling(coords[5]),
          height = ceiling(coords[6]),
          deviceScaleFactor = 1,
          mobile = FALSE
        )
        ws$send(to_json(list(
          id = 15, sessionId = session_id, method = 'Emulation.setDeviceMetricsOverride',
          params = device_metrics
        )))
      },
      {
        # Command #15 received -> callback: command #16 Page.captureScreenshot
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
          id = 16, sessionId = session_id, method = 'Page.captureScreenshot',
          params = opts
        )))
      },
      {
        # Command #16 received (printToPDF or captureScreenshot)
        # if data are received -> callback: save to file & close Chrome
        # if a stream handle is received -> callback: command #17 IO.read
        if (is.null(stream_handle <<- msg$result$stream)) {
          writeBin(jsonlite::base64_dec(msg$result$data), output)
          if (!isFALSE(outline) && length(toc_infos)) add_outline(output, toc_infos, verbose)
          resolve(output)
          token$done = TRUE
        } else {
          if (verbose >= 1) message('Receiving PDF from a stream')
          # open a connection
          con <<- file(output, 'wb')
          # read the first chunk of the stream
          ws$send(to_json(list(
            id = 17, sessionId = session_id, method = 'IO.read',
            params = list(handle = stream_handle)
          )))
        }
      },
      {
        # Command #17 received
        # if there is another chunk to read -> callback: IO.read
        # if EOF -> callback: command #18 IO.close
        if (verbose >= 1) message('    stream chunk received')
        if (isTRUE(msg$result$base64Encoded)) {
          writeBin(jsonlite::base64_dec(msg$result$data), con)
        } else {
          writeBin(msg$result$data, con)
        }

        if (isTRUE(msg$result$eof)) {
          if (verbose >= 1) message(
            'No more stream chunk to read\n    closing stream'
          )
          close(con)
          ws$send(to_json(list(
            id = 18, sessionId = session_id, method = 'IO.close',
            params = list(handle = stream_handle)
          )))
        } else {
          # read another chunk
          ws$send(to_json(list(
            id = 17, sessionId = session_id, method = 'IO.read',
            params = list(handle = stream_handle)
          )))
        }
      },
      {
        # Command #18 received -> callback: add outline & close Chrome
        if (!isFALSE(outline) && length(toc_infos)) add_outline(output, toc_infos, verbose)
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
      if (method == 'Inspector.targetCrashed') {
        token$error = paste(
          'Chrome crashed.',
          'This may be caused by insufficient resources.',
          'Please, try to add "--disable-dev-shm-usage" to the `extra_args` argument.'
        )
        reject(token$error)
      }
      if (method == 'Runtime.exceptionThrown') {
        warning(
          'A runtime exception has occured while executing JavaScript\n',
          '  Runtime exception message:\n    ',
          msg$params$exceptionDetails$exception$description,
          call. = FALSE, immediate. = TRUE
        )
      }
      if (method == "Page.loadEventFired") {
        ws$send(to_json(list(
          id = 9, sessionId = session_id, method = 'Runtime.evaluate',
          params = list(expression = "!!window.PagedPolyfill")
        )))
      }
      if (method == "Runtime.bindingCalled") {
        Sys.sleep(wait)
        opts = as.list(options)
        payload = jsonlite::fromJSON(msg$params$payload, simplifyVector = FALSE)
        toc_infos <<- payload$tocInfos
        if (verbose >= 1 && payload$pagedjs) {
          message("Rendered ", payload$pages, " pages in ", payload$elapsedtime, " milliseconds.")
        }
        if (format == 'pdf') {
          opts = merge_list(list(printBackground = TRUE, preferCSSPageSize = TRUE), opts)
          ws$send(to_json(list(
            id = 16, sessionId = session_id, params = opts, method = 'Page.printToPDF'
          )))
        } else {
          ws$send(to_json(list(id = 11, sessionId = session_id, method = "DOM.enable")))
        }
      }
    }
  })

  ws$connect()
}
