# run tests on Travis (these tests depend on Chrome)
if (!is.na(Sys.getenv('CI', NA))) testit::test_pkg('tinytex', 'test-travis')
