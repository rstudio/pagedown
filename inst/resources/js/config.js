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

  // Util function for front and back covers images
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

  const insertPageBreaksCSS = () => {
    insertCSS(`
    .page-break-after {break-after: page;}
    .page-break-before {break-before: page;}
    `);
  };

  window.PagedConfig.before = async () => {
    // Front and back covers support
    let frontCover = document.querySelector('.front-cover');
    let backCover = document.querySelector('.back-cover');
    if (frontCover) document.body.prepend(frontCover);
    if (backCover) document.body.append(backCover);
    insertCSSForCover('front-cover');
    insertCSSForCover('back-cover');
    insertPageBreaksCSS();

    if (beforePaged) await beforePaged();
  };

  // from https://stackoverflow.com/q/21647928
  const toUTF16BE = x => {
    let res = '';
    for (i=0; i < x.length; i++) {
      let hex = x.charCodeAt(i).toString(16);
      hex = ('000' + hex).slice(-4);
      res += hex
    }
    res = 'feff' + res ;
    return res;
  }

  const findPage = el => {
    while (el.parentElement) {
      el = el.parentElement;
      if (el.getAttribute('data-page-number')) {
        return parseInt(el.getAttribute('data-page-number'));
      }
    }
    return null;
  };

  const tocEntriesInfos = ul => {
    let result = []; // where we store the results
    // if there is no element, return an empty array 
    if (!ul) {
      return result;
    }
    const tocEntries = ul.children; // tocEntries are 'li' elements

    for (const li of tocEntries) {
      // get the title and encode it in UTF16BE (pdfmark is encoded in UTF16BE with BOM)
      const title = toUTF16BE(li.querySelector('a').textContent);

      // get the page number
      const href = li.querySelector('a').getAttribute('href');
      const el = document.querySelector(href);
      const page = findPage(el);

      // get the children
      children = tocEntriesInfos(li.querySelector('ul'));

      result.push({
        title: title,
        page: page,
        children: children
      });
    }

    return result;
  };
  window.PagedConfig.after = (flow) => {
    // force redraw, see https://github.com/rstudio/pagedown/issues/35#issuecomment-475905361
    // and https://stackoverflow.com/a/24753578/6500804
    document.body.style.display = 'none';
    document.body.offsetHeight;
    document.body.style.display = '';

    // run previous PagedConfig.after function if defined
    if (afterPaged) afterPaged(flow);

    // pagedownListener is a binding added by the chrome_print function
    // this binding exists only when chrome_print opens the html file
    if (window.pagedownListener) {
      // the html file is opened for printing
      // call the binding to signal to the R session that Paged.js has finished
      const tocList = flow.source.querySelector('.toc > ul');
      const tocInfos = tocEntriesInfos(tocList);
      pagedownListener(JSON.stringify({
        pagedjs: true,
        pages: flow.total,
        elapsedtime: flow.performance,
        tocInfos: tocInfos
      }));
      return;
    }
    if (sessionStorage.getItem('pagedown-scroll')) {
      // scroll to the last position before the page is reloaded
      window.scrollTo(0, sessionStorage.getItem('pagedown-scroll'));
      return;
    }
    if (window.location.hash) {
      const id = window.location.hash.replace(/^#/, '');
      document.getElementById(id).scrollIntoView({behavior: 'smooth'});
    }
  };
})();
