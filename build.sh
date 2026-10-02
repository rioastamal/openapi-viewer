#!/usr/bin/env bash
# ==============================================================================
# OpenAPI / Swagger Viewer - Single-File Distribution Builder
# ==============================================================================
# Injects an OpenAPI / Swagger JSON specification into the standalone viewer template.
#
# Usage:
#   bash build.sh --spec-file /path/to/spec.json
#   bash build.sh --spec-file spec.json --output dist/index.html
#   bash build.sh --spec-file spec.json --theme default
#   bash build.sh --spec-file spec.json --template src/index.html --minify
#   bash build.sh --spec-file spec.json --disable-load-url --disable-upload
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[31m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_BLUE='\033[34m'
C_CYAN='\033[36m'
C_GRAY='\033[90m'

# Disable colors if stdout is not a TTY or NO_COLOR is set
if [ ! -t 1 ] || [ "${NO_COLOR:-}" != "" ]; then
  C_RESET=''
  C_BOLD=''
  C_RED=''
  C_GREEN=''
  C_YELLOW=''
  C_BLUE=''
  C_CYAN=''
  C_GRAY=''
fi

log_info() {
  echo -e "${C_BLUE}${C_BOLD}[INFO]${C_RESET} $*"
}

log_success() {
  echo -e "${C_GREEN}${C_BOLD}[SUCCESS]${C_RESET} $*"
}

log_warn() {
  echo -e "${C_YELLOW}${C_BOLD}[WARN]${C_RESET} $*"
}

log_error() {
  echo -e "${C_RED}${C_BOLD}[ERROR]${C_RESET} $*" >&2
}

print_usage() {
  cat << USAGE
${C_BOLD}OpenAPI / Swagger Viewer Build Script${C_RESET}

${C_CYAN}Usage:${C_RESET}
  bash build.sh --spec-file <path-to-json> [options]
  ./build.sh -s <path-to-json> [-o <output-path>]

${C_CYAN}Options:${C_RESET}
  -s, --spec-file <path>    Path to OpenAPI or Swagger JSON specification file (Required)
  -o, --output <path>       Output standalone HTML file path (Default: build/index.html)
  -t, --template <path>     Viewer HTML template file path (Default: src/index.html)
      --theme <name|path>   Theme name or CSS file path (Default: default)
      --server-url <url>    Override default API server/base URL from JSON spec
  -m, --minify              Minify JSON specification before injection
      --disable-load-url    Disable / omit the remote URL input and fetch component
      --disable-upload      Disable / omit the local JSON file upload component
  -h, --help                Show this help message and exit

${C_CYAN}Examples:${C_RESET}
  bash build.sh --spec-file examples/petstore.json
  bash build.sh --spec-file spec.json --theme default
  bash build.sh --spec-file spec.json --output dist/index.html --minify
  bash build.sh --spec-file examples/petstore.json --server-url https://api.prod.example.com/v1
  bash build.sh --spec-file examples/petstore.json --disable-load-url --disable-upload
USAGE
}

# Default Configuration
SPEC_FILE=""
OUTPUT_FILE="build/index.html"
TEMPLATE_FILE="src/index.html"
THEME="default"
SERVER_URL=""
MINIFY=false
DISABLE_LOAD_URL=false
DISABLE_UPLOAD=false

# Argument Parsing (compatible with macOS Bash 3.2 and modern Bash/Zsh)
while [ $# -gt 0 ]; do
  case "$1" in
    -s|--spec-file)
      if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
        log_error "Missing value for $1"
        print_usage
        exit 1
      fi
      SPEC_FILE="$2"
      shift 2
      ;;
    -o|--output)
      if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
        log_error "Missing value for $1"
        print_usage
        exit 1
      fi
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -t|--template)
      if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
        log_error "Missing value for $1"
        print_usage
        exit 1
      fi
      TEMPLATE_FILE="$2"
      shift 2
      ;;
    --theme)
      if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
        log_error "Missing value for $1"
        print_usage
        exit 1
      fi
      THEME="$2"
      shift 2
      ;;
    --server-url)
      if [ -z "${2:-}" ] || [[ "$2" == -* ]]; then
        log_error "Missing value for $1"
        print_usage
        exit 1
      fi
      SERVER_URL="$2"
      shift 2
      ;;
    -m|--minify)
      MINIFY=true
      shift
      ;;
    --disable-load-url)
      DISABLE_LOAD_URL=true
      shift
      ;;
    --disable-upload)
      DISABLE_UPLOAD=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    -*)
      log_error "Unknown option: $1"
      print_usage
      exit 1
      ;;
    *)
      # Fallback: support positional argument for spec file if not already set
      if [ -z "$SPEC_FILE" ]; then
        SPEC_FILE="$1"
        shift
      else
        log_error "Unexpected positional argument: $1"
        print_usage
        exit 1
      fi
      ;;
  esac
