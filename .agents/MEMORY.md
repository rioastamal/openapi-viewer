# User Preferences & Reusable Knowledge

- **Spec Separation**:
  - The OpenAPI/Swagger JSON specifications must remain decoupled from the HTML viewer template (`src/index.html`).
  - Example specifications reside in the `examples/` directory (`examples/petstore.json`).

- **Theme Customization**:
  - Theme styles are located in `src/themes/<theme-name>.css` (default: `src/themes/default.css`).
  - New themes can be created in `src/themes/` to match application branding.

- **Build Script Preference**:
  - The user prefers Bash for build and injection tooling (`build.sh`).
  - Standard invocation: `bash build.sh --spec-file /path/to/openapi/spec-file.json`.
  - Must remain compatible with macOS default Bash 3.2.
  - Theme selection: `--theme <THEME_NAME>` inlines the chosen CSS into `<style id="theme-style">` (defaults to `default`).
  - Component toggles: `--disable-load-url` and `--disable-upload` omit corresponding components from the built bundle.
