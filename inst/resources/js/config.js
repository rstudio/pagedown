// Configuration script for paged.js

(function() {
  // Retrieve previous config object if defined
  window.PagedConfig = window.PagedConfig || {};
  const {before: beforePaged, after: afterPaged} = window.PagedConfig;

  // utils
  const insertCSS = text => {
    let style = document.createElement('style');
		style.type = 'text/css';
		style.appendChild(document.createTextNode(text));
    document.head.appendChild(style);
  };

  // Support for front and back covers images CSS variables
  const insertCSSForCover = type => {
    const links = document.querySelectorAll('link[id^=' + type + ']');
    if (!links.length) return;
    const re = new RegExp(type + '-\\d+');
    let text = ':root {--' + type + ': var(--' + type + '-1);';
    for (const link of links) {
      text += '--' + re.exec(link.id)[0] + ': url("' + link.href + '");';
    }
    text += '}';
    insertCSS(text);
  };

  window.PagedConfig.before = async () => {
    insertCSSForCover('front-cover');
    insertCSSForCover('back-cover');

    if (beforePaged) await beforePaged();
  };

  window.PagedConfig.after = (flow) => {
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
      pagedownListener(JSON.stringify({
        pagedjs: true,
        pages: flow.total,
        elapsedtime: flow.performance
      }));
    } else {
      // scroll to the last position before the page is reloaded
      window.scrollTo(0, sessionStorage.getItem('pagedown-scroll'));
    }
  };
})();
