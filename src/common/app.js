function getBaseHref() {
    return 'https://cdn.jsdelivr.net/gh/WLJSTeam/web-components@latest/src/'
}

const WLJS_BOOTSTRAP = (() => {
  let _promise = null;

  const CSS_URLS = [
    "common/styles.css",
    "wljs-editor/src/styles.css",
    "wljs-graphics3d-threejs/src/styles.css",
    "wljs-html-support/src/style.css",
    "wljs-js-support/src/style.css",
    "wljs-graphics-d3/src/styles.css",
    "wljs-wlx-support/src/styles.css",
    "wljs-inputs/src/styles.css",
    "wljs-revealjs/dist/reveal.css",
    "wljs-revealjs/src/style.css",
    "wljs-revealjs/src/drawer/drawer.css",
    "wljs-revealjs/src/pointer/pointer.css",
    "wljs-markdown-support/src/styles.css",
  ];

  const ESM_URLS_IN_ORDER = [
    "wljs-interpreter/dist/interpreter.js",
    "wljs-interpreter/src/core.js",
    "wljs-wxf-accelerator/override.js",
    "wljs-export-html/Formats/MDX/Polyfill.js",
    "wljs-export-html/DynamicsTools/Runners.js",
    "wljs-cells/src/module.js",
    "wljs-editor/dist/kernel.js",
    "wljs-editor/src/boxes.js",
    "wljs-editor/src/metamarkers.js",
    "wljs-editor/src/objects.js",
    "wljs-editor/src/frontsubmit.js",
    "wljs-js-support/src/kernel.js",
    "wljs-magic-support/src/kernel.js",
    "wljs-mermaid-support/dist/kernel.js",
    "wljs-sound/dist/kernel.js",
    "wljs-inputs/dist/kernel.js",
    "wljs-html-support/src/kernel.js",
    "wljs-wlx-support/src/kernel.js",
    "wljs-sharedlib-mk/dist/kernel.js",
    "wljs-sharedlib-d3/dist/kernel.js",
    "wljs-sharedlib-three/dist/kernel.js",
    "wljs-manipulate/kernel.js",
    "wljs-revealjs/dist/kernel.js",
    "wljs-graphics-d3/dist/kernel.js",
    "wljs-plotly/dist/kernel.js",
    "wljs-graphics3d-threejs/dist/kernel.js",
  ];

  const loadedCss = new Set();
  const importedModules = new Set();

  function resolve(rel) {
    return new URL(rel, getBaseHref()).href;
  }

  function loadCSS(relHref) {
    const absHref = resolve(relHref);

    return new Promise((resolvePromise, reject) => {
      if (loadedCss.has(absHref)) return resolvePromise(absHref);

      // avoid duplicates in DOM even if Set was reset somehow
      const existing = document.querySelector(`link[rel="stylesheet"][href="${absHref}"]`);
      if (existing) {
        loadedCss.add(absHref);
        return resolvePromise(absHref);
      }

      const link = document.createElement("link");
      link.rel = "stylesheet";
      link.href = absHref;
      link.dataset.wljsCss = "1";

      link.onload = () => {
        loadedCss.add(absHref);
        resolvePromise(absHref);
      };
      link.onerror = () => reject(new Error(`Failed to load CSS: ${absHref}`));

      document.head.appendChild(link);
    });
  }

  async function importESMSequential(urls) {
    for (const rel of urls) {
      const abs = resolve(rel);
      if (importedModules.has(abs)) continue;

      await import(abs);
      importedModules.add(abs);
    }
  }

  async function ensureLoaded() {
    // keep cascade order exactly as listed
    for (const href of CSS_URLS) {
      await loadCSS(href);
    }

    await importESMSequential(ESM_URLS_IN_ORDER);

    if (!window.server) console.warn("[WLJS] window.server not present after bootstrap");
    if (!window.SupportedCells) console.warn("[WLJS] window.SupportedCells not present after bootstrap");
  }

  return {
    ready() {
      if (!_promise) _promise = ensureLoaded();
      return _promise;
    },
    CSS_URLS,
    ESM_URLS_IN_ORDER,
  };
})();


const cx = (...xs) => xs.filter(Boolean).join(" ");

const DefaultClasses = {
  downloadButton: {
    a: "p-2 text-xs w-full flex text-gray-600 my-2",
  },
  codeBlock: {
    wrapper: "bg-gray-15 mx-2",
    pre: undefined,
    code: {
      Input: "block input-cell-border",
      Output: "block",
    },
    placeholder: "opacity-0",
  },
};



