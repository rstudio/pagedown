library(testit)

is_pdf = function(file) {
  identical(readBin(file, 'raw', 5L), charToRaw('%PDF-'))
}

assert('find_chrome() finds Chrome executable', {
  (nzchar(find_chrome()))
})

assert('chrome_print() works with an url', {
  (is_pdf(print_pdf('http://httpbin.org/html')))
})

assert('chrome_print() works with a local file path', {
  r_faq_html = file.path(R.home('doc'), 'manual', 'R-FAQ.html')

  (is_pdf(print_pdf(r_faq_html)))
})

assert('chrome_print() works with html_paged format', {
  (is_pdf(print_pdf('test-chrome.Rmd')))
})

assert('chrome_print() works with reveal.js presentations', {
  f = print_pdf('test-revealjs.Rmd')

  (is_pdf(f))

  (identical(pdftools::pdf_info(f)$pages, 5L))

  first_page_text_content = pdftools::pdf_text(f)[1]
  (identical(first_page_text_content, 'Test reveal.js'))
})
