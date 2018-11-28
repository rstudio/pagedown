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

  var windowLoaded = new Promise(function($){window.addEventListener('load', $, {once: true})});

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
        if (!mainHeader) return;
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
      await expandLinksInLoft();
      await Promise.all([
        addLeadersSpans(),
        appendShortTitles1(),
        appendShortTitles2()
      ]);
      await runMathJax();
      await windowLoaded;
      await document.fonts.ready;
    }
  };
})();
