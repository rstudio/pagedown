library(testit)

assert('find_chrome() finds Chrome executable', {
  (grepl("google-chrome-stable", find_chrome()))
})