function svgIconMarkup() {
  return `
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="w-5 h-5 ml-auto">
      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1"
        d="M17 17h.01m.39-3h.6c.932 0 1.398 0 1.765.152a2 2 0 0 1 1.083 1.083C21 15.602 21 16.068 21 17s0 1.398-.152 1.765a2 2 0 0 1-1.083 1.083C19.398 20 18.932 20 18 20H6c-.932 0-1.398 0-1.765-.152a2 2 0 0 1-1.083-1.083C3 18.398 3 17.932 3 17s0-1.398.152-1.765a2 2 0 0 1 1.083-1.083C4.602 14 5.068 14 6 14h.6m5.4 1V4m0 11-3-3m3 3 3-3"/>
    </svg>
  `;
}

/**
 * <wljs-store json="..." kernel="..." notebook="..."></wljs-store>
 */
// wljs-store.js

class WLJSStore extends HTMLElement {
  connectedCallback() {
    this._run();
  }

  async _run() {
    // 1) ensure WLJS libs exist first
    await WLJS_BOOTSTRAP.ready();

    // 2) now safe to do original store logic
    const virtualServer = window.server;
    if (!virtualServer) return;

    virtualServer.resetIO?.();

    const jsonUrl = this.getAttribute("json");
    const kernelUrl = this.getAttribute("kernel");

    if (jsonUrl) {
      const res = await fetch(jsonUrl);
      const objects = await res.json();
      virtualServer.loadObjects?.(objects);
    }

    if (kernelUrl) {
      const kres = await fetch(kernelUrl);
      const kernelMesh = await kres.json();
      await virtualServer.loadKernel?.(kernelMesh);
    }

    virtualServer.flushEvents?.();
  }
}

customElements.define("wljs-store", WLJSStore);


/**
 * <wljs-html>ENCODED_HTML</wljs-html>
 * or <wljs-html value="ENCODED_HTML"></wljs-html>
 */
class WLJSHTML extends HTMLElement {
  static get observedAttributes() {
    return ["value", "encoded"];
  }

  async connectedCallback() {
    await WLJS_BOOTSTRAP.ready();
    this._render();
  }

  attributeChangedCallback() {
    if (this.isConnected) this._render();
  }

  _getSourceText() {
    if (this.hasAttribute("encoded")) return decodeURIComponent(this.innerHTML.trim() ?? ""); 
    const script = this.querySelector('script[type="text/plain"]');
    if (script) return script.textContent.trim() ?? "";
    return this.textContent.trim() ?? "";
    }  

  _render() {
    //throw this._getSourceText();
    this.innerHTML = this._getSourceText();
  }
}
customElements.define("wljs-html", WLJSHTML);

/**
 * <wljs-editor type="Input|Output" display="..." fade></wljs-editor>
 * Content is the encoded cell source.
 *
 * Attributes:
 * - display: used to pick window.SupportedCells[display]
 * - type: "Input" or "Output" (for class selection)
 * - fade: presence enables fade behavior (like opts.Fade)
 * - print: if display === "print" (same behavior)
 */

function decodeMaybe(v) {
  if (v == null) return "";
  const s = String(v);
  try { return decodeURIComponent(s).trim(); } catch { return s; }
}



class WLJSEditor extends HTMLElement {
  static get observedAttributes() {
    return ["display", "type", "fade", "encoded"];
  }

  async connectedCallback() {
    await WLJS_BOOTSTRAP.ready();

    this._mounted = true;
    this._instance = null;

    requestAnimationFrame(() => this._mount());
  }

  disconnectedCallback() {
    this._mounted = false;
    this._teardown();
  }

  _getSourceText() {
    if (this.hasAttribute("encoded")) return decodeURIComponent(this.textContent.trim() ?? ""); 
    const script = this.querySelector('script[type="text/plain"]');
    if (script) return script.textContent.trim() ?? "";
    return this.textContent.trim() ?? "";
    }

