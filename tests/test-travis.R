# run tests on Travis (these tests depend on Chrome)

print_pdf = function(input, output = tempfile(), ...) {
  chrome_print(
    input, output,
    # use --no-sandbox with travis
    # https://docs.travis-ci.com/user/chrome#sandboxing
    extra_args = c('--disable-gpu', '--no-sandbox'),
    ...
  )
}

if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
  options(pagedown.remote.maxattempts = 100L)
  testit::test_pkg('pagedown', 'test-travis')
}
