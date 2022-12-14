# run tests on CI (these tests depend on Chrome)

print_pdf = function(input, output = tempfile(), ...) {
  chrome_print(input, output, ...)
}

if (!is.na(Sys.getenv('CI', NA))) {
  options(pagedown.remote.maxattempts = 100L)
  testit::test_pkg('pagedown', 'test-ci')
}
