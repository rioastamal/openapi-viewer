# Implementation Summary

- **Live Response Table View (`src/index.html`)**:
  - Added `JSON | Table` view switcher (`#try-response-view-switcher`) in the Live Response header, persisted via `state.liveResponseView`.
  - Implemented `extractTableDataset()` supporting arrays of objects, wrapped REST responses (auto-detecting `data`/`items`/`results`/etc. with sibling metadata chips), and single objects (2-column `Key | Value`) with dot-notation flattening up to 2 levels.
  - Added row filtering (`#try-response-table-filter`), 3-state column sorting (`asc` -> `desc` -> default via `sortTableRows()` with `null`/`undefined` always last), sorted/filtered CSV copy (`#btn-copy-resp-csv`), click-to-copy cell values, XSS HTML escaping, and fullscreen height adaptation (`lg:max-h-[calc(100vh-17rem)]`).

- **Live Client Fullscreen Toggle (`src/index.html`)**:
  - Added `toggleCodePanelFullscreen()` and `updateFullscreenUI()` controlled by `#btn-fullscreen-code-panel` (panel header) and `Esc`.
  - When enabled on desktop, automatically hides `#sidebar-container` and `#docs-container`, expands `#code-container` (`flex-1 w-full`), displays the active endpoint badge (`#live-client-endpoint-badge`), and switches Live Client request/response to a side-by-side layout where the response panel (`lg:flex-1`, ~64-66%) is wider than the request form (`lg:w-[36%] xl:w-[34%]`).
  - Restores previous `sidebarCollapsed` and `codePanelCollapsed` states on exit, and exits fullscreen automatically when collapsing the panel or opening a custom page.

