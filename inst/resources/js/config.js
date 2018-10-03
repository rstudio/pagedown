// Configuration script for paged.js

function appendShortTitleSpans() {
  Array.from(document.getElementsByClassName('level1')).forEach(div => {
    var mainHeader = div.getElementsByTagName('h1')[0];
    var mainTitle = mainHeader.textContent;
    var runningTitle = 'shortTitle' in div.dataset ? div.dataset.shortTitle : mainTitle;
    var runningHeader = document.createElement('span');
    runningHeader.className = 'shorttitle';
    runningHeader.innerText = runningTitle;
    div.insertBefore(runningHeader, mainHeader);
  });
}

window.PagedConfig = {
  before: () => {
    return new Promise((resolve, reject) => {
      appendShortTitleSpans();
      resolve();
    })
  },
  after: (flow) => { console.log("after", flow) },
};
