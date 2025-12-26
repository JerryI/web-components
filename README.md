# WLJS Web-Components

***RELEASE IS NOT STABLE, PLEASE WAIT***


A web component library for embedding [WLJS Notebooks](https://wljs.io/) (Jupyter-like notebooks for freeware Wolfram Engine) into static HTML pages. Export your WLJS Notebook as embeddable HTML and get interactive plots, mathematical expressions, and dynamic content on any webpage.

## Demos
- [Basic single html page](https://wljsteam.github.io/web-components/) *this repo*
- [Next.js blog example](https://wljsteam.github.io/web-components-mdx/)

## Features

- 🚀 **Lazy Loading** - Components and dependencies load progressively, showing *meaningful* raw content while loading
- 📝 **Graceful Degradation** - Users with JavaScript disabled still see readable code and expressions
- 🎨 **Interactive Content** - Embed 2D/3D graphics, plots, manipulatable widgets, and more
- 📦 **CDN-Ready** - Single script import, all dependencies loaded automatically
- 🔧 **Flexible Encoding** - Supports both `<xmp>`* tags and URI-encoded content

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