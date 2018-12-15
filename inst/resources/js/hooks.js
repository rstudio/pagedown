// Hooks for paged.js

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
