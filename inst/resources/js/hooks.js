// Hooks for paged.js

// This hook creates a list of abbreviations
// Note: we also could implement this feature using a Pandoc filter
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }
  beforeParsed(content) {
    const abbreviations = content.querySelectorAll('abbr');
    if(abbreviations.length === 0) return;
    const loaTitle = 'List of Abbreviations';
    const loaId = 'LOA';
    const tocList = content.querySelector('.toc ul');
    let listOfAbbreviations = document.createElement('div');
    let descriptionList = document.createElement('dl');
    content.appendChild(listOfAbbreviations);
    listOfAbbreviations.id = loaId;
    listOfAbbreviations.classList.add('section', 'front-matter', 'level1', 'loa');
    listOfAbbreviations.innerHTML = '<h1>' + loaTitle + '</h1>';
    listOfAbbreviations.appendChild(descriptionList);
    for(let abbr of abbreviations) {
      if(!abbr.title) continue;
      let term = document.createElement('dt');
      let definition = document.createElement('dd');
      descriptionList.appendChild(term);
      descriptionList.appendChild(definition);
      term.innerHTML = abbr.innerHTML;
      definition.innerText = abbr.title;
    }
    if (tocList) {
      const loaTOCItem = document.createElement('li');
      loaTOCItem.innerHTML = '<a href="#' + loaId + '">' + loaTitle + '</a>';
      tocList.appendChild(loaTOCItem);
    }
  }
});

// This hook moves the sections of class front-matter in the div.front-matter-container
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }

  beforeParsed(content) {
    const frontMatter = content.querySelector('.front-matter-container');
    if (!frontMatter) return;

    // move front matter sections in the front matter container
    const frontMatterSections = content.querySelectorAll('.level1.front-matter');
    for (const section of frontMatterSections) {
      frontMatter.appendChild(section);
    }

    // add the class front-matter-ref to any <a></a> element
    // referring to an entry in the front matter
    const anchors = content.querySelectorAll('a[href^="#"]:not([href*=":"])');
    for (const a of anchors) {
      const ref = a.getAttribute('href').replace(/^#/, '');
      const element = content.getElementById(ref);
      if (frontMatter.contains(element)) a.classList.add('front-matter-ref');
    }

    // update the toc, lof and lot for front matter sections
    const frontMatterSectionsLinks = content.querySelectorAll('.toc .front-matter-ref, .lof .front-matter-ref, .lot .front-matter-ref');
    for (let i = frontMatterSectionsLinks.length - 1; i >= 0; i--) {
      const listItem = frontMatterSectionsLinks[i].parentNode;
      const list = listItem.parentNode;
      list.insertBefore(listItem, list.firstChild);
    }
  }
});

// This hook expands the links in the lists of figures and tables
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }

  beforeParsed(content) {
    const items = content.querySelectorAll('.lof li, .lot li');
    for (const item of items) {
      const anchor = item.firstChild;
      anchor.innerText = item.innerText;
      item.innerText = '';
      item.append(anchor);
    }
  }
});

// This hook adds spans for leading symbols
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }

  beforeParsed(content) {
    const anchors = content.querySelectorAll('.toc a, .lof a, .lot a');
    for (const a of anchors) {
      a.innerHTML = a.innerHTML + '<span class="leaders"></span>';
    }
  }
});

// This hook appends short titles spans
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }

  beforeParsed(content) {
  /* A factory returning a function that appends short titles spans.
     The text content of these spans are reused for running titles (see default.css).
     Argument: level - An integer between 1 and 6.
  */
  function appendShortTitleSpans(level) {
    return () => {
      const divs = Array.from(content.querySelectorAll('.level' + level));

      function addSpan(div) {
        const mainHeader = div.getElementsByTagName('h' + level)[0];
        if (!mainHeader) return;
        const mainTitle = mainHeader.textContent;
        const spanSectionNumber = mainHeader.getElementsByClassName('header-section-number')[0];
        const mainNumber = !!spanSectionNumber ? spanSectionNumber.textContent : '';
        const runningTitle = 'shortTitle' in div.dataset ? mainNumber + ' ' + div.dataset.shortTitle : mainTitle;
        const span = document.createElement('span');
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
        addSpan(div);
      }
    };
  }

  appendShortTitleSpans(1)();
  appendShortTitleSpans(2)();
  }
});

