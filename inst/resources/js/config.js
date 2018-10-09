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

  // This function add spans for leading symbols.
  async function addLeadersSpans() {
    var anchors = document.querySelectorAll('.toc a');
    for (var a of anchors) {
      a.innerHTML = a.innerHTML + '<span class="leaders"></span>';
    }
  }

  window.PagedConfig = {
    before: async () => {
      await addLeadersSpans();
      await runMathJax();
    }
  };
})();
