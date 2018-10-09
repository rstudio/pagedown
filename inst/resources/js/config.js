// Configuration script for paged.js
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
      mainHeader.insertAdjacentElement('afterend', span);
      if (level == 1 && div.querySelector('.level2') === null) {
        var span2 = document.createElement('span');
        span2.className = 'shorttitle2';
        span2.innerText = ' ';
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
  before: () => {
    return Promise.all([
      appendShortTitles1(),
      appendShortTitles2()
    ]);
  }
};
