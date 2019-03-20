// An auto-scaling iframe
// This object emits the following events:
// - load: this is the same event as the iframe
// - initialized: before the iframe load the source document
// - resized: this event fires when the auto-scaling has finished
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
        position: absolute;
        transform-origin: top left;
      }
      </style>
      <iframe frameborder="0">
      </iframe>
      `;
      let iframe = shadowRoot.querySelector('iframe');

      // dispatch the iframe load events by the custom element
      iframe.addEventListener('load', event => {
        this.dispatchEvent(new Event('load'));
      });

      // the first load event throws the initialized event
      this.addEventListener('load', () => this.dispatchEvent(new Event('initialized')), {once: true});

      this.initialized = new Promise(resolve => {
        if (this.hasAttribute('initialized')) {
          resolve(this);
        } else {
          this.addEventListener('initialized', e => {
            this.setAttribute('initialized', '');
            resolve(e.currentTarget);
          });
        }
      });

      this.ready = new Promise($ => this.addEventListener('resized', e => $(e.currentTarget), {once: true}));
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
          pr = new Promise($ => this.addEventListener('load', e => $(e.currentTarget), {once: true, capture: true}));
          iframe.removeAttribute(attr);
        } else {
          pr = Promise.resolve(this);
        }
        return pr;
      };

      // clear srcdoc first (important)
      return clearSource('srcdoc').then(() => clearSource('src'));
    }
    loadSrc() {
      let iframe = this.shadowRoot.querySelector('iframe');
      let pr;
      if (this.hasAttribute('src')) {
        pr = new Promise($ => this.addEventListener('load', e => $(e.currentTarget), {once: true, capture: true}));
        iframe.src = this.getAttribute('src');
      } else {
        pr = Promise.resolve();
      }
      return pr;
    }
    loadSource() {
      let iframe = this.shadowRoot.querySelector('iframe');
      // load src first (important)
      return this.loadSrc().then(() => {
        let loadSrcdoc;
        if (this.hasAttribute('srcdoc')) {
          loadSrcdoc = new Promise($ => this.addEventListener('load', e => $(e.currentTarget), {once: true, capture: true}));
          iframe.srcdoc = this.getAttribute('srcdoc');
        } else {
          loadSrcdoc = Promise.resolve();
        }
        return loadSrcdoc;
      });
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
      this.dispatchEvent(new Event('resized'));
      return Promise.resolve(this);
    }
  }
);}
