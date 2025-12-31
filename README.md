# WLJS Web-Components

***RELEASE IS NOT STABLE, PLEASE WAIT***


A web component library for embedding [WLJS Notebooks](https://wljs.io/) (Jupyter-like notebooks for freeware Wolfram Engine) into static HTML pages. Export your WLJS Notebook as embeddable HTML and get interactive plots, mathematical expressions, and dynamic content on any webpage.

## Demos
- [Basic single html page](https://wljsteam.github.io/web-components/) *this repo*
- [Next.js blog example](https://wljsteam.github.io/web-components-mdx/)

📥 If you are looking for __ready-to-go solution for publishing notebooks as blog posts__ - check out [Next.js Integration](https://github.com/WLJSTeam/web-components-mdx)

## Features

- 🚀 **Lazy Loading** - Components and dependencies load progressively, showing *meaningful* raw content while loading
- 📝 **Graceful Degradation** - Users with JavaScript disabled still see readable code and expressions
- 🎨 **Interactive Content** - Embed 2D/3D graphics, plots, manipulatable widgets, and more
- 📦 **CDN-Ready** - Single script import, all dependencies loaded automatically
- **No building step is required**
- **Framework agnostic** - Life cycle is managed automatically using native web-components compatible with any modern web-framework

> *Yes, we know, that `<xmp>` is not recommended, but it is still widely supported and works better with JS disabled than any other solutions available

## Quick Start

### 1. Include the Library

Add the script to __the end of your__ HTML page:

```html
<script type="module" src="https://cdn.jsdelivr.net/gh/WLJSTeam/web-components@latest/src/common/app.js"></script>
```

Or use local development version:

```html
<script type="module" src="./src/common/app.js"></script>
```

### 2. Add Components

‼️ Note, that you don't have to write them manually. All tags can be automatically generated with WLJS Notebook export option

```html
<!-- Load notebook data -->
<wljs-store json="attachments/data.txt"></wljs-store>

<!-- Display input cell -->
<wljs-editor display="codemirror" type="Input">
  <xmp>Plot[Sin[x], {x, 0, 2 Pi}]</xmp>
</wljs-editor>

<!-- Display output cell -->
<wljs-editor display="codemirror" type="Output">
  <xmp>(*VB[*)(Graphics[...])(*]VB*)</xmp>
</wljs-editor>
```

## Web Components API

### `<wljs-store>`

Loads notebook data and kernel state.

**Attributes:**
- `json` - Path to JSON file containing serialized objects
- `kernel` - Path to JSON file containing kernel mesh data
- `notebook` - (Optional) Notebook identifier

**Example:**
```html
<wljs-store json="attachments/8f0674d8-8a5d-40d7-b8a5-bf7114e97175.txt"></wljs-store>
```

### `<wljs-editor>`

Renders notebook cells (input/output) with syntax highlighting and interactive features.

**Attributes:**
- `display` - Renderer type (e.g., `"codemirror"`, `"print"`)
- `type` - Cell type: `"Input"` or `"Output"`
- `fade` - (Optional) Enable fade effect on focus/blur
- `encoded` - (Optional) Content is URI-encoded instead of using `<xmp>`
- `editable` - (Optional) Make the cell editable and focusable
- `lazy` - (Optional) Defer mounting until element becomes visible (improves performance with many cells)

**Content Encoding Options:**

**Option 1: Using `<xmp>` tag (recommended for human-readable exports)**
```html
<wljs-editor display="codemirror" type="Input">
  <xmp>Manipulate[Plot[Sin[a x], {x, 0, 2 Pi}], {a, 1, 5}]</xmp>
</wljs-editor>
```

✅ **Pros:** 
- Raw content visible while loading
- Works without JavaScript
- Human-readable source

⚠️ **Note:** `<xmp>` is deprecated but widely supported

**Option 2: Using `encoded` attribute**
```html
<wljs-editor display="codemirror" type="Input" encoded="true">
  Plot%5BSin%5Bx%5D%2C%20%7Bx%2C%200%2C%202%20Pi%7D%5D
</wljs-editor>
```

✅ **Pros:** 
- No special tag needed
- Handles any characters safely

⚠️ **Cons:** 
- Unreadable garbage before JS loads
- Requires JavaScript to display anything

**Option 3: Using `<script type="text/plain">`**
```html
<wljs-editor display="codemirror" type="Input">
  <script type="text/plain">
    Plot[Sin[x], {x, 0, 2 Pi}]
  </script>
</wljs-editor>
```

### `<wljs-html>`

Renders decoded HTML content from notebook output.

**Attributes:**
- `encoded` - (Optional) Content is URI-encoded

**Example:**
```html
<wljs-html>
  <div class="result">Output content</div>
</wljs-html>
```


## Export Workflow

1. **Create your notebook** in WLJS Notebook desktop app
2. **Export as HTML Embeddable** - generates standalone HTML file with custom tags and assets
3. **Embed it to your page** - provide paths to assets, adjust styles and layout if needed
4. **Deploy** - upload to any static hosting (GitHub Pages, Netlify, etc.)

## Styling
Code blocks are unstyled by the default, you can provide your own styles for all possible states. For example:

```css
  xmp {
    white-space: pre-wrap;
    word-break: normal;
    padding: 0rem;
  }
  wljs-html,wljs-assets {
    display: inline-block;
    width:100%;
  }
  wljs-html:not(:defined) {
    display: none;
  }
  wljs-assets:not(:defined) {
    display: none
  } 
  wljs-editor {
    border: none;
    background: none;
    display: block;
    line-height: 1em;
    letter-spacing: normal;
    overflow: auto;
    background: #f5f5f5;
    border-radius: 6px;
    padding: calc(1rem + 2px);
    padding-top: 0rem;
    overflow: auto;
    font-family: monospace;
    font-size: 1rem;
    margin-bottom: 1rem;
    min-height: 4rem;
  } 
  wljs-editor.wljs-hide-undefined {
    display: none;
  }
  wljs-editor.wljs-mounted {
    padding-top: 8px;
    padding-bottom: 4px;
    padding-left: 1rem;
    padding-right: 1rem;
    display: block;
    min-height: unset;
  }
```

Here it is styled in the way to avoid layout shifts during hydration. You can always hide raw blocks if needed by setting:

```css
wljs-editor {
    display: none;
}
wljs-editor.wljs-mounted {
    display: block;
}
```

## How to reduce CSS tables
Under the hood WLJS uses a subset of Tailwind classes for various components. If you already have Tailwind installed in your system, please use:

```html
<script type="module" src="https://cdn.jsdelivr.net/gh/WLJSTeam/web-components@latest/src/common/app.tw.js"></script>
```

with the following safelist:

```
@source inline('sr-only pointer-events-none pointer-events-auto visible fixed absolute relative input-cell-border sticky inset-0 -top-6 bottom-0 left-0 right-0 top-0 top-6 z-0 z-10 z-40 z-50 -m-1 -m-1.5 m-4 -mx-2 mx-1 mx-4 mx-auto my-1 my-2 my-auto -ml-0 -ml-0.5 -mt-1 mb-1 mb-2 mb-4 mb-6 mb-auto ml-0 ml-0.5 ml-1 ml-3 ml-4 ml-auto mr-0 mr-0.5 mr-1 mr-1.5 mr-2 mr-3 mr-8 mr-auto mt-0 mt-1 mt-10 mt-12 mt-2 mt-3 mt-4 mt-5 mt-6 mt-auto block inline-block inline flex inline-flex table hidden h-1 h-1.5 h-10 h-12 h-16 h-2 h-3 h-4 h-5 h-6 h-7 h-8 h-auto h-full h-px max-h-10 max-h-60 max-h-80 max-h-96 min-h-full w-0 w-1 w-1.5 w-12 w-2 w-2/4 w-3 w-3/6 w-4 w-5 w-56 w-6 w-7 w-8 w-96 w-full w-px w-screen min-w-0 max-w-2xl max-w-60 max-w-7xl max-w-full max-w-lg max-w-xs flex-1 flex-auto flex-none flex-shrink-0 shrink shrink-0 flex-grow grow grow-0 origin-top-right translate-x-0 translate-x-5 translate-y-0 translate-y-2 rotate-45 rotate-90 transform animate-spin cursor-default cursor-pointer cursor-vertical-text select-none resize-none scroll-py-2 list-disc appearance-none flex-row flex-row-reverse flex-col flex-wrap-reverse items-start items-end items-center justify-center justify-between gap-x-1 gap-x-10 gap-x-2 gap-x-3 gap-x-4 gap-x-5 gap-x-6 gap-y-1 gap-y-2 gap-y-3 gap-y-5 gap-y-7 space-x-1 space-y-0 space-y-1 space-y-6 divide-x divide-y divide-gray-100 divide-gray-200 divide-gray-400 divide-gray-500 divide-opacity-10 self-start self-end overflow-hidden overflow-x-auto overflow-y-auto overflow-y-scroll scroll-smooth truncate whitespace-nowrap rounded rounded-full rounded-lg rounded-md rounded-sm rounded-xl rounded-b-lg border border-0 border-2 border-b border-l border-r border-t border-solid border-gray-100 border-gray-200 border-gray-300 border-transparent bg-gray-100 bg-gray-200 bg-gray-400/30 bg-gray-50 bg-gray-500 bg-green-300/50 bg-red-100 bg-red-50 bg-red-600 bg-transparent bg-white bg-white/90 bg-yellow-300 bg-opacity-25 bg-opacity-60 bg-opacity-75 bg-opacity-80 fill-current fill-teal-600 stroke-current p-0 p-0.5 p-1 p-1.5 p-2 p-2.5 p-3 p-4 p-8 px-0 px-1 px-2 px-3 px-4 px-5 px-6 py-0 py-0.5 py-1 py-1.5 py-2 py-3 py-4 py-5 py-6 py-8 pb-0 pb-0.5 pb-1 pb-10 pb-2 pb-3 pb-4 pl-0 pl-0.5 pl-1 pl-2 pl-20 pl-24 pl-3 pl-5 pl-7 pr-0 pr-1 pr-10 pr-2 pr-4 pt-0 pt-0.5 pt-1 pt-2 pt-2.5 pt-5 text-left text-center text-start align-middle font-sans text-2xl text-3xl text-base text-lg text-sm text-xs font-bold font-medium font-semibold uppercase leading-4 leading-5 leading-6 leading-7 leading-8 leading-tight tracking-tight text-black text-blue-600 text-gray-200 text-gray-400 text-gray-500 text-gray-600 text-gray-700 text-gray-800 text-gray-900 text-green-400 text-indigo-600 text-orange-600 text-red-400 text-red-500 text-red-600 text-red-700 text-red-800 text-transparent text-white text-yellow-400 text-opacity-40 opacity-0 opacity-100 shadow shadow-2xl shadow-inner shadow-lg shadow-md shadow-sm shadow-xl outline outline-1 outline-offset-0 outline-gray-300 ring-0 ring-1 ring-inset ring-black ring-gray-200 ring-gray-300 ring-gray-400 ring-opacity-5 sm:mx-0 sm:my-8 sm:ml-3 sm:ml-4 sm:mt-0 sm:mt-4 sm:flex sm:h-10 sm:w-10 sm:w-auto sm:w-full sm:max-w-lg sm:translate-x-0 sm:translate-x-2 sm:translate-y-0 sm:flex-row-reverse sm:flex-col sm:items-start sm:items-end sm:items-center sm:p-0 sm:p-6 sm:px-0 sm:px-2 sm:px-6 sm:pr-3 sm:text-left sm:text-sm sm:text-xs sm:leading-6 md:fixed md:inset-y-0 md:z-50 md:-ml-14 md:ml-2 md:ml-5 md:block md:flex md:flex-col md:space-x-3 md:p-20 md:px-4 md:pl-2 md:pr-5 lg:px-8');

```

## How It Works

### Progressive Loading

1. **Initial render:** Raw content visible in `<xmp>` or `<script>` tags
2. **Bootstrap:** `app.js` loads CSS and JS modules sequentially
3. **Mount:** Web components initialize and render interactive views
4. **Hydrate:** Full functionality available (plotting, interaction, etc.)

### Architecture

```
app.js (entry point)
├── WLJS_BOOTSTRAP
│   ├── CSS (styles for all components)
│   └── ESM modules (interpreters, renderers, libraries)
├── Custom Elements
│   ├── <wljs-store>    → Data loader
│   ├── <wljs-editor>   → Cell renderer  
│   ├── <wljs-html>     → HTML output
│   └── <wljs-assets>   → Scripts & styles
└── window.server (virtual kernel)
```

## Supported Features

- ✅ 2D/3D Graphics (D3.js, Three.js, Plotly)
- ✅ Interactive Manipulate widgets
- ✅ Markdown cells
- ✅ Mathematical expressions
- ✅ Code syntax highlighting
- ✅ Mermaid diagrams
- ✅ HTML/CSS outputs
- ✅ Audio playback
- ✅ Reveal.js presentations

## Browser Compatibility

Modern browsers with ES modules support:
- Chrome/Edge 61+
- Firefox 60+
- Safari 11+

## Development

```bash
# Install dependencies
npm install

# Start local server
node server.js

# View test page
open http://localhost:3000
```

## Example

See [index.html](index.html) for a complete working example with plots and interactive manipulations.

## License
MIT

> See individual package licenses in `src/` subdirectories.

## Related

- [WLJS Notebook](https://wljs.io/) - Desktop application
- [Wolfram Language](https://www.wolfram.com/language/) - Programming language