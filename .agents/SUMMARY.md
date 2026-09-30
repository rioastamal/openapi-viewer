# Implementation Summary

- **Separated JSON Spec & Viewer**:
  - Decoupled specification from `src/index.html` using markers (`// __EMBEDDED_SPEC_START__` / `// __EMBEDDED_SPEC_END__`).
  - Added clean empty-state view for direct browser preview.
  - Reduced `src/index.html` from ~321 KB down to ~144 KB.

- **Lightweight Example Specification**:
  - Replaced the large ~175 KB example spec files with a compact, canonical Swagger Petstore OpenAPI 3.0 spec in `examples/petstore.json` (7.6 KB, 310 lines).

- **Theme Extraction & Modular Architecture**:
  - Extracted theme styling into dedicated CSS file [src/themes/default.css](file:///Users/rioastamal/Projects/openapi-swagger-viewer/src/themes/default.css).
  - Uses CSS custom properties (`--theme-brand-accent`, `--theme-bg-body`, `--theme-text-main`, `--theme-border`) for easy app branding customization.
  - In `src/index.html`, linked via `<link rel="stylesheet" href="themes/default.css">` wrapped by `<!-- __THEME_START__ -->` / `<!-- __THEME_END__ -->`.

- **Removed Embedded-Spec Dropdown**:
  - Deleted redundant `#select-demo-preset` select dropdown from header and related event handlers.

- **Build Script (`build.sh`)**:
  - Standalone Bash script supporting macOS Bash 3.2 and Linux.
  - Syntax: `bash build.sh --spec-file <path> [options]`.
  - Flags: `-s`/`--spec-file`, `-o`/`--output`, `-t`/`--template`, `--theme`, `-m`/`--minify`, `--disable-load-url`, `--disable-upload`, `-h`/`--help`.
  - Added `--theme <THEME_NAME>`: automatically resolves theme files in `src/themes/` or custom file paths and inlines CSS into a `<style id="theme-style">` tag in the output bundle (defaults to `default`).
