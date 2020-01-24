# CHANGES IN pagedown VERSION 0.8

## BUG FIXES

- In `chrome_print()`, fixed some connection problems to headless Chrome: in some situations, the R session tries to connect to headless Chrome before a target is created. Now, `chrome_print()` controls the target creation by connecting to the `Browser` endpoint (thanks, @gershomtripp, #158).  

- In `html_resume()` template, vertical space is removed when details are omitted (thanks, @mrajeev08, #161).

# CHANGES IN pagedown VERSION 0.7

## NEW FEATURES

- Added support for pagebreaks: in output formats which use **paged.js**, a pagebreak can be forced using the LaTeX commands `\newpage` and `\pagebreak` or using the CSS classes `page-break-before` and `page-break-after`.

- **reveal.js** presentations can be printed to PDF using `chrome_print()`. 

- Using RStudio, any R Markdown HTML output formats can be directly printed to PDF by adding the line `"knit: pagedown::chrome_print"` to the YAML header: this line modifies the behavior of the "Knit" button of RStudio and produce both HTML and PDF documents.

## BUG FIXES

- In `chrome_print()` with `async = FALSE`, the Chrome processes and the local web server are properly closed when the function exits. This regression was introduced in **pagedown** 0.6.

# CHANGES IN pagedown VERSION 0.6

## MINOR CHANGES

- Added support for MathJax in `html_resume` output format (thanks, @ginolhac, #146).

- The `chrome_print()` function internally uses a private event loop provided by `later` 1.0.0 when `async=FALSE` (thanks, @jcheng5, #127).

# CHANGES IN pagedown VERSION 0.5

## NEW FEATURES

- Added support for lines numbering in `html_paged()`: lines can be numbered using the top-level YAML parameter `number-lines` (thanks, @julientaq, #115 and #129).

- Added support for covers images in `html_paged()`: `html_paged()` gains two arguments, `front_cover` and `back_cover`, to insert images in the front and back covers. Textual contents can also be added in the covers using two special divs of classes `front-cover` and `back-cover` (thanks, @atusy, #134, #136 and #137).

- When `chrome_print()` is used with `verbose >= 1`, some auxiliary informations about Paged.js rendering are printed (number of pages and elapsed time).

- Added a `template` argument to the `business_card()` output format for passing a custom Pandoc template (thanks, @mariakharitonova, #135).

## BUG FIXES

- Remove duplicated footnotes in table of contents (thanks, @pzhaonet and @jdbarillas, #54).

# CHANGES IN pagedown VERSION 0.4

## BUG FIXES

- Fixed several bugs related to MathJax: local version of MathJax is now used when the `mathjax` parameter is set to `"local"` and self contained documents are rendered by default with MathJax without throwing any warning (#130).

- In `html_paged`, the nodes tree is sanitized before Paged.js splits the content into pages. This should avoid duplicated content observed when `break-after: avoid` and `break-before: avoid` are used (#131).

# CHANGES IN pagedown VERSION 0.3

## NEW FEATURES

- Added an `async` argument to `chrome_print()`. When `async = TRUE`, `chrome_print()` returns a `promises::promise` object. This allows `chrome_print()` to be used inside a Shiny App (thanks, @ColinFay, #91).

- Added the support for chapter prefix as in **bookdown**. Chapter of class `chapter` are prefixed with the word `Chapter`. This prefix can be changed for internationalization purpose (thanks, @brentthorne, #101 and #107).

- Added the support for lists of abbreviations. If the document contains `<abbr>` HTML elements, a list of abbreviations is automatically built (thanks, @brentthorne, #102 and #107).

- Added the new `thesis_paged` template (thanks, @brentthorne, #107).

## MAJOR CHANGES

- Paged.js is upgraded from version 0.1.28 to 0.1.32: Paged.js CSS variables are now prefixed with `pagedjs-`. For instance, `--width` is replaced by `--pagedjs-width`. Users' stylesheets that use Paged.js CSS variables need to be updated. Bleeds and crop marks are now supported. Several bugs are fixed.

## MINOR CHANGES

- The default stylesheet of `html_paged()` is updated to support the new argument `clean_highlight_tags` of `bookdown::html_document2()` introduced in **bookdown** 0.10 (thanks, @atusy, #100).

- In `chrome_print()` the connection between the R session and headless Chrome now uses the native websocket client provided by the **websocket** package. The previous workaround which used a websocket server, a websocket tunnel and a browser-based websocket client is removed (reverts #74). `chrome_print()` runs faster due to this simplification.

## BUG FIXES

- browser is forced to redraw the document after Paged.js finished. This will fix wrong page references observed with Chrome and RStudio 1.2.xxxx (#35 and #46, thanks, @petermeissner).  

- `jsonlite::toJSON()` is now used in `chrome_print()` for building all the JSON messages sent to headless Chromium/Chrome: this guarantees that the JSON strings are valid (thanks, @ColinFay, #85 and @cderv, #88).

- In `uri-to-fn.lua`, use a shallow copy of `PANDOC_VERSION`. This is required for Pandoc >= 2.7.3 which changes the type of `PANDOC_VERSION` (thanks, @andreaphsz, #111).

- Insert page numbers after page references (thanks @atusy, #120).

- With Pandoc 2.7.3, page numbers wrongly appear in code blocks.

# CHANGES IN pagedown VERSION 0.2

## MAJOR CHANGES

- The function `chrome_print()` has been significantly enhanced. Now it prints web pages and R Markdown documents to PDF through the Chrome DevTools Protocol instead of the simple command-line call (like in v0.1). It also supports capturing screenshots.


# CHANGES IN pagedown VERSION 0.1

## NEW FEATURES

- The first CRAN release. See more information about this package at: https://github.com/rstudio/pagedown.