done

# Step 1: Validate required parameters
if [ -z "$SPEC_FILE" ]; then
  log_error "--spec-file is required."
  print_usage
  exit 1
fi

# Step 2: Validate template file existence
if [ ! -f "$TEMPLATE_FILE" ]; then
  log_error "Template file not found: '$TEMPLATE_FILE'"
  exit 1
fi

# Step 3: Validate spec file existence
if [ ! -f "$SPEC_FILE" ]; then
  log_error "Specification file not found: '$SPEC_FILE'"
  exit 1
fi

if [ ! -s "$SPEC_FILE" ]; then
  log_error "Specification file is empty: '$SPEC_FILE'"
  exit 1
fi

# Step 4: Resolve and validate theme CSS file
TEMPLATE_DIR="$(dirname "$TEMPLATE_FILE")"
THEME_FILE=""

if [ -f "$THEME" ]; then
  THEME_FILE="$THEME"
elif [ -f "src/themes/${THEME}" ]; then
  THEME_FILE="src/themes/${THEME}"
elif [ -f "src/themes/${THEME}.css" ]; then
  THEME_FILE="src/themes/${THEME}.css"
elif [ -f "$TEMPLATE_DIR/themes/${THEME}" ]; then
  THEME_FILE="$TEMPLATE_DIR/themes/${THEME}"
elif [ -f "$TEMPLATE_DIR/themes/${THEME}.css" ]; then
  THEME_FILE="$TEMPLATE_DIR/themes/${THEME}.css"
else
  log_error "Theme file not found for theme '$THEME'."
  log_error "Searched: '$THEME', 'src/themes/${THEME}.css', 'src/themes/${THEME}'"
  exit 1
fi

if [ ! -s "$THEME_FILE" ]; then
  log_error "Theme file is empty: '$THEME_FILE'"
  exit 1
fi

log_info "Validating specification JSON: ${C_CYAN}$SPEC_FILE${C_RESET}"

# Step 5: Validate JSON structure using available tools (python3 -> jq -> node)
IS_VALID_JSON=false

if command -v python3 >/dev/null 2>&1; then
  if python3 -c "import json, sys; json.load(open('$SPEC_FILE'))" >/dev/null 2>&1; then
    IS_VALID_JSON=true
  fi
elif command -v jq >/dev/null 2>&1; then
  if jq empty "$SPEC_FILE" >/dev/null 2>&1; then
    IS_VALID_JSON=true
  fi
elif command -v node >/dev/null 2>&1; then
  if node -e "JSON.parse(require('fs').readFileSync('$SPEC_FILE', 'utf8'))" >/dev/null 2>&1; then
    IS_VALID_JSON=true
  fi
else
  log_warn "Neither python3, jq, nor node found to validate JSON syntax. Proceeding with caution."
  IS_VALID_JSON=true
fi

if [ "$IS_VALID_JSON" = false ]; then
  log_error "Specification file '$SPEC_FILE' is not valid JSON."
  exit 1
fi

# Step 6: Validate template injection markers
MARKER_START="// __EMBEDDED_SPEC_START__"
MARKER_END="// __EMBEDDED_SPEC_END__"
MARKER_THEME_START="<!-- __THEME_START__ -->"
MARKER_THEME_END="<!-- __THEME_END__ -->"

if ! grep -q "$MARKER_START" "$TEMPLATE_FILE" || ! grep -q "$MARKER_END" "$TEMPLATE_FILE"; then
  log_error "Template file '$TEMPLATE_FILE' is missing spec injection markers."
  log_error "Expected markers: '$MARKER_START' and '$MARKER_END'"
  exit 1
