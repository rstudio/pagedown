# run tests on Travis (these tests depend on Chrome)

print_pdf = function(input) {
  chrome_print(
    input, tempfile(),
    # use --no-sandbox with travis
    # https://docs.travis-ci.com/user/chrome#sandboxing
    extra_args = c('--disable-gpu', '--no-sandbox')
  )
}

if (!is.na(Sys.getenv('CI', NA))) testit::test_pkg('pagedown', 'test-travis')
