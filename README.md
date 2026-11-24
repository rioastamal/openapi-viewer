# OpenAPI Viewer

A lightweight, zero-build, single-file **OpenAPI 3.x** and **Swagger 2.0** documentation viewer and interactive API client written in pure Vanilla JavaScript.

---

## Try It Now

- **Live Web App:** Open directly in your browser at **[https://rioastamal.net/openapi-viewer/](https://rioastamal.net/openapi-viewer/)**
- **Build Locally:** Run the standalone bundler and inspect the output file:

```bash
bash build.sh
# Open build/index.html directly in any web browser
```

Or bundle your own JSON/YAML specification directly into a locked-down, self-contained HTML file:

```bash
bash build.sh --spec-file examples/petstore.json --disable-load-url --disable-upload
# Open build/index.html in your browser
```

---

## Key Features

- **OpenAPI 3.x & Swagger 2.0 Support** — Full compatibility with both **JSON** and **YAML** specifications (`.json`, `.yaml`, `.yml`).
- **Flexible Spec Ingestion** — Load specs via drag-and-drop local file picker, remote URL fetch, or pre-embed a specification directly into a single standalone HTML bundle using `build.sh`.
- **Zero Build Tools at Runtime** — Pure ES6+ Vanilla JS with Tailwind CSS, Highlight.js, Lucide Icons, and `js-yaml` loaded via CDN. No Node/React/bundler runtime required to view.
- **Interactive Live Client (`Try It`)**:
  - Live parameter editing for path, query, and headers with custom server base URL override.
  - JSON request payload editor with a 3-way merge algorithm that preserves your custom field edits when switching example templates.
  - Per-endpoint draft state persistence across navigation.
  - Keyboard shortcut: send requests instantly via `⌘ + Enter` on macOS or `Ctrl + Enter` on Windows and Linux.
- **Generic Variables & Environment Replacement (`{VARIABLE_NAME}`)** — Define reusable variables (e.g. `{API_TOKEN}`, `{DEVICE_ID}`) in the Variables modal, persisted in `localStorage`, and reference them dynamically across URLs, headers, and request payloads.
- **Multi-Language Code Snippets** — Ready-to-use snippets for **cURL**, **JavaScript (`fetch`)**, **PHP**, and **Go** (with Bearer authorization tokens masked as `{API_TOKEN}`).
- **Custom Markdown Pages (`x-pages` & `x-page`)** — Embed top-level documentation guides (`x-pages`) or path-level overviews (`x-page`) using Markdown, syntax-highlighted code blocks, and GitHub-Flavored Markdown alert callouts (`[!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`).
- **Responsive 3-Column Interface & Dark Mode** — Collapsible sidebar and interactive code panel on desktop, responsive drawer and tab navigation on mobile, plus persistent light/dark theme toggle.
- **Modular Theme Support** — Easily customize accent colors and layout styles using CSS custom properties via `src/themes/`.

---

## Standalone Distribution Builder (`build.sh`)

The project includes a POSIX-compliant Bash script (`build.sh`) compatible with macOS default Bash 3.2 and Linux.

### 1. Build a Generic Viewer (No Pre-Embedded Spec)

Omitting `--spec-file` generates a standalone viewer in `build/index.html` that boots into a welcome screen ready for local JSON/YAML file upload or remote URL loading:

```bash
bash build.sh
```

### 2. Embed a Specification (JSON or YAML)

Embed a specific OpenAPI or Swagger specification into `build/index.html`:

```bash
# Embed JSON specification
bash build.sh --spec-file examples/petstore.json

# Embed YAML specification (automatically validated and converted to JSON)
bash build.sh --spec-file path/to/spec.yaml --minify

# Locked-down single-file documentation (disables file upload and remote URL inputs)
bash build.sh --spec-file path/to/spec.yaml --disable-load-url --disable-upload
```

### `build.sh` Options

| Option | Description | Default |
| :--- | :--- | :--- |
| `-s, --spec-file <path>` | Path to OpenAPI/Swagger JSON or YAML specification (optional) | None (generic viewer) |
| `-o, --output <path>` | Output standalone HTML file destination | `build/index.html` |
| `-t, --template <path>` | Viewer template source file | `src/index.html` |
| `--theme <name\|path>` | Theme name from `src/themes/` or direct CSS file path | `default` |
| `--server-url <url>` | Override default API server base URL | From specification |
| `-m, --minify` | Minify specification JSON before embedding | `false` |
| `--disable-load-url` | Omit the remote URL input and fetch component | `false` |
| `--disable-upload` | Omit the local file upload component | `false` |
| `-h, --help` | Display usage instructions and exit | — |

> **Note:** Omitting `--spec-file` while specifying both `--disable-load-url` and `--disable-upload` is rejected with an error, as the viewer would have no mechanism to load an API specification.

### YAML Parser Detection

When a YAML file is provided to `build.sh`, it automatically converts and validates it into JSON using the first available tool:

1. `python3` with `PyYAML`
2. `ruby` (built-in `yaml`/`Psych` on macOS and Linux)
3. `yq`
4. `node` with `js-yaml` or `yaml`

---

## Project Structure

```text
.
├── build.sh              # Single-file distribution builder (Bash 3.2+ / Linux)
├── build/
│   └── index.html        # Generated standalone HTML viewer
├── examples/
│   └── petstore.json     # Sample OpenAPI 3.0 specification
└── src/
    ├── index.html        # Viewer template & Vanilla JS application
    └── themes/
        └── default.css   # Default theme styling & color variables
```

---

## Custom Documentation Pages (`x-pages`)

Add dedicated guides directly inside your OpenAPI specification without mixing them into endpoints:

- **Top-level Guides:** Add an `x-pages` array at the specification root (or under `info`) containing objects with `{ id, title, icon, content }`.
- **Path-level Pages:** Add `x-page` (or `x-pages`) under any path entry in `paths["/your-path"]` to show an overview guide directly above the endpoint operations for that path.

---

## License

MIT