// Footnotes support
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);

    this.splittedParagraphRefs = [];
  }

  beforeParsed(content) {
    var footnotes = content.querySelectorAll('.footnote');

    for (var footnote of footnotes) {
      var parentElement = footnote.parentElement;
      var footnoteCall = document.createElement('a');
      var footnoteNumber = footnote.dataset.pagedownFootnoteNumber;

      footnoteCall.className = 'footnote-ref'; // same class as Pandoc
      footnoteCall.setAttribute('id', 'fnref' + footnoteNumber); // same notation as Pandoc
      footnoteCall.setAttribute('href', '#' + footnote.id);
      footnoteCall.innerHTML = '<sup>' + footnoteNumber +'</sup>';
      parentElement.insertBefore(footnoteCall, footnote);

      // Here comes a hack. Fortunately, it works with Chrome and FF.
      var handler = document.createElement('p');
      handler.className = 'footnoteHandler';
      parentElement.insertBefore(handler, footnote);
      handler.appendChild(footnote);
      handler.style.display = 'inline-block';
      handler.style.width = '100%';
      handler.style.float = 'right';
      handler.style.pageBreakInside = 'avoid';
    }
  }

  afterPageLayout(pageFragment, page, breakToken) {
    function hasItemParent(node) {
      if (node.parentElement === null) {
        return false;
      } else {
        if (node.parentElement.tagName === 'LI') {
          return true;
        } else {
          return hasItemParent(node.parentElement);
        }
      }
    }
    // If a li item is broken, we store the reference of the p child element
    // see https://github.com/rstudio/pagedown/issues/23#issue-376548000
    if (breakToken !== undefined) {
      if (breakToken.node.nodeName === "#text" && hasItemParent(breakToken.node)) {
        this.splittedParagraphRefs.push(breakToken.node.parentElement.dataset.ref);
      }
    }
  }

  afterRendered(pages) {
    for (var page of pages) {
      var footnotes = page.element.querySelectorAll('.footnote');
      if (footnotes.length === 0) {
        continue;
      }

      var pageContent = page.element.querySelector('.pagedjs_page_content');
      var hr = document.createElement('hr');
      var footnoteArea = document.createElement('div');

      pageContent.style.display = 'flex';
      pageContent.style.flexDirection = 'column';

      hr.className = 'footnote-break';
      hr.style.marginTop = 'auto';
      hr.style.marginBottom = 0;
      hr.style.marginLeft = 0;
      hr.style.marginRight = 'auto';
      pageContent.appendChild(hr);

      footnoteArea.className = 'footnote-area';
      pageContent.appendChild(footnoteArea);

      for (var footnote of footnotes) {
        var handler = footnote.parentElement;

        footnoteArea.appendChild(footnote);
        handler.parentNode.removeChild(handler);

        footnote.innerHTML = '<sup>' + footnote.dataset.pagedownFootnoteNumber + '</sup>' + footnote.innerHTML;
        footnote.style.fontSize = 'x-small';
        footnote.style.marginTop = 0;
        footnote.style.marginBottom = 0;
        footnote.style.paddingTop = 0;
        footnote.style.paddingBottom = 0;
        footnote.style.display = 'block';
      }
    }

    for (var ref of this.splittedParagraphRefs) {
      var paragraphFirstPage = document.querySelector('[data-split-to="' + ref + '"]');
      // We test whether the paragraph is empty
      // see https://github.com/rstudio/pagedown/issues/23#issue-376548000
      if (paragraphFirstPage.innerText === "") {
        paragraphFirstPage.parentElement.style.display = "none";
        var paragraphSecondPage = document.querySelector('[data-split-from="' + ref + '"]');
        paragraphSecondPage.parentElement.style.setProperty('list-style', 'inherit', 'important');
      }
    }
  }
});


// Support for "Chapter " label on section with class `.chapter`
Paged.registerHandlers(class extends Paged.Handler {
  constructor(chunker, polisher, caller) {
    super(chunker, polisher, caller);
  }
  beforeParsed(content) {
    const tocAnchors = content.querySelectorAll('.toc a[href^="#"]:not([href*=":"]');
    for(let anchor of tocAnchors) {
      const ref = anchor.getAttribute('href').replace(/^#/, '');
      const element = content.getElementById(ref);
      if(element.classList.contains('chapter')) {
        anchor.classList.add('chapter-ref');
      }
    }
  }
});

