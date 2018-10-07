// Hooks for paged.js

// This hook takes the value stored in the data-pagedown-item-num attribute to
// restart the ordered lists.
// It is intended to be used with the storeNumbersOrderedLists function (see config.js)
class numberOl extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }

  afterRendered(pages) {
    var orderedLists = document.getElementsByTagName('ol');
    for (var list of orderedLists) {
      list.start = list.firstElementChild.dataset.pagedownItemNum;
    }
  }
}

// Hook for broken items: when a list item is broken, the marker appears on the
// remaining content.
// The following hook removes the marker.

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

var brokenItem = false;

class removeMarkerOnBrokenItem extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }

  afterPageLayout(pageFragment, page, breakToken) {
    if (brokenItem === true) {
      pageFragment.classList.add('broken-item');
    }
    if (typeof(breakToken) === "undefined") {
      brokenItem = false;
    } else {
      brokenItem = breakToken.node.nodeName === "#text" && hasItemParent(breakToken.node);
    }
  }

  afterRendered(pages) {
    var brokenItems = document.querySelectorAll('.broken-item li:first-of-type');
    for (var item of brokenItems) {
      item.style.listStyleType = "none";
    }
  }
}

// Register hooks
Paged.registerHandlers(numberOl, removeMarkerOnBrokenItem);