- **Client-Side YAML Parser in Viewer (`src/index.html`)**:
  - Added `js-yaml` (`4.1.0`) CDN in [src/index.html](file:///Users/rioastamal/Projects/openapi-swagger-viewer/src/index.html) and updated local upload (`accept=".json,.yaml,.yml"`) and remote URL fetch handlers to use `parseSpecText()`.
  - Added `normalizeParsedSpec()` (converts YAML `Date` objects to ISO strings and stringifies non-string keys) and hardened `parseOpenApiSpec()` to accept numeric YAML `openapi`/`swagger` versions (e.g. unquoted `swagger: 2.0`).
  - Rejects empty, multi-document, or non-object YAML inputs with clear error alerts.

- **YAML Specification Support in `build.sh`**:
  - Added `.yaml`/`.yml` (and fallback non-JSON content) detection, validation, and JSON conversion in [build.sh](file:///Users/rioastamal/Projects/openapi-swagger-viewer/build.sh) compatible with macOS Bash 3.2 and Linux.
  - Fallback converter chain: `python3` (`PyYAML`) -> `ruby` (built-in `Psych` + `JSON`) -> `yq` -> `node` (`js-yaml`/`yaml`).
  - Validates YAML syntax, rejects empty/multi-document/non-object roots, resolves anchors/merge keys (`<<: *alias`), normalizes `Date`/`Time` and non-string keys, coerces numeric `openapi`/`swagger` versions to strings, escapes `</script` sequences, and supports `--minify`.
  - Made `--spec-file` optional for building a standalone generic viewer (`EMBEDDED_OPENAPI_SPEC = null`), rejecting omission only when both `--disable-load-url` and `--disable-upload` are set.

- **Path-level `x-page` Documentation Support**:
  - Revoked the tag description `page:` prefix parsing.
  - Added support for optional `x-page` (or `x-pages`) on each path definition in `paths[pathStr]`.
  - Contains `title`, `icon`, and `content`.
  - Rendered in the sidebar navigation directly before the endpoint operations of that path (e.g. renders `"Pets Overview"` before `"GET /pets"`).
  - Uses the specified `icon` (defaulting to `info`).
  - Clicking the item opens the page in the main documentation view rendered with Markdown, GFM alerts, code blocks, and diagrams, identically to top-level `x-pages`.

- **Live Client Server URL Override**:
  - Added a **Server URL** input field at the top of the **Live Client (Try It)** tool in [src/index.html](file:///Users/rioastamal/Projects/openapi-swagger-viewer/src/index.html).
  - Pre-populated with the specification's default `baseUrl` (or custom `--server-url`).
  - Allows users to interactively override the server base URL (e.g. testing against local `http://localhost:8080`, staging, or alternative gateways).
  - Automatically updates the live requests executed by `executeLiveRequest` as well as the multi-language code snippets and copy snippets in real time.

- **Collapsible Navigation Sidebar & Persistent Live Client Arrow (Desktop Only)**:
  - **Navigation Sidebar Toggle Inside Sidebar**: Placed the collapse button (`#btn-toggle-sidebar`) inside the sidebar container directly above the filter/search box, showing `< Endpoints and Guides` (with a `chevron-left` icon). Hidden on mobile (`hidden lg:flex`).
  - **Docked Navigation Expand Arrow**: When the sidebar is collapsed on desktop, a docked toggle button (`#btn-expand-sidebar`) with `chevron-right` appears on the left side of the documentation view to quickly bring back the navigation. Hidden on mobile (`hidden lg:flex`).
  - **Persistent Live Client Arrow**: In the Live Client / Code panel header, a collapse arrow (`#btn-toggle-code-panel`, `chevron-right`) collapses the panel on desktop (`hidden lg:inline-flex`). When collapsed, a docked button (`#btn-expand-code-panel`, `chevron-left`) stays anchored on the right edge of the documentation container on desktop (`hidden lg:flex`) to restore the panel on demand. Mobile screens use native drawer navigation and mobile tabs.

- **Empty Initial Value for Live Client Parameters**:
  - Updated parameter initialization in [src/index.html](file:///Users/rioastamal/Projects/openapi-swagger-viewer/src/index.html) so parameters without an explicit `example`, `default`, or `enum` are initialized to empty string (`""`) rather than pre-filling `"sample_value"`.
  - Preserves the placeholder text (`placeholder="${p.example !== undefined ? p.example : p.type}"`) so users see guidance without having to manually backspace or clear pre-filled dummy strings.

- **GitHub-Flavored Markdown (GFM) Alert Box Support**:
  - Upgraded `renderMarkdown()` in [src/index.html](file:///Users/rioastamal/Projects/openapi-swagger-viewer/src/index.html) to support multi-line GFM alert callouts.
  - Alert types supported:
    - `> [!NOTE]` / `> [!INFO]`: Blue accent banner with `info` icon.
    - `> [!TIP]`: Emerald green accent banner with `lightbulb` icon.
    - `> [!IMPORTANT]`: Violet accent banner with `alert-circle` icon.
    - `> [!WARNING]`: Amber/orange accent banner with `alert-triangle` icon.
    - `> [!CAUTION]`: Rose/red accent banner with `shield-alert` icon.
  - Standard blockquotes (`> text`) without `[!TYPE]` are rendered as styled neutral quote callouts.
  - Inline formatting (backticks code, bold, italic, links) inside alert boxes is properly preserved and rendered.
  - Fully supports both light and dark themes.

- **Masked Authorization Input with Eye Toggle**:
  - Masked the API authorization token inputs (`type="password"`) by default in both the **API Authorization Modal** and the **Live Client (Try It)** input.
  - Added an eye/eye-off toggle icon button to each input allowing users to securely preview or hide their token as plaintext on demand.

- **Server URL Override Option (`--server-url`)**:
  - Added `--server-url <url>` option to [build.sh](file:///Users/rioastamal/Projects/openapi-swagger-viewer/build.sh) allowing users to override the API server/base URL defined in OpenAPI 3.x (`servers[0].url`) or Swagger 2.0 (`host`/`basePath`/`schemes`).
  - Injected via `// __EMBEDDED_SERVER_URL_START__` / `// __EMBEDDED_SERVER_URL_END__` markers into `EMBEDDED_SERVER_URL` in [src/index.html](file:///Users/rioastamal/Projects/openapi-swagger-viewer/src/index.html).
  - When specified, `parseOpenApiSpec` prioritizes `EMBEDDED_SERVER_URL` across documentation headers, code snippet generators (`curl`, `javascript`, `php`, `golang`), and live browser request execution.

- **Header Simplification**:
  - Removed the `OpenAPI 3.x` / `OAS 3.0` specification type badge (`#header-spec-type`) from the header toolbar in both [src/index.html](file:///Users/rioastamal/Projects/openapi-swagger-viewer/src/index.html) and [build/index.html](file:///Users/rioastamal/Projects/openapi-swagger-viewer/build/index.html).

- **Separated JSON Spec & Viewer**:
  - Decoupled specification from `src/index.html` using markers (`// __EMBEDDED_SPEC_START__` / `// __EMBEDDED_SPEC_END__`).
  - Added clean empty-state view for direct browser preview.
  - Reduced `src/index.html` from ~321 KB down to ~144 KB.

- **Authorization Token Management (`Authorization: Bearer <API_TOKEN>`)**:
  - Added dedicated **Authorize** button in top header navbar and **Authorization** field in the interactive Try It panel.
  - Features a modal dialog allowing users to enter, save, or clear their Bearer Token / API Key.
  - Automatically persists the token to `localStorage` (`openapi_viewer_api_token`).
  - Code generators for **cURL**, **JavaScript (Fetch)**, **PHP**, and **Golang** now include `Authorization: Bearer <API_TOKEN>` (or `YOUR_API_TOKEN` fallback if empty).
  - The interactive client runner (`executeLiveRequest`) automatically includes the `Authorization` header on live browser fetch requests.
  - Fixed focus loss bug on keystroke in the Authorization input box by preventing DOM re-renders of the input container while typing.

- **Custom Documentation Pages (`x-pages`)**:
  - Added support for custom non-endpoint documentation pages via OpenAPI top-level `x-pages` or `info["x-pages"]`.
  - Schema: each page has `id`, `title`, `icon` (Lucide icon name), and `content` (Markdown string with fenced code blocks).
  - Sidebar: renders an **Overview & Guides** section above endpoints with search filtering.
  - Reader View: displays full-width formatted Markdown documentation with syntax-highlighted code blocks, blockquotes, and lists.
  - Added rich example pages ("Introduction" and "Registration & Authentication") in `examples/petstore.json`.

- **Theme Extraction & Modular Architecture**:
  - Extracted theme styling into dedicated CSS file `src/themes/default.css`.
  - Uses CSS custom properties (`--theme-brand-accent`, `--theme-bg-body`, `--theme-text-main`, `--theme-border`) for easy app branding customization.
  - In `src/index.html`, linked via `<link rel="stylesheet" href="themes/default.css">` wrapped by `<!-- __THEME_START__ -->` / `<!-- __THEME_END__ -->`.

- **Build Script (`build.sh`)**:
  - Standalone Bash script supporting macOS Bash 3.2 and Linux.
  - Standard invocation always includes: `bash build.sh --spec-file <PATH> --disable-upload --disable-load-url`.
  - Flags: `-s`/`--spec-file`, `-o`/`--output`, `-t`/`--template`, `--theme`, `--server-url`, `-m`/`--minify`, `--disable-load-url`, `--disable-upload`, `-h`/`--help`.
