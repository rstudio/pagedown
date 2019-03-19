// A responsive iframe
// Works only with a same-origin html file
if (customElements) {
  customElements.define('responsive-iframe',
    class extends HTMLElement {
      constructor() {
        super(); // compulsory
        let shadowRoot = this.attachShadow({mode: 'open'}); // we must use shadow DOM in the constructor
        // Populate the shadow DOM:
        shadowRoot.innerHTML = `
        <style>
        div, iframe {position: absolute;}
        div {overflow: hidden;}
        </style>
        <div>
          <iframe frameborder="0"></iframe>
        </div>
        `;
        this.ready = new Promise(resolve => {this.finished = resolve;});
      }
      connectedCallback() {
        // Be aware that the connectedCallback() function can be called multiple times,
        // see https://developer.mozilla.org/docs/Web/Web_Components/Using_custom_elements#Using_the_lifecycle_callbacks
        if (!this.hasAttribute('initial-width')) {
          this.setAttribute('initial-width', this.style.width);
        }
        if (!this.hasAttribute('initial-height')) {
          this.setAttribute('initial-height', this.style.height);
        }

        // First, we embed the <responsive-iframe> element in a footprint div.
        // This footprint will take room before Paged.js begins parsing the document.
        // Since the constructor is also called after Paged.js builds the document,
        // we also must test if the footprint div already exists.
        let footprint;
        if (!this.parentElement.classList.contains('responsive-iframe-footprint')) {
          // The footprint div does not exist yet, create it.
          footprint = document.createElement('div');
          footprint.style = this.style.cssText;
          this.removeAttribute('style');
          footprint.style.boxSizing='content-box';
          footprint.style.breakInside = 'avoid';
          footprint.style.position = 'relative';
          footprint.className = 'responsive-iframe-footprint';
          this.insertAdjacentElement('beforebegin', footprint);
          footprint.appendChild(this);
          this.setAttribute('style', 'position: absolute;');
        } else {
          // The footprint div already exists.
          footprint = this.parentElement;
        }

        let iframe = this.shadowRoot.querySelector('iframe');
        let container = this.shadowRoot.querySelector('div');
        container.style.width = footprint.style.width;
        container.style.height = footprint.style.height;

        iframe.addEventListener('load', () => {
          // The load event fires twice:
          // 1st time when the iframe is attached (therefore the iframe document does not exist)
          // 2nd time when the document is loaded
          if (!iframe.contentWindow) {
            // This is the 1st time that the load event fires, the document does not exist
            // Quit early:
            return;
          }
          let docEl = iframe.contentWindow.document.documentElement; // this works only with same-origin content
          let contentHeight = docEl.scrollHeight;
          let contentWidth = docEl.scrollWidth;

          let widthScaleFactor = parseFloat(footprint.style.width) / contentWidth;
          let heightScaleFactor = parseFloat(footprint.style.height) / contentHeight;
          let scaleFactor = Math.min(widthScaleFactor, heightScaleFactor);
          scaleFactor = Math.floor(scaleFactor * 1e6) / 1e6;
          iframe.style.transformOrigin = "top left";
          iframe.style.transform = "scale(" + scaleFactor + ")";
          iframe.width = contentWidth;
          iframe.height = contentHeight;

          container.style.width = iframe.getBoundingClientRect().width + 'px';
          container.style.height = iframe.getBoundingClientRect().height + 'px';
          footprint.style.width = iframe.getBoundingClientRect().width + 'px';
          footprint.style.height = iframe.getBoundingClientRect().height + 'px';
          this.finished();
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
