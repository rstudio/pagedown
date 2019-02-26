# pagedown

[![Travis build status](https://travis-ci.org/rstudio/pagedown.svg?branch=master)](https://travis-ci.org/rstudio/pagedown)
[![Downloads from the RStudio CRAN mirror](https://cranlogs.r-pkg.org/badges/pagedown)](https://cran.r-project.org/package=pagedown)

<a href="https://github.com/rstudio/pagedown"><img src="https://user-images.githubusercontent.com/163582/51942716-66be4180-23dd-11e9-8dbc-fdb4f465d1c2.png" alt="pagedown logo" align="right" /></a>

Paginate the HTML Output of R Markdown with CSS for Print. You only need a modern web browser (e.g., Google Chrome) to generate PDF. No need to install LaTeX to get beautiful PDFs.

This R package stands on the shoulders of two giants to support typesetting with CSS for R Markdown documents: [Paged.js](https://gitlab.pagedmedia.org/tools/pagedjs) and [ReLaXed](https://github.com/RelaxedJS/ReLaXed) (we only borrowed some CSS from the ReLaXed repo and didn't really use the Node package).

You may install this package from Github:

```r
remotes::install_github('rstudio/pagedown')
```

This package requires a recent version of Pandoc (>= 2.2.3). If you use RStudio, you are recommended to install the [Preview version](https://www.rstudio.com/products/rstudio/download/preview/) (>= 1.2.1070), which has bundled Pandoc 2.x, otherwise you need to install Pandoc separately.

Below are some existing R Markdown output formats and examples.

## Paged HTML documents (`pagedown::html_paged`)

[![A paged HTML document](https://user-images.githubusercontent.com/163582/47673682-58b11880-db83-11e8-87fd-b5e753af7288.png)](https://pagedown.rbind.io)

### Journal of Statistical Software article (`pagedown::jss_paged`)

[![A JSS article](https://user-images.githubusercontent.com/19177171/51005498-5b46cb80-153f-11e9-9026-4b50a9f3d3f1.png)](https://pagedown.rbind.io/jss-paged/)

## Resume (`pagedown::html_resume`)

[![An HTML resume](https://user-images.githubusercontent.com/163582/46879762-7a34a500-ce0c-11e8-87e3-496f3577ff05.png)](https://pagedown.rbind.io/html-resume/)

## Posters

### `pagedown::poster_relaxed`

[![A poster of the ReLaXed style](https://user-images.githubusercontent.com/163582/47672385-e12dba00-db7f-11e8-92de-af94d5bab12f.jpg)](https://pagedown.rbind.io/poster-relaxed/)

### `pagedown::poster_jacobs`

[![A poster of the Jacobs University style](https://user-images.githubusercontent.com/163582/49780277-7b326780-fcd3-11e8-9eb6-69e46292158c.png)](https://pagedown.rbind.io/poster-jacobs/)

## Business cards (`pagedown::business_card`)

[![A business card](https://user-images.githubusercontent.com/163582/47741877-68933000-dc49-11e8-94f8-92724b67e9a6.png)](https://pagedown.rbind.io/business-card/)

## Letters (`pagedown::html_letter`)

[![A letter in HTML](https://user-images.githubusercontent.com/163582/47872372-61e8f200-dddc-11e8-839b-d8e8ef8f51eb.png)](https://pagedown.rbind.io/html-letter)

## Other examples

- "Template of Exec Summaries with pagedown" by Joshua David Barillas: https://github.com/jdbarillas/executive_summary

- Deepak Kumar Tanwar's CV: https://dktanwar.github.io/CV/ds.html

## Authors and contributors

The main authors of this package are Yihui Xie (RStudio) and Romain Lesur. Romain has received a grant from the Shuttleworth Foundation for his work on both Paged.js and **pagedown**.

[![Shuttleworth Funded](https://user-images.githubusercontent.com/163582/49319242-72ff4e80-f4c1-11e8-89fe-d8749355d261.jpg)](https://www.shuttleworthfoundation.org)

You can find [the full list of contributors of **pagedown** here](https://github.com/rstudio/pagedown/graphs/contributors). We always welcome new contributions. In particular, if you are familiar with CSS, we'd love to include your contributions of more creative and beautiful CSS stylesheets in this package. It is also very helpful if you don't know CSS but just tell us the creative and beautiful web pages you have seen, since other CSS experts may be able to port them into **pagedown**.
