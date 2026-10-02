# Implementation Summary

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