  _mount() {
    if (!this._mounted) return;

    const display = this.getAttribute("display");
    if (display === "print") return;

    const SupportedCells = window.SupportedCells;
    if (!SupportedCells || !SupportedCells[display] || !SupportedCells[display].view) {
      // If no renderer, keep raw text as-is.
      return;
    }

    const decoded = this._getSourceText();

    this.replaceChildren();
    this.classList.add('wljs-mounted');
    const host = this;

    // Instantiate the view
    try {
      const ViewCtor = SupportedCells[display].view;
      this._instance = new ViewCtor({ element: host }, decoded);
    } catch (e) {
      console.error("[WLJSEditor] mount error:", e);
      return;
    }

    // Optional fade behavior: toggles a class on <pre>
    if (this._instance?.editor && this.hasAttribute("fade")) {
      this.classList.add("h-fade-20");
      const self = this;

      this._onFocusIn = () => self.classList.remove("h-fade-20");
      this._onFocusOut = () => self.classList.add("h-fade-20");

      this.addEventListener("focusin", this._onFocusIn);
      this.addEventListener("focusout", this._onFocusOut);
    }
  }

  _teardown() {
    if (this._onFocusIn) this.removeEventListener("focusin", this._onFocusIn);
    if (this._onFocusOut) this.removeEventListener("focusout", this._onFocusOut);
    this._onFocusIn = null;
    this._onFocusOut = null;

    try { this._instance?.dispose?.(); } catch (e) { console.error(e); }
    this._instance = null;
  }
}

customElements.define("wljs-editor", WLJSEditor);

/**
 * <wljs-assets>ENCODED_HTML_WITH_STYLE_AND_SCRIPT</wljs-assets>
 *
 * Behavior:
 * - appends <style> contents as real <style> elements (tagged for cleanup)
 * - executes each <script> body in order via AsyncFunction, providing:
 *   api.registerCleanup(fn), api.element, api.exports, api.index
 * - calls all registered cleanup functions + removes appended styles on disconnect/update
 */
class WLJSAssets extends HTMLElement {
  static get observedAttributes() {
    return ["value", "encoded"];
  }

  async connectedCallback() {
    await WLJS_BOOTSTRAP.ready();
    this._mounted = true;
    this._disposers = [];
    this._renderAndRun();
  }

  disconnectedCallback() {
    this._mounted = false;
    this._cleanup();
  }

  attributeChangedCallback() {
    if (this.isConnected) this._renderAndRun();
  }

  _cleanup() {
    // run disposers LIFO
    for (let i = this._disposers.length - 1; i >= 0; i--) {
      try {
        this._disposers[i]();
      } catch (e) {
        console.error(e);
      }
    }
    this._disposers = [];

    // remove appended styles
    this.querySelectorAll('[data-wljs-style="1"]').forEach((n) => n.remove());
  }

  _getSourceText() {
    if (this.hasAttribute("encoded")) return decodeURIComponent(this.textContent.trim() ?? ""); 
    const script = this.querySelector('script[type="text/plain"]');
    if (script) return script.textContent.trim() ?? "";
    return this.textContent.trim() ?? "";
    } 

  _renderAndRun() {
    this._cleanup();

    //const encoded = this.getAttribute("value") ?? this.textContent ?? "";
    const decoded = this._getSourceText();
    if (!decoded) return;

    const tpl = document.createElement("template");
    tpl.innerHTML = decoded;

    // 1) append styles
    tpl.content.querySelectorAll("style").forEach((styleNode) => {
      const el = document.createElement("style");
      el.dataset.wljsStyle = "1";
      el.textContent = styleNode.textContent || "";
      this.appendChild(el);
    });

    // 2) run scripts in order
    const scripts = Array.from(tpl.content.querySelectorAll("script"));
    const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;

    const runOne = (code, index) => {
      const localDisposers = [];
      const registerCleanup = (fn) => {
        if (typeof fn === "function") {
          localDisposers.push(fn);
          this._disposers.push(fn);
        }
      };

      const api = Object.freeze({
        registerCleanup,
        element: this,
        exports: Object.create(null),
        index,
      });

      const body = `
        try {
          ${code}
        } catch (e) {
          console.error("[WLJSAssets] script #${index} error:", e);
        }
      `;

      try {
        const fn = new AsyncFunction("api", "el", body);
        fn(api, this);
      } catch (e) {
        console.error("[WLJSAssets] build/run error for script #"+index+":", e);
      }
    };

    scripts.forEach((s, i) => {
      const code = s.textContent || "";
      if (code.trim()) runOne(code, i);
    });
  }
}
customElements.define("wljs-assets", WLJSAssets);

// --- helpers ---
function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
