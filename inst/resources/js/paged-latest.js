{
  let script = document.createElement('script');
  script.src = 'https://unpkg.com/pagedjs/dist/paged.polyfill.js';
  script.async = false;
  document.head.querySelector('script[src*="config.js"]').insertAdjacentElement('afterend', script);
}
