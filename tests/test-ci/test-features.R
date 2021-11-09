library(testit)

assert('Page breaks work', {
  f = print_pdf('test-page-breaks.Rmd')
  (identical(pdftools::pdf_info(f)$pages, 5L))
})
