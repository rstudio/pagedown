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

Paged.registerHandlers(numberOl);
