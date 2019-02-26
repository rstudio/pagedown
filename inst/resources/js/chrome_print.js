(() => {
  let HTMLWidgetsReady = new Promise((resolve) => {
    window.addEventListener(
      'DOMContentLoaded',
      () => {
        if (window.HTMLWidgets) {
          HTMLWidgets.addPostRenderHandler(resolve);
        } else {
          resolve();
        }
      },
      {capture: true, once: true}
    );
  });

  let MathJaxReady = new Promise((resolve) => {
    window.addEventListener(
      'load',
      () => {
        if (window.MathJax) {
          if (window.MathJax.Hub) {
           window.MathJax.Hub.Register.StartupHook('Begin', () => {
              window.MathJax.Hub.Queue(resolve);
            });
          } else {
            let previousAuthorInit = window.MathJax.AuthorInit || function () {};
            window.MathJax.AuthorInit = function() {
              previousAuthorInit();
              MathJax.Hub.Register.StartupHook('Begin', () => {
                MathJax.Hub.Queue(resolve);
              });
            };
          }
        }
        else {
          resolve();
        }
      },
      {capture: true, once: true}
    );
  });

  window.pagedownReady = Promise.all([MathJaxReady, HTMLWidgetsReady, document.fonts.ready]);
})();
