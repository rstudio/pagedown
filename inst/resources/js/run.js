(async function() {
  await new Promise(function($){window.addEventListener('load', $, {once: true})});
  window.PagedPolyfill.preview();
})();
