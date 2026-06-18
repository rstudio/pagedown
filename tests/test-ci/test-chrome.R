library(testit)

is_pdf = function(file) {
  identical(readBin(file, 'raw', 5L), charToRaw('%PDF-'))
}

run_promise = function(x) {
  # There's no easy way to test the promise object so it's based on Romain Lesur's code at
  # https://github.com/RLesur/crrri/blob/48b5c2c5e0d209d3742720d30ed91694a6e80c12/R/hold.R#L34-L66
  state <- new.env()
  state$pending = TRUE
  promises::then(
    x,
    onFulfilled = function(value) {
      state$pending = FALSE
      state$value = value
    },
    onRejected = function(error) {
      state$pending = FALSE
      state$reason = error
    }
  )
  while(state$pending) {
    later::run_now(all = FALSE)
  }
  if (!is.null(state$reason)) stop(state$reason)
  state$value
}

# Extract the PDF outline as a nested list of title/children, comparable across
# pdftools versions. pdftools >= 3.8.0 added an `is_open` field to pdf_toc(),
# which also shifted the entries from `[[2L]]` to the `children` element; we
# therefore select `children` by name and keep only `title`/`children`.
pdf_outline = function(file) {
  prune = function(x) lapply(x, function(node) list(
    title = node$title, children = prune(node$children)
  ))
  prune(pdftools::pdf_toc(file)$children)
}

assert('find_chrome() finds Chrome executable', {
  (nzchar(find_chrome()))
})

assert('chrome_print() works with an url', {
  (is_pdf(print_pdf('https://www.r-project.org')))
})

assert('chrome_print() works with a local file path', {
  r_faq_html = file.path(R.home('doc'), 'manual', 'R-FAQ.html')

  (is_pdf(print_pdf(r_faq_html)))
})

assert('chrome_print() supports PDF streaming', {
  r_faq_html = file.path(R.home('doc'), 'manual', 'R-FAQ.html')

  (is_pdf(print_pdf(r_faq_html, options = list(transferMode = 'ReturnAsStream'))))
})


assert('chrome_print() works with html_paged format', {
  (is_pdf(print_pdf('test-chrome.Rmd')))
})

assert('chrome_print() works with reveal.js presentations', {
  f = print_pdf('test-revealjs.Rmd')

  (is_pdf(f))

  # in theory it should be 5 pages; I don't know why it's 6 instead
  (pdftools::pdf_info(f)$pages %==% 7L)

  (pdftools::pdf_text(f)[1] %==% 'Test reveal.js\n')
})

assert('find_gs() finds Ghostscript executable', {
  (nzchar(find_gs()))
  (gs_available())
})

assert('chrome_print() generates expected outline', {
  f = print_pdf('test-outline.Rmd')

  (is_pdf(f))

  toc = pdf_outline(f)
  res = list(
    list(title = "1 Title 1", children = list()),
    list(
      title = "2 Title 2",
      children = list(
        list(title = "2.1 Title 2-1", children = list()),
        list(title = "2.2 Title 2-2", children = list(
          list(title = "2.2.1 Title 2-2-1", children = list()),
          list(title = "2.2.2 Title 2-2-2",children = list())
        ))
      )
    ),
    list(title = "3 \u4e2d\u6587", children = list()),
    list(title = "4 \u4e2d\u6587 \u5e26\u7a7a\u683c", children = list(
      list(title = "4.1 \u4e2d\u6587\u6b21\u7ea7\u6807\u9898", children = list())
    ))
  )

  (toc %==% res)

  # works for async
  f = run_promise(print_pdf('test-outline.Rmd', async = TRUE))
  (is_pdf(f))
  toc = pdf_outline(f)
  (toc %==% res)

  # works for output name with non-ASCII & white space
  output = tempfile(pattern = "\u4e2d \u6587")
  f = print_pdf('test-outline.Rmd', output = output)
  (is_pdf(f))
  toc = pdf_outline(f)
  (toc %==% res)

  # works for input name with non-ASCII & white space
  input = tempfile(pattern = "\u4e2d \u6587", fileext = '.Rmd')
  file.copy('test-outline.Rmd', input)
  f = print_pdf(input)
  (is_pdf(f))
  toc = pdf_outline(f)
  (toc %==% res)
})
