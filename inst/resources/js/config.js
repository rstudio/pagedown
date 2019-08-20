// Configuration script for paged.js

(function() {
  // Retrieve previous config object if defined
  window.PagedConfig = window.PagedConfig || {};
  const afterPaged = window.PagedConfig.after;

  window.PagedConfig.after = () => {
    // force redraw, see https://github.com/rstudio/pagedown/issues/35#issuecomment-475905361
    // and https://stackoverflow.com/a/24753578/6500804
    document.body.style.display = 'none';
    document.body.offsetHeight;
    document.body.style.display = '';

    // run previous PagedConfig.after function if defined
    if (afterPaged) afterPaged();

    // pagedownListener is a binding added by the chrome_print function
    // this binding exists only when chrome_print opens the html file
    if (window.pagedownListener) {
      // the html file is opened for printing
      // call the binding to signal to the R session that Paged.js has finished
      pagedownListener('');
    } else {
      // scroll to the last position before the page is reloaded
      window.scrollTo(0, sessionStorage.getItem('pagedown-scroll'));
    }
  };
})();
