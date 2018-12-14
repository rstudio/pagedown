setwd('inst/examples')
for (tpl in list.files('../rmarkdown/templates', full.names = TRUE)) {
  f = list.files(tpl, '^skeleton[.]Rmd$', recursive = TRUE, full.names = TRUE)
  file.copy(f, paste0(basename(tpl), '.Rmd'))
}

options(htmltools.dir.version = FALSE)

for (f in list.files('.', '[.]Rmd$')) {
  rmarkdown::render(f, output_options = list(self_contained = FALSE))
}

writeLines(c(
  'http://pagedown.netlify.com/* https://pagedown.rbind.io/:splat 301!',
  'http://pagedown.rbind.io/*    https://pagedown.rbind.io/:splat 301!'
), '_redirects')
