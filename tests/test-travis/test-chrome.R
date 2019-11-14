library(testit)

assert('find_chrome() finds Chrome executable', {
  (nzchar(find_chrome()))
})
