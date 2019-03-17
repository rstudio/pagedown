// Configuration script for paged.js

(function() {
  // Retrieve MathJax loading function
  function getBeforeAsync() {
    if (typeof window.PagedConfig !== "undefined") {
      if (typeof window.PagedConfig.before !== "undefined") {
        return window.PagedConfig.before;
      }
    }
    return async () => {};
  }

  var runMathJax = getBeforeAsync();

  // This function puts the sections of class front-matter in the div.front-matter-container
  async function moveToFrontMatter() {
    let frontMatter = document.querySelector('.front-matter-container');
    const items = document.querySelectorAll('.level1.front-matter');
    for (const item of items) {
      frontMatter.appendChild(item);
    }
  }

  // This function adds the class front-matter-ref to any <a></a> element
  // referring to an entry in the front matter
  async function detectFrontMatterReferences() {
    const frontMatter = document.querySelector('.front-matter-container');
    if (!frontMatter) return;
    let anchors = document.querySelectorAll('a[href^="#"]:not([href*=":"])');
    for (let a of anchors) {
      const ref = a.getAttribute('href').replace(/^#/, '');
      const element = document.getElementById(ref);
      if (frontMatter.contains(element)) a.classList.add('front-matter-ref');
    }
  }

  // This function expands the links in the lists of figures or tables (loft)
  async function expandLinksInLoft() {
    var items = document.querySelectorAll('.lof li, .lot li');
    for (var item of items) {
      var anchor = item.firstChild;
      anchor.innerText = item.innerText;
      item.innerText = '';
      item.append(anchor);
    }
  }

  // This function add spans for leading symbols.
  async function addLeadersSpans() {
    var anchors = document.querySelectorAll('.toc a, .lof a, .lot a');
    for (var a of anchors) {
      a.innerHTML = a.innerHTML + '<span class="leaders"></span>';
    }
  }

  /* A factory returning a function that appends short titles spans.
     The text content of these spans are reused for running titles (see default.css).
     Argument: level - An integer between 1 and 6.
  */
  function appendShortTitleSpans(level) {
    return async () => {
      var divs = Array.from(document.getElementsByClassName('level' + level));

      async function addSpan(div) {
        var mainHeader = div.getElementsByTagName('h' + level)[0];
        if (!mainHeader) return;
        var mainTitle = mainHeader.textContent;
        var spanSectionNumber = mainHeader.getElementsByClassName('header-section-number')[0];
        var mainNumber = !!spanSectionNumber ? spanSectionNumber.textContent : '';
        var runningTitle = 'shortTitle' in div.dataset ? mainNumber + ' ' + div.dataset.shortTitle : mainTitle;
        var span = document.createElement('span');
        span.className = 'shorttitle' + level;
        span.innerText = runningTitle;
        span.style.display = "none";
        mainHeader.insertAdjacentElement('afterend', span);
        if (level == 1 && div.querySelector('.level2') === null) {
          var span2 = document.createElement('span');
          span2.className = 'shorttitle2';
          span2.innerText = ' ';
          span2.style.display = "none";
          span.insertAdjacentElement('afterend', span2);
        }
      }

      for (const div of divs) {
        await addSpan(div);
      }
    };
  }

  var appendShortTitles1 = appendShortTitleSpans(1);
  var appendShortTitles2 = appendShortTitleSpans(2);

  window.PagedConfig = {
    before: async () => {
      await moveToFrontMatter();
      await detectFrontMatterReferences();
      await expandLinksInLoft();
      await Promise.all([
        addLeadersSpans(),
        appendShortTitles1(),
        appendShortTitles2()
      ]);
      await runMathJax();
      let iframeHTMLWidgets = document.getElementsByTagName('responsive-iframe');
      let widgetsReady = Promise.all([...iframeHTMLWidgets].map(el => {return el['ready'];}));
      await widgetsReady;
    },
    after: () => {
      // pagedownListener is a binder added by the chrome_print function
      // this binder exists only when chrome_print opens the html file
      if (window.pagedownListener) {
        // the html file is opened for printing
        // call the binder to signal to the R session that Paged.js has finished
        pagedownListener('');
      } else {
        // scroll to the last position before the page is reloaded
        window.scrollTo(0, sessionStorage.getItem('pagedown-scroll'));
      }
    }
  };
})();

// Define a custom <responsive-iframe> element
if (customElements) {
  customElements.define('responsive-iframe',
    class extends HTMLElement {
      constructor() {
        super(); // compulsory
        let shadowRoot = this.attachShadow({mode: 'open'}); // we must use shadow DOM in the constructor
        // Populate the shadow DOM:
        shadowRoot.innerHTML = `
        <style>
        div {overflow: hidden;}
        </style>
        <div>
          <iframe frameborder="0" seamless></iframe>
        </div>
        `;
        this.ready = new Promise(resolve => {this.finished = resolve;})
      }
      connectedCallback() {
        // First, we embed the <responsive-iframe> element in a div footprint
        // This footprint will take room before Paged.js begins parsing the document
        // Since the constructor is called a second time after Paged.js builds the document,
        // we also must test if the footprint div already exists
        let footprint;
        if (this.parentElement.classList.contains('responsive-iframe-footprint')) {
          footprint = this.parentElement;
        } else {
          footprint = document.createElement('div');
          footprint.style.overflow = 'hidden';
          footprint.style.breakInside = 'avoid';
          footprint.className = 'responsive-iframe-footprint';
          this.insertAdjacentElement('beforebegin', footprint);
          footprint.appendChild(this);
        }
        footprint.style.width = this.getAttribute('width');
        footprint.style.height = this.getAttribute('height');

        let iframe = this.shadowRoot.querySelector('iframe');
        let container = this.shadowRoot.querySelector('div');
        container.style.width = this.getAttribute('width');
        container.style.height = this.getAttribute('height');

        iframe.addEventListener('load', () => {
          // The load event fires twice:
          // 1st time when the iframe is attached (therefore the iframe document does not exist)
          // 2nd time when the document is loaded
          if (!iframe.contentWindow) {
            // This is the 1st time that the load event fires, the document does not exist
            // Quit early:
            return;
          }
          let docEl = iframe.contentWindow.document.documentElement;
          let contentHeight = docEl.scrollHeight;
          let contentWidth = docEl.scrollWidth;

          let widthScaleFactor = footprint.getBoundingClientRect().width / contentWidth;
          let heightScaleFactor = footprint.getBoundingClientRect().height / contentHeight;
          let scaleFactor = Math.min(widthScaleFactor, heightScaleFactor);
          iframe.style.transformOrigin = "top left";
          iframe.style.transform = "scale(" + scaleFactor + ")";
          iframe.width = contentWidth;
          iframe.height = contentHeight;

          container.style.width = iframe.getBoundingClientRect().width + 'px';
          footprint.style.width = iframe.getBoundingClientRect().width + 'px';
          this.setAttribute('width', container.style.width);
          container.style.height = iframe.getBoundingClientRect().height + 'px';
          footprint.style.height = iframe.getBoundingClientRect().height + 'px';
          this.setAttribute('height', container.style.height);
          this.finished();
        });

        if (this.hasAttribute('srcdoc')) {
          iframe.srcdoc = this.getAttribute('srcdoc');
        }
        if (this.hasAttribute('src')) {
          iframe.src = this.getAttribute('src');
        }
      }
    }
  );
}
