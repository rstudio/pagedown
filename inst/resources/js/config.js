// Configuration script for paged.js

async function runMathJax() {
  if (typeof loadMathJax === "undefined") {
    return async () => {};
  } else {
    return loadMathJax();
  }
}

window.PagedConfig = {
  before: runMathJax
};