fi

# Step 7: Prepare Output Directory
OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

# Step 8: Prepare JSON stream (minified or formatted)
TEMP_SPEC="$(mktemp "${TMPDIR:-/tmp}/spec.XXXXXX")"
TEMP_BUILD="$(mktemp "${TMPDIR:-/tmp}/viewer.XXXXXX")"
TEMP_FILTERED="$(mktemp "${TMPDIR:-/tmp}/viewer_filtered.XXXXXX")"
TEMP_THEMED="$(mktemp "${TMPDIR:-/tmp}/viewer_themed.XXXXXX")"
trap 'rm -f "$TEMP_SPEC" "$TEMP_BUILD" "$TEMP_FILTERED" "$TEMP_THEMED" "${TEMP_SERVER:-}"' EXIT

if [ "$MINIFY" = true ]; then
  log_info "Minifying specification JSON..."
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json, sys; json.dump(json.load(open('$SPEC_FILE')), open('$TEMP_SPEC', 'w'), separators=(',', ':'))"
  elif command -v jq >/dev/null 2>&1; then
    jq -c . "$SPEC_FILE" > "$TEMP_SPEC"
  elif command -v node >/dev/null 2>&1; then
    node -e "const d = JSON.parse(require('fs').readFileSync('$SPEC_FILE', 'utf8')); require('fs').writeFileSync('$TEMP_SPEC', JSON.stringify(d));"
  else
    log_warn "Minifier tool not found. Using original file."
    cp "$SPEC_FILE" "$TEMP_SPEC"
  fi
else
  cp "$SPEC_FILE" "$TEMP_SPEC"
fi

# Step 9: Stream-inject spec into template
# Uses robust POSIX streaming with sed + cat, avoiding memory limits or escape bugs
log_info "Injecting specification into standalone bundle..."

# Part 1: Lines from start of template up to and including the start marker
sed -e "/\/\/ __EMBEDDED_SPEC_START__/q" "$TEMPLATE_FILE" > "$TEMP_BUILD"

# Part 2: Injected JavaScript constant declaration + JSON content + semicolon
echo "    const EMBEDDED_OPENAPI_SPEC = " >> "$TEMP_BUILD"
cat "$TEMP_SPEC" >> "$TEMP_BUILD"
echo ";" >> "$TEMP_BUILD"

# Part 3: Injected end marker + lines from end marker to end of template
echo "    // __EMBEDDED_SPEC_END__" >> "$TEMP_BUILD"
sed -e "1,/\/\/ __EMBEDDED_SPEC_END__/d" "$TEMPLATE_FILE" >> "$TEMP_BUILD"

# Step 9a: Inject server URL override if specified
MARKER_SERVER_START="__EMBEDDED_SERVER_URL_START__"
MARKER_SERVER_END="__EMBEDDED_SERVER_URL_END__"

if grep -q "$MARKER_SERVER_START" "$TEMP_BUILD" && grep -q "$MARKER_SERVER_END" "$TEMP_BUILD"; then
  TEMP_SERVER="$(mktemp "${TMPDIR:-/tmp}/viewer_server.XXXXXX")"
  sed -e "/$MARKER_SERVER_START/q" "$TEMP_BUILD" > "$TEMP_SERVER"
  if [ -n "$SERVER_URL" ]; then
    log_info "Overriding server base URL: ${C_CYAN}$SERVER_URL${C_RESET}"
    echo "    const EMBEDDED_SERVER_URL = \"$SERVER_URL\";" >> "$TEMP_SERVER"
  else
    echo "    const EMBEDDED_SERVER_URL = null;" >> "$TEMP_SERVER"
  fi
  echo "    // __EMBEDDED_SERVER_URL_END__" >> "$TEMP_SERVER"
  sed -e "1,/$MARKER_SERVER_END/d" "$TEMP_BUILD" >> "$TEMP_SERVER"
  mv "$TEMP_SERVER" "$TEMP_BUILD"
fi


