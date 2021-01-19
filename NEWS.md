# CHANGES IN pagedown VERSION 0.14

## MAJOR CHANGES

- Paged.js is upgraded from version 0.1.32 to 0.1.43. This update speeds up the rendering time and fixes several bugs (see also <https://www.pagedjs.org/posts/2020-02-25-weekly/>, <https://www.pagedjs.org/posts/2020-03-03-update-pagedjs-0-1-39/>, <https://www.pagedjs.org/posts/2020-04-01-pagedjs-0-1-40/> and <https://www.pagedjs.org/posts/2020-06-22-pagedjs-0-1-42/>) (#202).

## BUG FIXES

- The default value of the `counter-reset` CSS property is correctly set to 0 instead of 1 (see <https://developer.mozilla.org/en-US/docs/Web/CSS/counter-reset>). To reset a `page` CSS counter to 1, the following declaration must be used: `counter-reset: page 1` (#202).

- Numbered example lists (<https://pandoc.org/MANUAL.html#numbered-example-lists>) are correctly numbered (thanks, @atusy, #122 and #202).

- Periods are now supported in titles (thanks, @yves-amevoin and @martinschmelzer, #84, #185 and #202).

- Parts titles in the table of contents no longer crash `chrome_print()`.

- `chrome_print()` is now compatible with the stream transfer mode which can be used to generate large PDF files (#205).

- `chrome_print()` no longer ignores runtime exceptions in Chrome. An R warning is now raised when Chrome encounters a runtime exception (#203).

# CHANGES IN pagedown VERSION 0.13

## NEW FEATURES

- In `html_paged()`, the title of the list of abbreviations can now be modified with the `loa-title` field in the YAML header (thanks, @jtrecenti, #199).

## BUG FIXES

- The option `anchor_sections` is disabled internally. This option is for `rmarkdown::html_document()` to generate anchor links for sections and currently it does not work well for **pagedown** format for now (#195).

- In `chrome_print()`, fixed a bug when the R session temporary directory and the current directory are mounted on different Linux file systems. In that case, `chrome_print()` failed to add an outline to the PDF and raised the warning `cannot rename file ..., reason 'Invalid cross-device link'` (#193). 

# CHANGES IN pagedown VERSION 0.12

## BUG FIXES

- `chrome_print()` no longer ignores the Chrome DevTools event `Inspector.targetCrashed`. An R error is now raised when Chrome crashes (#190). 

# CHANGES IN pagedown VERSION 0.11

## NEW FEATURES

- `chrome_print()` now has a new argument `outline`, with which the user can generate the outline bookmarks for the PDF file. Note, this feature requires [Ghostscript](https://www.ghostscript.com) being installed and detected by `tools::find_gs_cmd()` (thanks, @shrektan, #174 and #179).

# CHANGES IN pagedown VERSION 0.10

## BUG FIXES

- In `html_resume()` template, avoid page breaks after section titles and inside subsections (thanks, @kevinrue, #170).

# CHANGES IN pagedown VERSION 0.9

## BUG FIXES

- In `html_resume()` template, an icon inserted using inline HTML in a section title takes precedence over the default icon and the `data-icon` property (thanks, @Tazinho, #168).

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
