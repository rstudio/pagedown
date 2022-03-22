library(testit)

assert('Page breaks work', {
  f = print_pdf('test-page-breaks.Rmd')
  (identical(pdftools::pdf_info(f)$pages, 5L))
})

assert('lot / lof are inserted correctly', {
  # This test is tied to skeleton.Rmd for html-paged template
  # Check when skeleton.Rmd is modified
  if (xfun::loadable("xml2")) {
    dir.create(tmp_dir <- tempfile())
    xfun::in_dir(tmp_dir, {
      # use included template
      rmarkdown::draft("test.Rmd", "html-paged", "pagedown", edit = FALSE)
      res = rmarkdown::render("test.Rmd", quiet = TRUE)
    })
    content <- xml2::read_html(res, encoding = "UTF-8")
    # correctly in TOC
    toc <- xml2::xml_find_all(content, "//div[@id='TOC']")
    toc_lot <- xml2::xml_find_all(toc, "ul/li/a[@href='#LOT']")
    (length(toc_lot) == 1)
    (xml2::xml_text(toc_lot) == "List of Tables")
    toc_lof <- xml2::xml_find_all(toc, "ul/li/a[@href='#LOF']")
    (length(toc_lof) == 1)
    (xml2::xml_text(toc_lof) == "List of Figures")
    # Correctly in top body
    main <- xml2::xml_find_all(content, "//div[contains(@class, 'main')]")
    divs <- xml2::xml_find_all(main, "div[@id]")
    (xml2::xml_attr(divs[1], 'id') == "LOT")
    (length(xml2::xml_find_all(divs[1], 'ul/li/a[contains(@href, "md-tab")]')) == 1L)
    (length(xml2::xml_find_all(divs[1], 'ul/li/a[contains(@href, "simple-tab")]')) == 1L)
    (xml2::xml_attr(divs[2], 'id') == "LOF")
    (length(xml2::xml_find_all(divs[2], 'ul/li/a[contains(@href, "md-fig")]')) == 1L)
    (length(xml2::xml_find_all(divs[2], 'ul/li/a[contains(@href, "simple-graphic")]')) == 1L)

    # Change titles
    xfun::in_dir(tmp_dir, {
      xfun::gsub_file("test.Rmd", pattern = "^---$",
                      replacement = "---\nlot-title: Custom LOT\nlof-title: Custom LOF")
      res = rmarkdown::render("test.Rmd", quiet = TRUE)
    })
    content <- xml2::read_html(res)
    # correctly in TOC
    toc <- xml2::xml_find_all(content, "//div[@id='TOC']")
    toc_lot <- xml2::xml_find_all(toc, "ul/li/a[@href='#LOT']")
    (length(toc_lot) == 1)
    (xml2::xml_text(toc_lot) == "Custom LOT")
    toc_lof <- xml2::xml_find_all(toc, "ul/li/a[@href='#LOF']")
    (length(toc_lof) == 1)
    (xml2::xml_text(toc_lof) == "Custom LOF")
    # Correctly in top body
    main <- xml2::xml_find_all(content, "//div[contains(@class, 'main')]")
    h1 <- xml2::xml_find_all(main, "div/h1")
    (xml2::xml_text(h1[1]) == "Custom LOT")
    (xml2::xml_text(h1[2]) == "Custom LOF")

    # cleaning
    unlink(tmp_dir, recursive = TRUE)
  }
})
