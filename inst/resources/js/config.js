// Configuration script for paged.js

// This async function stores, for each li element of an ordered list, number
// in the data-pagedown-item-num attribute.
// This function is intended to be used with the numberOl hook (see hooks.js).
async function storeNumbersOrderedLists() {
  const orderedLists = document.getElementsByTagName('ol');

  function storeNumbers(list) {
    return new Promise((resolve, reject) => {
      var items = list.children;
      for (var i = 0; i < items.length; i++) {
        items[i].setAttribute('data-pagedown-item-num', i + 1);
      }
      resolve();
    })
  }

  for (const list of orderedLists) {
    await storeNumbers(list);
  }
}

window.PagedConfig = {
  before: storeNumbersOrderedLists
};
