// Configuration script for paged.js

(function() {
  // This function add spans for leading symbols.
  async function addLeadersSpans() {
    var anchors = document.querySelectorAll('.toc a');
    for (var a of anchors) {
      a.innerHTML = a.innerHTML + '<span class="leaders"></span>';
    }
  }

  window.PagedConfig = {
    before: addLeadersSpans
  };
})();
