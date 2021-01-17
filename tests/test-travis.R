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

if (!is.na(Sys.getenv('CI', NA))) {
  options(pagedown.remote.maxattempts = 100L)
  testit::test_pkg('pagedown', 'test-travis')
}
