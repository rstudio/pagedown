// An auto-scaling iframe
if (customElements) {
  customElements.define('autoscaling-iframe',
    class extends HTMLElement {
      constructor() {
        super(); // compulsory
        let shadowRoot = this.attachShadow({mode: 'open'});
        // Populate the shadow DOM:
        shadowRoot.innerHTML = `
        <style>
        :host {
          /*box-sizing: content-box;*/
          break-inside: avoid;
          display: block;
          position:relative;
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
        this.ready = new Promise(resolve => {this.finished = resolve;});
      }
      connectedCallback() {
        // Be aware that the connectedCallback() function can be called multiple times,
        // see https://developer.mozilla.org/docs/Web/Web_Components/Using_custom_elements#Using_the_lifecycle_callbacks
        let iframe = this.shadowRoot.querySelector('iframe');
        iframe.addEventListener('load', () => {
          // The load event fires twice:
          // 1st time when the iframe is attached (therefore the iframe document does not exist)
          // 2nd time when the document is loaded
          if (!iframe.contentWindow) {
            // This is the 1st time that the load event fires, the document does not exist
            // Quit early:
            return;
          }

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
            let widthScaleFactor = parseFloat(this.style.width) / contentWidth;
            let heightScaleFactor = parseFloat(this.style.height) / contentHeight;
            let scaleFactor = Math.min(widthScaleFactor, heightScaleFactor);
            scaleFactor = Math.floor(scaleFactor * 1e6) / 1e6;
            iframe.style.transform = "scale(" + scaleFactor + ")";
            iframe.width = contentWidth;
            iframe.height = contentHeight;

            this.style.width = iframe.getBoundingClientRect().width + 'px';
            this.style.height = iframe.getBoundingClientRect().height + 'px';
            this.finished();
          }
        });

        if (this.hasAttribute('srcdoc') && (iframe.srcdoc.length === 0)) {
          iframe.srcdoc = this.getAttribute('srcdoc');
        }
        if (this.hasAttribute('src') && (iframe.src.length === 0)) {
          iframe.src = this.getAttribute('src');
        }
      }
    }
  );
}
