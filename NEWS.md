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
