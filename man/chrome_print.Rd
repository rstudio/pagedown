% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/chrome.R
\name{chrome_print}
\alias{chrome_print}
\title{Print a web page to PDF or capture a screenshot using the headless Chrome}
\usage{
chrome_print(
  input,
  output = xfun::with_ext(input, format),
  wait = 2,
  browser = "google-chrome",
  format = c("pdf", "png", "jpeg"),
  options = list(),
  selector = "body",
  box_model = c("border", "content", "margin", "padding"),
  scale = 1,
  work_dir = tempfile(),
  timeout = 30,
  extra_args = c("--disable-gpu"),
  verbose = 0,
  async = FALSE,
  outline = gs_available(),
  encoding
)
}
\arguments{
\item{input}{A URL or local file path to an HTML page, or a path to a local
file that can be rendered to HTML via \code{rmarkdown::\link[rmarkdown]{render}()}
(e.g., an R Markdown document or an R script). If the \code{input} is to be
rendered via \code{rmarkdown::render()} and you need to pass any arguments
to it, you can pass the whole \code{render()} call to
\code{chrome_print()}, e.g., if you need to use the \code{params} argument:
\code{pagedown::chrome_print(rmarkdown::render('input.Rmd', params =
list(foo = 1:10)))}. This is because \code{render()} returns the HTML file,
which can be passed to \code{chrome_print()}.}

\item{output}{The output filename. For a local web page \file{foo/bar.html},
the default PDF output is \file{foo/bar.pdf}; for a remote URL
\file{https://www.example.org/foo/bar.html}, the default output will be
\file{bar.pdf} under the current working directory. The same rules apply
for screenshots.}

\item{wait}{The number of seconds to wait for the page to load before
printing (in certain cases, the page may not be immediately ready for
printing, especially there are JavaScript applications on the page, so you
may need to wait for a longer time).}

\item{browser}{Path to Google Chrome, Microsoft Edge or Chromium. This
function will try to find it automatically via \code{\link{find_chrome}()}
if the path is not explicitly provided and the environment variable
\code{PAGEDOWN_CHROME} is not set.}

\item{format}{The output format.}

\item{options}{A list of page options. See
\code{https://chromedevtools.github.io/devtools-protocol/tot/Page#method-printToPDF}
 for the full list of options for PDF output, and
\code{https://chromedevtools.github.io/devtools-protocol/tot/Page#method-captureScreenshot}
 for options for screenshots. Note that for PDF output, we have changed the
defaults of \code{printBackground} (\code{TRUE}),
\code{preferCSSPageSize} (\code{TRUE}) and when available
\code{transferMode} (\code{ReturnAsStream}) in this function.}

\item{selector}{A CSS selector used when capturing a screenshot.}

\item{box_model}{The CSS box model used when capturing a screenshot.}

\item{scale}{The scale factor used for screenshot.}

\item{work_dir}{Name of headless Chrome working directory. If the default
temporary directory doesn't work, you may try to use a subdirectory of your
home directory.}

\item{timeout}{The number of seconds before canceling the document
generation. Use a larger value if the document takes longer to build.}

\item{extra_args}{Extra command-line arguments to be passed to Chrome.}

\item{verbose}{Level of verbosity: \code{0} means no messages; \code{1} means
to print out some auxiliary messages (e.g., parameters for capturing
screenshots); \code{2} (or \code{TRUE}) means all messages, including those
from the Chrome processes and WebSocket connections.}

\item{async}{Execute \code{chrome_print()} asynchronously? If \code{TRUE},
\code{chrome_print()} returns a \code{\link[promises]{promise}} value (the
\pkg{promises} package has to be installed in this case).}

\item{outline}{If not \code{FALSE}, \code{chrome_print()} will add the
bookmarks to the generated \code{pdf} file, based on the table of contents
informations. This feature is only available for output formats based on
\code{\link{html_paged}}. It is enabled by default, as long as the
Ghostscript executable can be detected by \code{\link[tools]{find_gs_cmd}}.}

\item{encoding}{Not used. This argument is required by RStudio IDE.}
}
\value{
Path of the output file (invisibly). If \code{async} is \code{TRUE},
  this is a \code{\link[promises]{promise}} value.
}
\description{
Print an HTML page to PDF or capture a PNG/JPEG screenshot through the Chrome
DevTools Protocol. Google Chrome or Microsoft Edge (or Chromium on Linux)
must be installed prior to using this function.
}
\references{
\url{https://developer.chrome.com/blog/headless-chrome/}
}
