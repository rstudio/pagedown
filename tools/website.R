setwd('inst/examples')

options(htmltools.dir.version = FALSE)

for (tpl in list.files('../rmarkdown/templates', full.names = TRUE)) {
  f = list.files(paste0(tpl, '/skeleton'), recursive = TRUE, full.names = TRUE)
  file.copy(f, '.')
  skel = list.files('.', '^skeleton[.]Rmd$')
  main_file = paste0(basename(tpl), '.Rmd')
  file.rename(skel, main_file)
  rmarkdown::render(main_file, output_options = list(self_contained = FALSE))
}

writeLines(c(
  'http://pagedown.netlify.com/* https://pagedown.rbind.io/:splat 301!',
  'http://pagedown.rbind.io/*    https://pagedown.rbind.io/:splat 301!'
), '_redirects')