# Step 9b: Stream-inject theme CSS into bundle
if grep -q "$MARKER_THEME_START" "$TEMP_BUILD" && grep -q "$MARKER_THEME_END" "$TEMP_BUILD"; then
  log_info "Injecting theme: ${C_CYAN}$THEME${C_RESET} (${C_GRAY}$THEME_FILE${C_RESET})"
  sed -e "/$MARKER_THEME_START/q" "$TEMP_BUILD" > "$TEMP_THEMED"
  echo "  <style id=\"theme-style\">" >> "$TEMP_THEMED"
  cat "$THEME_FILE" >> "$TEMP_THEMED"
  echo "" >> "$TEMP_THEMED"
  echo "  </style>" >> "$TEMP_THEMED"
  sed -e "1,/$MARKER_THEME_END/d" "$TEMP_BUILD" >> "$TEMP_THEMED"
  mv "$TEMP_THEMED" "$TEMP_BUILD"
else
  log_warn "Theme injection markers not found in template. Skipping theme inlining."
fi

# Step 9c: Process component toggle flags (--disable-load-url, --disable-upload)
if [ "$DISABLE_LOAD_URL" = true ]; then
  log_info "Disabling remote URL component (--disable-load-url)..."
  sed -e "/__COMPONENT_LOAD_URL_START__/,/__COMPONENT_LOAD_URL_END__/d" "$TEMP_BUILD" > "$TEMP_FILTERED"
  mv "$TEMP_FILTERED" "$TEMP_BUILD"
else
  # Strip comment markers for a clean production build
  sed -e "/__COMPONENT_LOAD_URL_/d" "$TEMP_BUILD" > "$TEMP_FILTERED"
  mv "$TEMP_FILTERED" "$TEMP_BUILD"
fi

if [ "$DISABLE_UPLOAD" = true ]; then
  log_info "Disabling file upload component (--disable-upload)..."
  sed -e "/__COMPONENT_UPLOAD_START__/,/__COMPONENT_UPLOAD_END__/d" "$TEMP_BUILD" > "$TEMP_FILTERED"
  mv "$TEMP_FILTERED" "$TEMP_BUILD"
else
  # Strip comment markers for a clean production build
  sed -e "/__COMPONENT_UPLOAD_/d" "$TEMP_BUILD" > "$TEMP_FILTERED"
  mv "$TEMP_FILTERED" "$TEMP_BUILD"
fi

# Move generated file to destination atomically
mv "$TEMP_BUILD" "$OUTPUT_FILE"

# Step 10: Report build results
SPEC_SIZE=$(ls -lh "$SPEC_FILE" | awk '{print $5}')
BUNDLE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
TOTAL_LINES=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')

echo ""
log_success "${C_BOLD}Bundle built successfully!${C_RESET}"
echo -e "  ${C_GRAY}•${C_RESET} Specification:  ${C_CYAN}$SPEC_FILE${C_RESET} ($SPEC_SIZE)"
echo -e "  ${C_GRAY}•${C_RESET} Template:       ${C_CYAN}$TEMPLATE_FILE${C_RESET}"
echo -e "  ${C_GRAY}•${C_RESET} Theme:          ${C_CYAN}$THEME${C_RESET} ($THEME_FILE)"
echo -e "  ${C_GRAY}•${C_RESET} Server URL:     $([ -n "$SERVER_URL" ] && echo -e "${C_CYAN}$SERVER_URL${C_RESET} (overridden)" || echo -e "${C_GRAY}Default from specification${C_RESET}")"
echo -e "  ${C_GRAY}•${C_RESET} Output:         ${C_GREEN}${C_BOLD}$OUTPUT_FILE${C_RESET} ($BUNDLE_SIZE, $TOTAL_LINES lines)"
echo -e "  ${C_GRAY}•${C_RESET} Remote URL:     $([ "$DISABLE_LOAD_URL" = true ] && echo -e "${C_YELLOW}Disabled (omitted)${C_RESET}" || echo -e "${C_GREEN}Enabled${C_RESET}")"
echo -e "  ${C_GRAY}•${C_RESET} File Upload:    $([ "$DISABLE_UPLOAD" = true ] && echo -e "${C_YELLOW}Disabled (omitted)${C_RESET}" || echo -e "${C_GREEN}Enabled${C_RESET}")"
echo -e "  ${C_GRAY}•${C_RESET} Standalone:     ${C_BOLD}Yes (Open directly in any modern web browser)${C_RESET}"
echo ""
