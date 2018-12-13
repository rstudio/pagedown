/**
 * @license Hyphenopoly_Loader 2.6.0 - client side hyphenation
 * ©2018  Mathias Nater, Zürich (mathiasnater at gmail dot com)
 * https://github.com/mnater/Hyphenopoly
 *
 * Released under the MIT license
 * http://mnater.github.io/Hyphenopoly/LICENSE
 */

(function H9YL() {
    "use strict";
    const d = document;
    const H = Hyphenopoly;

    /**
     * Create Object without standard Object-prototype
     * @returns {Object} empty object
     */
    function empty() {
        return Object.create(null);
    }

    (function config() {
        // Set H.clientFeat (either from sessionStorage or empty)
        if (H.cacheFeatureTests && sessionStorage.getItem("Hyphenopoly_Loader")) {
            H.clientFeat = JSON.parse(sessionStorage.getItem("Hyphenopoly_Loader"));
        } else {
            H.clientFeat = {
                "langs": empty(),
                "polyfill": false,
                "wasm": null
            };
        }
        // Set defaults for paths and setup
        if (H.paths) {
            if (!H.paths.patterndir) {
                H.paths.patterndir = "../Hyphenopoly/patterns/";
            }
            if (!H.paths.maindir) {
                H.paths.maindir = "../Hyphenopoly/";
            }
        } else {
            H.paths = {
                "maindir": "../Hyphenopoly/",
                "patterndir": "../Hyphenopoly/patterns/"
            };
        }

        if (H.setup) {
            if (!H.setup.selectors) {
                H.setup.selectors = empty();
                H.setup.selectors[".hyphenate"] = empty();
            }
            if (H.setup.classnames) {
                Object.keys(H.setup.classnames).forEach(function cn2sel(cn) {
                    H.setup.selectors["." + cn] = H.setup.classnames[cn];
                });
                H.setup.classnames = null;
                delete H.setup.classnames;
            }
            if (!H.setup.timeout) {
                H.setup.timeout = 1000;
            }
            if (!H.setup.hide) {
                H.setup.hide = "all";
            }
        } else {
            H.setup = {
                "hide": "all",
                "selectors": {".hyphenate": {}},
                "timeout": 1000
            };
        }
        H.lcRequire = empty();
        Object.keys(H.require).forEach(function copyRequire(k) {
            H.lcRequire[k.toLowerCase()] = H.require[k];
        });
        if (H.fallbacks) {
            H.lcFallbacks = empty();
            Object.keys(H.fallbacks).forEach(function copyFallbacks(k) {
                H.lcFallbacks[k.toLowerCase()] = H.fallbacks[k].toLowerCase();
            });
        }
    }());

    H.toggle = function toggle(state) {
        if (state === "on") {
            const stylesNode = d.getElementById("H9Y_Styles");
            if (stylesNode) {
                stylesNode.parentNode.removeChild(stylesNode);
            }
        } else {
            const sc = d.createElement("style");
            sc.id = "H9Y_Styles";
            switch (H.setup.hide) {
            case "all":
                sc.innerHTML = "html {visibility: hidden !important}";
                break;
            case "element":
                Object.keys(H.setup.selectors).
                    forEach(function eachSelector(sel) {
                        sc.innerHTML += sel + " {visibility: hidden !important}\n";
                    });

                break;
            case "text":
                Object.keys(H.setup.selectors).
                    forEach(function eachSelector(sel) {
                        sc.innerHTML += sel + " {color: transparent !important}\n";
                    });
                break;
            default:
                sc.innerHTML = "";
            }
            d.getElementsByTagName("head")[0].appendChild(sc);
        }
    };

    (function setupEvents() {
        // Events known to the system
        const definedEvents = empty();
        // Default events, execution deferred to Hyphenopoly.js
        const deferred = [];

        /*
         * Eegister for custom event handlers, where event is not yet defined
         * these events will be correctly registered in Hyphenopoly.js
         */
        const tempRegister = [];

        /**
         * Create Event Object
         * @param {string} name The Name of the event
         * @param {function} defFunc The default method of the event
         * @param {boolean} cancellable Is the default cancellable
         * @returns {undefined}
         */
        function define(name, defFunc, cancellable) {
            definedEvents[name] = {
                "cancellable": cancellable,
                "default": defFunc,
                "register": []
            };
        }

        define(
            "timeout",
            function def(e) {
                H.toggle("on");
                window.console.info(
                    "Hyphenopolys 'FOUHC'-prevention timed out after %dms",
                    e.delay
                );
            },
            false
        );

        define(
            "error",
            function def(e) {
                window.console.error(e.msg);
            },
            true
        );

        define(
            "contentLoaded",
            function def(e) {
                deferred.push({
                    "data": e,
                    "name": "contentLoaded"
                });
            },
            false
        );

        define(
            "engineLoaded",
            function def(e) {
                deferred.push({
                    "data": e,
                    "name": "engineLoaded"
                });
            },
            false
        );

        define(
            "hpbLoaded",
            function def(e) {
                deferred.push({
                    "data": e,
                    "name": "hpbLoaded"
                });
            },
            false
        );

        /**
         * Dispatch error <name> with arguments <data>
         * @param {string} name The name of the event
         * @param {Object|undefined} data Data of the event
         * @returns {undefined}
         */
        function dispatch(name, data) {
            if (!data) {
                data = empty();
            }
            let defaultPrevented = false;
            definedEvents[name].register.forEach(function call(currentHandler) {
                data.preventDefault = function preventDefault() {
                    if (definedEvents[name].cancellable) {
                        defaultPrevented = true;
                    }
                };
                currentHandler(data);
            });
            if (
                !defaultPrevented &&
                definedEvents[name].default
            ) {
                definedEvents[name].default(data);
            }
        }

        /**
         * Add EventListender <handler> to event <name>
         * @param {string} name The name of the event
         * @param {function} handler Function to register
         * @param {boolean} defer If the registration is deferred
         * @returns {undefined}
         */
        function addListener(name, handler, defer) {
            if (definedEvents[name]) {
                definedEvents[name].register.push(handler);
            } else if (defer) {
                tempRegister.push({
                    "handler": handler,
                    "name": name
                });
            } else {
                H.events.dispatch(
                    "error",
                    {"msg": "unknown Event \"" + name + "\" discarded"}
                );
            }
        }

        if (H.handleEvent) {
            Object.keys(H.handleEvent).forEach(function add(name) {
                addListener(name, H.handleEvent[name], true);
            });
        }

        H.events = empty();
        H.events.deferred = deferred;
        H.events.tempRegister = tempRegister;
        H.events.dispatch = dispatch;
        H.events.define = define;
        H.events.addListener = addListener;
    }());

    /**
     * Test if wasm is supported
     * @returns {undefined}
     */
    function featureTestWasm() {
        /* eslint-disable max-len, no-magic-numbers, no-prototype-builtins */
        /**
         * Feature test for wasm
         * @returns {boolean} support
         */
        function runWasmTest() {
            /*
             * This is the original test, without webkit workaround
             * if (typeof WebAssembly === "object" &&
             *     typeof WebAssembly.instantiate === "function") {
             *     const module = new WebAssembly.Module(Uint8Array.from(
             *         [0, 97, 115, 109, 1, 0, 0, 0]
             *     ));
             *     if (WebAssembly.Module.prototype.isPrototypeOf(module)) {
             *         return WebAssembly.Instance.prototype.isPrototypeOf(
             *             new WebAssembly.Instance(module)
             *         );
             *     }
             * }
             * return false;
             */

            /*
             * Wasm feature test with iOS bug detection
             * (https://bugs.webkit.org/show_bug.cgi?id=181781)
             */
            if (
                typeof WebAssembly === "object" &&
                typeof WebAssembly.instantiate === "function"
            ) {
                /* eslint-disable array-element-newline */
                const module = new WebAssembly.Module(Uint8Array.from([
                    0, 97, 115, 109, 1, 0, 0, 0, 1, 6, 1, 96, 1, 127, 1, 127,
                    3, 2, 1, 0, 5, 3, 1, 0, 1, 7, 8, 1, 4, 116, 101, 115,
                    116, 0, 0, 10, 16, 1, 14, 0, 32, 0, 65, 1, 54, 2, 0, 32,
                    0, 40, 2, 0, 11
                ]));
                /* eslint-enable array-element-newline */
                if (WebAssembly.Module.prototype.isPrototypeOf(module)) {
                    const inst = new WebAssembly.Instance(module);
                    return WebAssembly.Instance.prototype.isPrototypeOf(inst) &&
                            (inst.exports.test(4) !== 0);
                }
            }
            return false;
        }
        /* eslint-enable max-len, no-magic-numbers, no-prototype-builtins */
        if (H.clientFeat.wasm === null) {
            H.clientFeat.wasm = runWasmTest();
        }
    }

    const scriptLoader = (function scriptLoader() {
        const loadedScripts = empty();

        /**
         * Load script by adding <script>-tag
         * @param {string} path Where the script is stored
         * @param {string} filename Filename of the script
         * @returns {undefined}
         */
        function loadScript(path, filename) {
            if (!loadedScripts[filename]) {
                const script = d.createElement("script");
                loadedScripts[filename] = true;
                script.src = path + filename;
                if (filename === "hyphenEngine.asm.js") {
                    script.addEventListener("load", function listener() {
                        H.events.dispatch("engineLoaded", {"msg": "asm"});
                    });
                }
                d.head.appendChild(script);
            }
        }
        return loadScript;
    }());

    const loadedBins = empty();

    /**
     * Load binary files either with fetch (on new browsers that support wasm)
     * or with xmlHttpRequest
     * @param {string} path Where the script is stored
     * @param {string} fne Filename of the script with extension
     * @param {string} name Name of the ressource
     * @param {Object} msg Message
     * @returns {undefined}
     */
    function binLoader(path, fne, name, msg) {
        /**
         * Get bin file using fetch
         * @param {string} p Where the script is stored
         * @param {string} f Filename of the script with extension
         * @param {string} n Name of the ressource
         * @param {Object} m Message
         * @returns {undefined}
         */
        function fetchBinary(p, f, n, m) {
            if (!loadedBins[n]) {
                loadedBins[n] = true;
                window.fetch(p + f).then(
                    function resolve(response) {
                        if (response.ok) {
                            if (n === "hyphenEngine") {
                                H.binaries[n] = response.arrayBuffer().then(
                                    function getModule(buf) {
                                        return new WebAssembly.Module(buf);
                                    }
                                );
                            } else {
                                H.binaries[n] = response.arrayBuffer();
                            }
                            H.events.dispatch(m[0], {"msg": m[1]});
                        }
                    }
                );
            }
        }

        /**
         * Get bin file using XHR
         * @param {string} p Where the script is stored
         * @param {string} f Filename of the script with extension
         * @param {string} n Name of the ressource
         * @param {Object} m Message
         * @returns {undefined}
         */
        function requestBinary(p, f, n, m) {
            if (!loadedBins[n]) {
                loadedBins[n] = true;
                const xhr = new XMLHttpRequest();
                xhr.open("GET", p + f);
                xhr.onload = function onload() {
                    H.binaries[n] = xhr.response;
                    H.events.dispatch(m[0], {"msg": m[1]});
                };
                xhr.responseType = "arraybuffer";
                xhr.send();
            }
        }
        if (H.clientFeat.wasm) {
            fetchBinary(path, fne, name, msg);
        } else {
            requestBinary(path, fne, name, msg);
        }
    }

    /**
     * Allocate memory for (w)asm
     * @param {string} lang Language
     * @returns {undefined}
     */
    function allocateMemory(lang) {
        let wasmPages = 0;
        switch (lang) {
        case "nl":
            wasmPages = 41;
            break;
        case "de":
            wasmPages = 75;
            break;
        case "nb-no":
            wasmPages = 92;
            break;
        case "hu":
            wasmPages = 207;
            break;
        default:
            wasmPages = 32;
        }
        if (!H.specMems) {
            H.specMems = empty();
        }
        if (H.clientFeat.wasm) {
            H.specMems[lang] = new WebAssembly.Memory({
                "initial": wasmPages,
                "maximum": 256
            });
        } else {
            /**
             * Polyfill Math.log2
             * @param {number} x argument
             * @return {number} Log2(x)
             */
            Math.log2 = Math.log2 || function polyfillLog2(x) {
                return Math.log(x) * Math.LOG2E;
            };
            /* eslint-disable no-bitwise */
            const asmPages = (2 << Math.floor(Math.log2(wasmPages))) * 65536;
            /* eslint-enable no-bitwise */
            H.specMems[lang] = new ArrayBuffer(asmPages);
        }
    }

    /**
     * Load all ressources for a required <lang> and check if wasm is supported
     * @param {string} lang The language
     * @returns {undefined}
     */
    function loadRessources(lang) {
        let filename = lang + ".hpb";
        if (H.lcFallbacks && H.lcFallbacks[lang]) {
            filename = H.lcFallbacks[lang] + ".hpb";
        }
        if (!H.binaries) {
            H.binaries = empty();
        }
        featureTestWasm();
        scriptLoader(H.paths.maindir, "Hyphenopoly.js");
        if (H.clientFeat.wasm) {
            binLoader(
                H.paths.maindir,
                "hyphenEngine.wasm",
                "hyphenEngine",
                ["engineLoaded", "wasm"]
            );
        } else {
            scriptLoader(H.paths.maindir, "hyphenEngine.asm.js");
        }
        binLoader(H.paths.patterndir, filename, lang, ["hpbLoaded", lang]);
        allocateMemory(lang);
    }

    (function featureTestCSSHyphenation() {
        const tester = (function tester() {
            let fakeBody = null;

            const css = (function createCss() {
                /* eslint-disable array-element-newline */
                const props = [
                    "visibility:hidden;",
                    "-moz-hyphens:auto;",
                    "-webkit-hyphens:auto;",
                    "-ms-hyphens:auto;",
                    "hyphens:auto;",
                    "width:48px;",
                    "font-size:12px;",
                    "line-height:12px;",
                    "border:none;",
                    "padding:0;",
                    "word-wrap:normal"
                ];
                /* eslint-enable array-element-newline */
                return props.join("");
            }());

            /**
             * Create and append div with CSS-hyphenated word
             * @param {string} lang Language
             * @returns {undefined}
             */
            function createTest(lang) {
                if (H.clientFeat.langs[lang]) {
                    return;
                }
                if (!fakeBody) {
                    fakeBody = d.createElement("body");
                }
                const testDiv = d.createElement("div");
                testDiv.lang = lang;
                testDiv.id = lang;
                testDiv.style.cssText = css;
                testDiv.appendChild(d.createTextNode(H.lcRequire[lang]));
                fakeBody.appendChild(testDiv);
            }

            /**
             * Append fakeBody with tests to target (document)
             * @param {Object} target Where to append fakeBody
             * @returns {Object|null} The body element or null, if no tests
             */
            function appendTests(target) {
                if (fakeBody) {
                    target.appendChild(fakeBody);
                    return fakeBody;
                }
                return null;
            }

            /**
             * Remove fakeBody
             * @returns {undefined}
             */
            function clearTests() {
                if (fakeBody) {
                    fakeBody.parentNode.removeChild(fakeBody);
                }
            }
            return {
                "appendTests": appendTests,
                "clearTests": clearTests,
                "createTest": createTest
            };
        }());

        /**
         * Checks if hyphens (ev.prefixed) is set to auto for the element.
         * @param {Object} elm - the element
         * @returns {Boolean} result of the check
         */
        function checkCSSHyphensSupport(elm) {
            return (
                elm.style.hyphens === "auto" ||
                elm.style.webkitHyphens === "auto" ||
                elm.style.msHyphens === "auto" ||
                elm.style["-moz-hyphens"] === "auto"
            );
        }

        /**
         * Expose the hyphenate-function of a specific language to
         * Hyphenopoly.hyphenators.<language>
         *
         * Hyphenopoly.hyphenators.<language> is a Promise that fullfills
         * to hyphenate(entity, sel) as soon as the ressources are loaded
         * and the engine is ready.
         * If Promises aren't supported (e.g. IE11) a error message is produced.
         *
         * @param {string} lang - the language
         * @returns {undefined}
         */
        function exposeHyphenateFunction(lang) {
            if (!H.hyphenators) {
                H.hyphenators = {};
            }
            if (!H.hyphenators[lang]) {
                if (window.Promise) {
                    H.hyphenators[lang] = new Promise(function pro(rs, rj) {
                        H.events.addListener("engineReady", function handler(e) {
                            if (e.msg === lang) {
                                rs(H.createHyphenator(e.msg));
                            }
                        }, true);
                        H.events.addListener("error", function handler(e) {
                            if (e.key === lang || e.key === "hyphenEngine") {
                                rj(e.msg);
                            }
                        }, true);
                    });
                } else {
                    H.hyphenators[lang] = {

                        /**
                         * Fires an error message, if then is called
                         * @returns {undefined}
                         */
                        "then": function () {
                            H.events.dispatch(
                                "error",
                                {"msg": "Promises not supported in this engine. Use a polyfill (e.g. https://github.com/taylorhakes/promise-polyfill)!"}
                            );
                        }
                    };
                }
            }
        }

        Object.keys(H.lcRequire).forEach(function doReqLangs(lang) {
            if (H.lcRequire[lang] === "FORCEHYPHENOPOLY") {
                H.clientFeat.polyfill = true;
                H.clientFeat.langs[lang] = "H9Y";
                loadRessources(lang);
                exposeHyphenateFunction(lang);
            } else if (
                H.clientFeat.langs[lang] &&
                H.clientFeat.langs[lang] === "H9Y"
            ) {
                loadRessources(lang);
                exposeHyphenateFunction(lang);
            } else {
                tester.createTest(lang);
            }
        });
        const testContainer = tester.appendTests(d.documentElement);
        if (testContainer !== null) {
            Object.keys(H.lcRequire).forEach(function checkReqLangs(lang) {
                if (H.lcRequire[lang] !== "FORCEHYPHENOPOLY") {
                    const el = d.getElementById(lang);
                    if (checkCSSHyphensSupport(el) && el.offsetHeight > 12) {
                        H.clientFeat.langs[lang] = "CSS";
                    } else {
                        H.clientFeat.polyfill = true;
                        H.clientFeat.langs[lang] = "H9Y";
                        loadRessources(lang);
                        exposeHyphenateFunction(lang);
                    }
                }
            });
            tester.clearTests();
        }
    }());

    (function run() {
        if (H.clientFeat.polyfill) {
            if (H.setup.hide === "all") {
                H.toggle("off");
            }
            if (H.setup.hide !== "none") {
                H.setup.timeOutHandler = window.setTimeout(function timedOut() {
                    H.toggle("on");
                    H.events.dispatch("timeout", {"delay": H.setup.timeout});
                }, H.setup.timeout);
            }
            d.addEventListener(
                "DOMContentLoaded",
                function DCL() {
                    if (H.setup.hide !== "none" && H.setup.hide !== "all") {
                        H.toggle("off");
                    }
                    H.events.dispatch(
                        "contentLoaded",
                        {"msg": ["contentLoaded"]}
                    );
                },
                {
                    "once": true,
                    "passive": true
                }
            );
        } else {
            window.Hyphenopoly = null;
        }
    }());

    if (H.cacheFeatureTests) {
        sessionStorage.setItem(
            "Hyphenopoly_Loader",
            JSON.stringify(H.clientFeat)
        );
    }
}());
