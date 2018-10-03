// Configuration script for paged.js

const appendShortTitleSpans = (level) => {
  return () => {
    return new Promise((resolve, reject) => {
      Array.from(document.getElementsByClassName('level' + level)).forEach(div => {
        var mainHeader = div.getElementsByTagName('h' + level)[0];
        var mainTitle = mainHeader.textContent;
        var runningTitle = 'shortTitle' in div.dataset ? div.dataset.shortTitle : mainTitle;
        var span = document.createElement('span');
        span.className = 'shorttitle' + level;
        span.innerText = runningTitle;
        div.insertBefore(span, mainHeader);
      });
      resolve();
    });
  };
};

var appendShortTitles1 = appendShortTitleSpans(1);
var appendShortTitles2 = appendShortTitleSpans(2);

window.PagedConfig = {
  before: () => {
    return Promise.all([
      appendShortTitles1(),
      appendShortTitles2()
    ]);
  },
  after: (flow) => { console.log("after", flow) },
};
