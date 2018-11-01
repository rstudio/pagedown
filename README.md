# pagedown

[![Travis build status](https://travis-ci.org/rstudio/pagedown.svg?branch=master)](https://travis-ci.org/rstudio/pagedown)

Paginate the HTML Output of R Markdown with CSS for Print. You only need a modern web browser (e.g., Google Chrome) to generate PDF. No need to install LaTeX to get beautiful PDFs.

This R package stands on the shoulders of two giants to support typesetting with CSS for R Markdown documents: [Paged.js](https://gitlab.pagedmedia.org/tools/pagedjs) and [ReLaXed](https://github.com/RelaxedJS/ReLaXed) (we only borrowed some CSS from the ReLaXed repo and didn't really use the Node package).

This package is still [very young](https://github.com/rstudio/pagedown/graphs/contributors). Please be warned that things are still subject to change. For those who are brave and curious, you may install the package from Github:

```r
remotes::install_github('rstudio/pagedown')
```

This package requires a recent version of Pandoc (>= 2.2.3). If you use RStudio, you are recommended to install the [Preview version](https://www.rstudio.com/products/rstudio/download/preview/) (>= 1.2.1070), which has bundled Pandoc 2.3.1, otherwise you need to install Pandoc separately.

Below are some existing R Markdown output formats and examples.

## Paged HTML documents (`pagedown::html_paged`)

[![A paged HTML document](https://user-images.githubusercontent.com/163582/47673682-58b11880-db83-11e8-87fd-b5e753af7288.png)](https://pagedown.rbind.io)

## Resume (`pagedown::html_resume`)

[![An HTML resume](https://user-images.githubusercontent.com/163582/46879762-7a34a500-ce0c-11e8-87e3-496f3577ff05.png)](https://pagedown.rbind.io/html-resume/)

## Posters (`pagedown::poster_relaxed`)

[![A poster of the ReLaXed style](https://user-images.githubusercontent.com/163582/47672385-e12dba00-db7f-11e8-92de-af94d5bab12f.jpg)](https://pagedown.rbind.io/poster-relaxed/)

## Business cards (`pagedown::business_card`)

[![A business card](https://user-images.githubusercontent.com/163582/47741877-68933000-dc49-11e8-94f8-92724b67e9a6.png)](https://pagedown.rbind.io/business-card/)

## Letters (`pagedown::html_letter`)

[![A letter in HTML](https://user-images.githubusercontent.com/163582/47872372-61e8f200-dddc-11e8-839b-d8e8ef8f51eb.png)](https://pagedown.rbind.io/html-letter)
