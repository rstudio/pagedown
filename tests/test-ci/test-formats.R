library(testit)
test_format <- function(template, output_options = NULL, skip = NULL) {

  # don't run on CRAN due to complicated dependencies (Pandoc)
  if (!identical(Sys.getenv("NOT_CRAN"), "true")) return()
  # skip if requested
  if (!is.null(skip) && isTRUE(skip)) return()

  # work in a temp directory
  dir <- tempfile()
  dir.create(dir)
  oldwd <- setwd(dir)
  on.exit({
    setwd(oldwd)
    unlink(dir, recursive = TRUE)
  }, add = TRUE)

  # create a draft of the format
  testdoc <- paste0(template,".Rmd")
  rmarkdown::draft(
    testdoc, template,
    package = "pagedown",
    create_dir = FALSE, edit = FALSE
  )

  message('Rendering the template for ', template, ' format...',
          if(!is.null(output_options)) " (with output options)")
  output_file <- rmarkdown::render(testdoc, output_options = output_options, quiet = TRUE)
  assert(paste(template, "format works"), {
    file.exists(output_file)
  })
}

templates <- dir(system.file("rmarkdown", "templates", package = "pagedown"))

for (template in templates) test_format(template)



