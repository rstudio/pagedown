// Configuration script for paged.js

(function() {
  // Retrieve MathJax loading function
  function getBeforeAsync() {
    if (typeof window.PagedConfig !== "undefined") {
      if (typeof window.PagedConfig.before !== "undefined") {
        return window.PagedConfig.before;
      }
    }
    return async () => {};
  }

  var runMathJax = getBeforeAsync();

  // bookdown uses ids of the form #fig:something #tab:something
  // Paged.js crashes when it looks for the page number of an id containing a
  // colon, see https://stackoverflow.com/questions/45110893/select-elements-by-attributes-with-colon
  // We need to sanitize the ids and the href
  async function sanitizeIds() {
    var ids = document.querySelectorAll('*[id*="\\:"]');
    var links = document.querySelectorAll('*[href*="\\:"]');
    for (var item of ids) {
      item.id = item.id.replace(/:/, "-");
    }
    for (var link of links) {
      link.href = link.getAttribute("href").replace(/:/, "-");
    }
  }

  // This function expands the links in the lists of figures or tables (loft)
  async function expandLinksInLoft() {
    var items = document.querySelectorAll('.lof li, .lot li');
    for (var item of items) {
      var anchor = item.firstChild;
      anchor.innerText = item.innerText;
      item.innerText = '';
      item.append(anchor);
    }
  }

  // This function add spans for leading symbols.
  async function addLeadersSpans() {
    var anchors = document.querySelectorAll('.toc a, .lof a, .lot a');
    for (var a of anchors) {
      a.innerHTML = a.innerHTML + '<span class="leaders"></span>';
    }
  }

  /* A factory returning a function that appends short titles spans.
     The text content of these spans are reused for running titles (see default.css).
     Argument: level - An integer between 1 and 6.
  */
  function appendShortTitleSpans(level) {
    return async () => {
      var divs = Array.from(document.getElementsByClassName('level' + level));

      async function addSpan(div) {
        var mainHeader = div.getElementsByTagName('h' + level)[0];
        var mainTitle = mainHeader.textContent;
        var runningTitle = 'shortTitle' in div.dataset ? div.dataset.shortTitle : mainTitle;
        var span = document.createElement('span');
        span.className = 'shorttitle' + level;
        span.innerText = runningTitle;
        span.style.display = "none";
        mainHeader.insertAdjacentElement('afterend', span);
        if (level == 1 && div.querySelector('.level2') === null) {
          var span2 = document.createElement('span');
          span2.className = 'shorttitle2';
          span2.innerText = ' ';
          span2.style.display = "none";
          span.insertAdjacentElement('afterend', span2);
        }
      }

      for (const div of divs) {
        await addSpan(div);
      }
    };
  }

  var appendShortTitles1 = appendShortTitleSpans(1);
  var appendShortTitles2 = appendShortTitleSpans(2);

  window.PagedConfig = {
    before: async () => {
      await sanitizeIds();
      await expandLinksInLoft();
      await Promise.all([
        addLeadersSpans(),
        appendShortTitles1(),
        appendShortTitles2()
      ]);
      await runMathJax();
    }
  };
})();
