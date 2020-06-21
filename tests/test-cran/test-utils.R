library(testit)

assert('pkg_resource() finds files under the resources dir of the package', {
  (dir.exists(pkg_resource(c('css', 'js'))))

  res = lua_filters('loft.lua', 'footnotes.lua')
  (sum(res == '--lua-filter') == 2)
  (length(res) == 4)
})

assert('check_css() validates CSS file paths', {
  (is.null(check_css(c('default', 'letter'))))
  (has_error(check_css('default2'), silent = TRUE))
})

assert('gen_toc_gs() works', {
  (gen_toc_gs(list()) %==% NULL)

  toc = list(list(title = 'a', page = 3, children = list()))
  res = '[/Count 0 /Title <a> /Page 3 /OUT pdfmark'

  (gen_toc_gs(toc) %==% res)

  toc = list(
    list(title = 'a', page = 3, children = list(
      list(title = 'a-1', page = 5, children = list()),
      list(title = 'a-2', page = 8, children = list(
        list(title = 'a-2-1', page = 9, children = list()),
        list(title = 'a-2-2', page = 10, children = list())
      ))
    )),
    list(title = 'b', page = 20, children = list())
  )
  res = c(
    "[/Count 2 /Title <a> /Page 3 /OUT pdfmark",
    "[/Count 0 /Title <a-1> /Page 5 /OUT pdfmark",
    "[/Count 2 /Title <a-2> /Page 8 /OUT pdfmark",
    "[/Count 0 /Title <a-2-1> /Page 9 /OUT pdfmark",
    "[/Count 0 /Title <a-2-2> /Page 10 /OUT pdfmark",
    "[/Count 0 /Title <b> /Page 20 /OUT pdfmark"
  )

  (gen_toc_gs(toc) %==% res)
})

