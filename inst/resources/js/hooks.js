// Hooks for paged.js

// This hook fixes the bug for ordered lists (when an ordered list is splitted
// on different pages, the numbering restarts from 1).
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }

  beforeParsed(content) {
    const orderedLists = content.querySelectorAll('ol');

    function storeNumbers(list) {
      var items = list.children;
      for (var i = 0; i < items.length; i++) {
        items[i].setAttribute('data-pagedown-item-num', i + 1);
      }
    }
    for (var list of orderedLists) {
      storeNumbers(list);
    }
  }

  afterRendered(pages) {
    var orderedLists = document.getElementsByTagName('ol');
    for (var list of orderedLists) {
      list.start = list.firstElementChild.dataset.pagedownItemNum;
    }
  }
});

// Hook fixing the bug for broken items (when a list item is broken, the marker appears on the
// remaining content).
// The following hook removes the extra marker.
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }

  afterPageLayout(pageFragment, page, breakToken) {
    function hasItemParent(node) {
      if (node.parentElement === null) {
        return false;
      } else {
        if (node.parentElement.tagName === 'LI') {
          return true;
        } else {
          return hasItemParent(node.parentElement);
        }
      }
    }

    if (breakToken !== undefined) {
      if (breakToken.node.nodeName === "#text" && hasItemParent(breakToken.node)) {
        pageFragment.classList.add('broken-item');
      }
    }
  }

  afterRendered(pages) {
    var brokenItems = document.querySelectorAll('.broken-item+.pagedjs_page li:first-of-type');
    for (var item of brokenItems) {
      item.style.listStyleType = "none";
    }
  }
});
