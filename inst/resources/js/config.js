// Configuration script for paged.js

const appendShortTitleSpans = () => {
  return new Promise((resolve, reject) => {
    Array.from(document.getElementsByClassName('level1')).forEach(div => {
      var mainHeader = div.getElementsByTagName('h1')[0];
      var mainTitle = mainHeader.textContent;
      var runningTitle = 'shortTitle' in div.dataset ? div.dataset.shortTitle : mainTitle;
      var runningHeader = document.createElement('span');
      runningHeader.className = 'shorttitle';
      runningHeader.innerText = runningTitle;
      div.insertBefore(runningHeader, mainHeader);
    });
    resolve();
  });
};

window.PagedConfig = {
  before: appendShortTitleSpans,
  after: (flow) => { console.log("after", flow) },
};
