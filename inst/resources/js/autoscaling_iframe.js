// An auto-scaling iframe
// This object emits the following events:
// - initialize: when the iframe is ready to load a document
// - clear: when the iframe sources are removed
// - load: this is the same event as the iframe
// - resize: this event fires when the auto-scaling has finished
//
// TODO  crosstalk support
//       setters/getters for width/height
if (customElements) {customElements.define('autoscaling-iframe',
  class extends HTMLElement {
    constructor() {
      super(); // compulsory
      let shadowRoot = this.attachShadow({mode: 'open'});
      // Populate the shadow DOM:
      shadowRoot.innerHTML = `
      <style>
      :host {
        break-inside: avoid;
        display: block;
        position: relative;
        overflow: hidden;
      }
      iframe {
        transform-origin: top left;
        position: absolute;
        top: 0;
        left: 0;
      }
      </style>
      <iframe frameborder="0">
      </iframe>
      `;
      let iframe = shadowRoot.querySelector('iframe');

      // the first load event throws the initialize event
      iframe.addEventListener(
        'load',
        () => this.dispatchEvent(new Event('initialize')),
        {once: true}
      );

      this.initialized = new Promise(resolve => {
        if (this.hasAttribute('initialized')) {
          resolve(this);
        } else {
          this.addEventListener('initialize', e => {
            this.setAttribute('initialized', '');
            resolve(e.currentTarget);
          });
        }
      });

      this.ready = new Promise($ => this.addEventListener('resize', e => $(e.currentTarget), {once: true}));
    }

    connectedCallback() {
      // Be aware that the connectedCallback() function can be called multiple times,
      // see https://developer.mozilla.org/docs/Web/Web_Components/Using_custom_elements#Using_the_lifecycle_callbacks
      return this.initialized.then(() => this.clear())
                             .then(() => this.loadSource())
                             .then(() => this.resize());
    }

    clear() {
      let iframe = this.shadowRoot.querySelector('iframe');

      const clearSource = (attr) => {
        let pr;
        if (iframe.hasAttribute(attr)) {
          pr = new Promise($ => iframe.addEventListener('load', e => $(e.currentTarget), {once: true, capture: true}));
          iframe.removeAttribute(attr);
        } else {
          pr = Promise.resolve(this);
        }
        return pr;
      };

      // clear srcdoc first (important)
      let res = clearSource('srcdoc').then(() => clearSource('src'));
      res.then(() => this.dispatchEvent(new Event('clear')));
      return res;
    }

    loadSource() {
      let iframe = this.shadowRoot.querySelector('iframe');

      const load = (attr) => {
        let pr;
        if (this.hasAttribute(attr)) {
          pr = new Promise($ => iframe.addEventListener('load', e => $(e.currentTarget), {once: true, capture: true}));
          iframe.setAttribute(attr, this.getAttribute(attr));
        } else {
          pr = Promise.resolve();
        }
        return pr;
      };

      // load src first (important)
      const res = load('src').then(() => load('srcdoc'));
      res.then(() => this.dispatchEvent(new Event('load')));
      return res;
    }

    resize() {
      let iframe = this.shadowRoot.querySelector('iframe');
      let contentHeight, contentWidth;
      try {
        // this works only with a same-origin url
        // with a cross-origin url, we get an error
        let docEl = iframe.contentWindow.document.documentElement;
        contentWidth = docEl.scrollWidth;
        contentHeight = docEl.scrollHeight;
      }
      catch(e) {
        // cross-origin url:
        // we cannot find the size of the html page
        // use a default resolution
        contentWidth = 1024;
        contentHeight = 768;
      }
      finally {
        let widthScaleFactor = this.clientWidth / contentWidth;
        let heightScaleFactor = this.clientHeight / contentHeight;
        let scaleFactor = Math.min(widthScaleFactor, heightScaleFactor);
        scaleFactor = Math.floor(scaleFactor * 1e6) / 1e6;
        iframe.style.transform = "scale(" + scaleFactor + ")";
        iframe.width = contentWidth;
        iframe.height = contentHeight;

        this.style.width = iframe.getBoundingClientRect().width + 'px';
        this.style.height = iframe.getBoundingClientRect().height + 'px';
        this.style.boxSizing = "content-box";
      }
      this.dispatchEvent(new Event('resize'));
      return Promise.resolve(this);
    }
  }
);}
