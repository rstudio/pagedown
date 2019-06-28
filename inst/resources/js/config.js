// Configuration script for paged.js

(function() {
  // Retrieve previous config object if defined
  window.PagedConfig = window.PagedConfig || {};
  const {before: beforePaged, after: afterPaged} = window.PagedConfig;

  function getPandocMeta() {
    const el = document.getElementById('pandoc-meta');
    if (el) {
      return JSON.parse(el.firstChild.data);
    } else {
      return {};
    }
  }

  function isString(value) {
    return typeof value === 'string' || value instanceof String;
  }

  function isArray(value) {
    return value && typeof value === 'object' && value.constructor === Array;
  }

  function insertCSS(text) {
    let style = document.createElement("style");
		style.type = "text/css";
		style.appendChild(document.createTextNode(text));
    document.head.appendChild(style);
  }

  function buildChapterNameStyleSheet(chapterName) {
    let text = '';
    if (isString(chapterName)) {
      text = '--chapter-name-before: "' + chapterName + '";';
    }
    if (isArray(chapterName)) {
      text = '--chapter-name-before: "' + chapterName[0] + '";';
      if(chapterName[1]) {
        text  = text + '--chapter-name-after: "' + chapterName[1] + '";';
      }
    }
    return ':root {' + text + '}';
  }

  window.PagedConfig.before = async () => {
    // Define CSS variables for internationalization
    const pandocMeta = getPandocMeta();
    const chapterName = pandocMeta["chapter_name"];

    if (chapterName) {
      const text = buildChapterNameStyleSheet(chapterName);
      insertCSS(text);
    }

    if (beforePaged) await beforePaged();
  }

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
