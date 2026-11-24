You are a Principal JavaScript Engineer specializing in pure Vanilla JS, modern Web APIs, and high-performance, frameworkless DOM architecture. 

Your task is to write a complete, production-quality, responsive OpenAPI (Swagger) documentation viewer and interactive client contained entirely within a single `index.html` file.

---

### 1. Strict Technical Constraints

- **Single File Output**: Everything must live in one self-contained `index.html` file (HTML, CSS, and Vanilla JS in a `<script>` tag).
- **Vanilla JavaScript Only**: 
  - **NO frameworks or reactive libraries** of any kind (No React, Vue, Alpine.js, Svelte, Preact, Lit, etc.).
  - Must use modern, standards-compliant ES6+ Vanilla JS (`const`/`let`, arrow functions, template literals, `async/await`, `fetch`, `EventTarget` or clean pure-JS state management).
  - DOM manipulation must be executed cleanly using native DOM methods (`querySelector`, `innerHTML`, `createElement`, or template literal rendering with event delegation).
- **Allowed CDN Libraries**:
  - Tailwind CSS via CDN (`https://cdn.tailwindcss.com`).
  - Code syntax highlighting via CDN (e.g., PrismJS or Highlight.js script and stylesheet for highlighting the generated code and JSON responses).
  - Optional icon library via CDN (e.g., Lucide Icons or inline SVGs).
  - YAML parser via CDN (`js-yaml`, e.g. `https://cdnjs.cloudflare.com/ajax/libs/js-yaml/4.1.0/js-yaml.min.js`) to parse OpenAPI/Swagger YAML specifications in the browser.
- **No Build Tools**: Runs directly by opening `index.html` in any modern web browser.

---

### 2. Architecture & State Management (Vanilla JS)

Structure the client-side JavaScript cleanly using a predictable, single-state pattern:
1. **Central State Object**: Maintain application state in a single object (e.g., `const state = { spec: null, selectedEndpoint: null, filterText: '', activeResponseCode: null, activeMobileTab: 'docs' };`).
2. **State Updates & Render Pipeline**: Mutate state through dedicated functions and trigger targeted re-renders (e.g., `renderSidebar()`, `renderDetails()`, `renderCodeSnippet()`) to avoid unnecessary full-page DOM destruction.
3. **Event Delegation**: Attach event listeners efficiently to parent containers where appropriate.

---

### 3. Layout & Responsive Structure

Default layout is a **3-column desktop layout** (`lg:` breakpoint) that gracefully adapts to mobile devices:

1. **Top Header**:
   - API Title & Version indicator.
   - **Spec Controls**:
     - Remote URL input with a "Fetch" button to load remote OpenAPI JSON or YAML.
     - Local file picker (`<input type="file" accept=".json,.yaml,.yml">`) to load a JSON or YAML spec directly from the user's disk via `FileReader`.
     - "Reset Demo" button to quickly reload a pre-embedded default sample spec (Petstore or similar) so the UI is fully populated on first open.
     - Error/status banner for invalid JSON/YAML, failed fetches, or CORS errors.

2. **Left Column (API Navigation - approx. 20-25% width)**:
   - Sticky full-height scrollable sidebar.
   - Search input that filters paths, tags, and methods in real-time (`input` event).
   - Endpoints grouped cleanly by OpenAPI `tags`.
   - Method badges with distinct styling:
     - `GET` (emerald/blue)
     - `POST` (indigo/green)
     - `PUT`/`PATCH` (amber/yellow)
     - `DELETE` (rose/red)
   - Visually highlighted active/selected item.

3. **Middle Column (API Documentation & Payload - approx. 45-50% width)**:
   - Method badge, full path URL, summary, and markdown/plain text description.
   - **Parameters Section**: Clean table displaying query, path, and header parameters (Name, In, Type, Required badge, Description).
   - **Request Body Section**:
     - Content-Type display (`application/json`).
     - Formatted payload preview / schema showing expected JSON structure and example values.
   - **Responses Section**:
     - Status code tabs (e.g., `200`, `400`, `404`, `500`).
     - Formatted, syntax-highlighted sample JSON response for the active status code tab.

4. **Right Column (JavaScript Code Example - approx. 30% width)**:
   - Sticky dark-mode terminal/card view.
   - **JavaScript Only**: Dynamically generates modern, ready-to-run JavaScript `fetch()` / `async/await` code to call the selected endpoint.
   - Dynamically includes:
     - The target URL (interpolating path parameters or base URL).
     - HTTP method (`GET`, `POST`, etc.).
     - Headers (e.g., `Content-Type: application/json`, `Accept: application/json`).
     - Formatted `body: JSON.stringify(...)` if the endpoint accepts a payload.
   - "Copy Code" button with temporary visual confirmation ("Copied!").

5. **Mobile Responsiveness (`< 1024px`)**:
   - Header collapses cleanly.
   - Navigation becomes a slide-out drawer or collapsible toggle.
   - Middle and Right columns stack or toggle between "Docs" and "Code" via a mobile tab bar.

---

### 4. Spec Ingestion & Standalone Build (`build.sh`)

- Support both **OpenAPI 3.x** and **Swagger 2.0** specifications in **JSON and YAML** formats.
- Include a simple internal dereferencing helper or fallback resolver for `$ref` schemas (e.g., resolving `#/definitions/...` or `#/components/schemas/...`).
- `build.sh` treats `--spec-file <path>` as **optional**:
  - When `--spec-file` is provided (JSON or YAML), validate/convert it and inject it into `EMBEDDED_OPENAPI_SPEC` so the generated `index.html` works immediately offline.
  - When `--spec-file` is omitted, leave `EMBEDDED_OPENAPI_SPEC = null` to build a standalone generic viewer that boots into the empty/welcome state ready for local file upload or remote URL loading.
  - Reject building without `--spec-file` when both `--disable-upload` and `--disable-load-url` are set, as the resulting viewer would have no way to load any specification.

---

### 5. Implementation Constraints

- Produce the **entire, complete `index.html`** file from `<!DOCTYPE html>` to `</html>`.
- **Do not use placeholders**, ellipsis (`...`), or `// TODO` comments. Every function must be fully implemented and working.
- Clean, minimalist aesthetic (neutral slate/zinc tones, refined borders, subtle hover effects).
