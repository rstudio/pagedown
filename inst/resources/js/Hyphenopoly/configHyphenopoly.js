// This script is not part of the original Hyphenopoly library
// It is addded to dynamically find the name of the directory where resides the source directory of Hyphenopoly
// This becomes from the fact that the the Hyphenopoly_Loader.js needs the directories for the other js scripts and patterns

(function() {
  var filePath = document.querySelector('script[src$="configHyphenopoly.js"]').getAttribute('src');
  var scriptName = filePath.split('/').pop();
  var maindir = filePath.replace(scriptName, "");
  var patterndir = maindir + "patterns/";
  window.Hyphenopoly.paths = {patterndir: patterndir, maindir: maindir};
})();
