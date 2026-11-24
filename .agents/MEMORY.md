# User Preferences & Reusable Knowledge

- **Keeping `.agents/CONTEXT.md` Up to Date**:
  - Whenever fundamental changes are requested (architecture, state structure, layout, panel behavior, Live Client features, or build pipeline), always update `.agents/CONTEXT.md` immediately alongside the code changes—do not only update `.agents/SUMMARY.md`.

- **Commit Message Style**:
  - When asked to draft a git commit message, only provide the message itself (no command or extra explanation).
  - Always keep it super short and concise.

- **Spec Separation**:
  - The OpenAPI/Swagger JSON specifications must remain decoupled from the HTML viewer template (`src/index.html`).
  - Example specifications reside in the `examples/` directory (`examples/petstore.json`).

- **Server URL Override (`--server-url`)**:
  - Users can override the base URL defined in the OpenAPI/Swagger JSON by passing `--server-url <url>` to `build.sh`.
  - Injected as `const EMBEDDED_SERVER_URL` and applied across all views, code generators, and live request calls.

- **Authorization Token (`Authorization: Bearer <API_TOKEN>`)**:
  - Authorization input is accessible via the top navigation bar modal ("Authorize") as well as an inline header field within the "Try It" interactive client panel.
  - Automatically injected across all 4 code generators (`curl`, `javascript`, `php`, `golang`) and sent in live requests executed by `executeLiveRequest()`.
  - Persisted in browser session `localStorage` under `openapi_viewer_api_token`.

- **Custom Documentation Pages (`x-pages`)**:
  - Custom pages are declared at the root of the OpenAPI JSON (or under `info`) via the `x-pages` vendor extension array.
  - Page fields:
    - `id`: Unique identifier (e.g. `introduction`, `registration`)
    - `title`: Display label in sidebar
    - `icon`: Lucide icon name (e.g. `book-open`, `key`, `shield`, `terminal`)
    - `content`: Markdown text supporting headers, blockquotes, bold/italic, lists, and fenced code blocks.

- **Theme Customization**:
  - Theme styles are located in `src/themes/<theme-name>.css` (default: `src/themes/default.css`).
  - New themes can be created in `src/themes/` to match application branding.

- **Build Script Preference & Standard Flags**:
  - The user prefers Bash for build and injection tooling (`build.sh`).
  - **Always pass `--disable-upload` and `--disable-load-url`** when building `index.html`.
  - Standard invocation: `bash build.sh --spec-file <SPEC_PATH> --disable-upload --disable-load-url`.
  - Must remain compatible with macOS default Bash 3.2.
  - Theme selection: `--theme <THEME_NAME>` inlines the chosen CSS into `<style id="theme-style">` (defaults to `default`).
  - Server URL override: `--server-url <url>` overrides the specification base URL.
