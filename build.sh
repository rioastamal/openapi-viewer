#!/usr/bin/env bash
# ==============================================================================
# OpenAPI / Swagger Viewer - Single-File Distribution Builder
# ==============================================================================
# Injects an OpenAPI / Swagger JSON or YAML specification into the standalone
# viewer template.
#
# Usage:
#   bash build.sh --spec-file /path/to/spec.json
#   bash build.sh --spec-file /path/to/spec.yaml
#   bash build.sh --spec-file spec.yaml --output dist/index.html
#   bash build.sh --spec-file spec.json --theme default
#   bash build.sh --spec-file spec.json --template src/index.html --minify
#   bash build.sh --spec-file spec.yaml --disable-load-url --disable-upload
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
  bash build.sh --spec-file <path-to-json-or-yaml> [options]
  ./build.sh -s <path-to-json-or-yaml> [-o <output-path>]

${C_CYAN}Options:${C_RESET}
  -s, --spec-file <path>    Path to OpenAPI/Swagger JSON or YAML specification file (Required)
  -o, --output <path>       Output standalone HTML file path (Default: build/index.html)
  -t, --template <path>     Viewer HTML template file path (Default: src/index.html)
      --theme <name|path>   Theme name or CSS file path (Default: default)
      --server-url <url>    Override default API server/base URL from specification
  -m, --minify              Minify specification JSON before injection
      --disable-load-url    Disable / omit the remote URL input and fetch component
      --disable-upload      Disable / omit the local file upload component
  -h, --help                Show this help message and exit

${C_CYAN}Examples:${C_RESET}
  bash build.sh --spec-file examples/petstore.json
  bash build.sh --spec-file examples/petstore.yaml
  bash build.sh --spec-file spec.yaml --theme default --minify
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

# Step 5: Detect specification format (JSON vs YAML)
SPEC_FILE_LOWER="$(printf '%s' "$SPEC_FILE" | tr '[:upper:]' '[:lower:]')"
SPEC_FORMAT=""

case "$SPEC_FILE_LOWER" in
  *.yaml|*.yml)
    SPEC_FORMAT="yaml"
    ;;
  *.json)
    SPEC_FORMAT="json"
    ;;
  *)
    # Fallback: inspect first non-whitespace character
    FIRST_CHAR="$(awk '{
      for (i = 1; i <= length($0); i++) {
        ch = substr($0, i, 1)
        if (ch != " " && ch != "\t" && ch != "\r") {
          print ch
          exit
        }
      }
    }' "$SPEC_FILE")"
    if [ "$FIRST_CHAR" = "{" ] || [ "$FIRST_CHAR" = "[" ]; then
      SPEC_FORMAT="json"
    else
      SPEC_FORMAT="yaml"
    fi
    ;;
esac

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

# Step 7: Prepare Output Directory & Temp Files
OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
fi

TEMP_SPEC="$(mktemp "${TMPDIR:-/tmp}/spec.XXXXXX")"
TEMP_BUILD="$(mktemp "${TMPDIR:-/tmp}/viewer.XXXXXX")"
TEMP_FILTERED="$(mktemp "${TMPDIR:-/tmp}/viewer_filtered.XXXXXX")"
TEMP_THEMED="$(mktemp "${TMPDIR:-/tmp}/viewer_themed.XXXXXX")"
TEMP_ERR="$(mktemp "${TMPDIR:-/tmp}/spec_err.XXXXXX")"
trap 'rm -f "$TEMP_SPEC" "$TEMP_BUILD" "$TEMP_FILTERED" "$TEMP_THEMED" "$TEMP_ERR" "${TEMP_SERVER:-}"' EXIT

# Step 8: Validate & prepare JSON stream (JSON or YAML -> JSON)
if [ "$SPEC_FORMAT" = "json" ]; then
  log_info "Validating specification JSON: ${C_CYAN}$SPEC_FILE${C_RESET}"
  IS_VALID_JSON=false

  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
if not isinstance(data, dict):
    sys.stderr.write('JSON error: root element must be a JSON object\n')
    sys.exit(1)
" "$SPEC_FILE" 2>"$TEMP_ERR"; then
      IS_VALID_JSON=true
    fi
  elif command -v jq >/dev/null 2>&1; then
    if jq -e 'type == "object"' "$SPEC_FILE" >/dev/null 2>"$TEMP_ERR"; then
      IS_VALID_JSON=true
    fi
  elif command -v node >/dev/null 2>&1; then
    if node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
if (!data || typeof data !== 'object' || Array.isArray(data)) {
  console.error('JSON error: root element must be a JSON object');
  process.exit(1);
}
" "$SPEC_FILE" 2>"$TEMP_ERR"; then
      IS_VALID_JSON=true
    fi
  else
    log_warn "Neither python3, jq, nor node found to validate JSON syntax. Proceeding with caution."
    IS_VALID_JSON=true
  fi

  if [ "$IS_VALID_JSON" = false ]; then
    log_error "Specification file '$SPEC_FILE' is not valid JSON."
    if [ -s "$TEMP_ERR" ]; then
      cat "$TEMP_ERR" >&2
    fi
    exit 1
  fi

  if [ "$MINIFY" = true ]; then
    log_info "Minifying specification JSON..."
    if command -v python3 >/dev/null 2>&1; then
      python3 -c "
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
with open(sys.argv[2], 'w', encoding='utf-8') as out:
    json.dump(data, out, separators=(',', ':'), ensure_ascii=False)
" "$SPEC_FILE" "$TEMP_SPEC"
    elif command -v jq >/dev/null 2>&1; then
      jq -c . "$SPEC_FILE" > "$TEMP_SPEC"
    elif command -v node >/dev/null 2>&1; then
      node -e "
const fs = require('fs');
const d = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
fs.writeFileSync(process.argv[2], JSON.stringify(d));
" "$SPEC_FILE" "$TEMP_SPEC"
    else
      log_warn "Minifier tool not found. Using original file."
      cp "$SPEC_FILE" "$TEMP_SPEC"
    fi
  else
    cp "$SPEC_FILE" "$TEMP_SPEC"
  fi
else
  log_info "Validating and converting YAML specification: ${C_CYAN}$SPEC_FILE${C_RESET}"
  YAML_CONVERTED=false
  YAML_TOOL_USED=""

  # 1. Try python3 + PyYAML
  if [ "$YAML_CONVERTED" = false ] && command -v python3 >/dev/null 2>&1; then
    if python3 -c "import yaml" >/dev/null 2>&1; then
      YAML_TOOL_USED="python3 (PyYAML)"
      if python3 -c "
import sys, json, yaml, datetime

spec_path, out_path, minify_flag = sys.argv[1], sys.argv[2], (sys.argv[3] == 'true')

try:
    with open(spec_path, 'r', encoding='utf-8') as f:
        docs = list(yaml.safe_load_all(f))
except yaml.YAMLError as e:
    sys.stderr.write(f'YAML syntax error: {e}\n')
    sys.exit(1)

if len(docs) == 0:
    sys.stderr.write('YAML error: specification file contains no YAML documents\n')
    sys.exit(1)
if len(docs) > 1:
    sys.stderr.write(f'YAML error: multiple YAML documents found ({len(docs)}); expected a single OpenAPI/Swagger document\n')
    sys.exit(1)

data = docs[0]
if data is None:
    sys.stderr.write('YAML error: specification document is empty/null\n')
    sys.exit(1)
if not isinstance(data, dict):
    sys.stderr.write(f'YAML error: root element must be a YAML object/mapping, got {type(data).__name__}\n')
    sys.exit(1)

def normalize(obj):
    if isinstance(obj, dict):
        res = {}
        for k, v in obj.items():
            if isinstance(k, (datetime.date, datetime.datetime)):
                ks = k.isoformat()
            elif isinstance(k, bool):
                ks = 'true' if k else 'false'
            elif k is None:
                ks = 'null'
            else:
                ks = str(k)
            res[ks] = normalize(v)
        return res
    if isinstance(obj, list):
        return [normalize(x) for x in obj]
    if isinstance(obj, (datetime.date, datetime.datetime)):
        return obj.isoformat()
    return obj

normalized = normalize(data)
for ver_key in ('openapi', 'swagger'):
    if ver_key in normalized and isinstance(normalized[ver_key], (int, float)):
        normalized[ver_key] = str(normalized[ver_key])

if 'openapi' not in normalized and 'swagger' not in normalized:
    sys.stderr.write(\"WARN: Root element does not contain 'openapi' or 'swagger' field.\n\")

with open(out_path, 'w', encoding='utf-8') as out:
    if minify_flag:
        json.dump(normalized, out, separators=(',', ':'), ensure_ascii=False)
    else:
        json.dump(normalized, out, indent=2, ensure_ascii=False)
" "$SPEC_FILE" "$TEMP_SPEC" "$MINIFY" 2>"$TEMP_ERR"; then
        YAML_CONVERTED=true
      else
        log_error "YAML validation failed for '$SPEC_FILE':"
        cat "$TEMP_ERR" >&2
        exit 1
      fi
    fi
  fi

  # 2. Try ruby (built-in yaml/Psych + json)
  if [ "$YAML_CONVERTED" = false ] && command -v ruby >/dev/null 2>&1; then
    YAML_TOOL_USED="ruby (Psych)"
    if ruby -ryaml -rjson -rdate -rtime -e '
spec_path = ARGV[0]
out_path = ARGV[1]
minify_flag = (ARGV[2] == "true")

content = File.read(spec_path, encoding: "UTF-8")

begin
  stream = Psych.parse_stream(content)
rescue Psych::SyntaxError => e
  abort("YAML syntax error: #{e.message}")
rescue Psych::Exception => e
  abort("YAML error: #{e.message}")
end

docs = stream.children
if docs.empty?
  abort("YAML error: specification file contains no YAML documents")
elsif docs.length > 1
  abort("YAML error: multiple YAML documents found (#{docs.length}); expected a single OpenAPI/Swagger document")
end

begin
  params = YAML.method(:safe_load).parameters.map(&:last)
  if params.include?(:permitted_classes)
    data = YAML.safe_load(content, permitted_classes: [Date, Time], aliases: true)
  else
    data = YAML.safe_load(content, [Date, Time], [], true)
  end
rescue Psych::SyntaxError => e
  abort("YAML syntax error: #{e.message}")
rescue Psych::Exception => e
  abort("YAML error: #{e.message}")
end

if data.nil?
  abort("YAML error: specification document is empty/null")
elsif !data.is_a?(Hash)
  abort("YAML error: root element must be a YAML object/mapping, got #{data.class}")
end

def normalize(obj)
  case obj
  when Hash
    obj.each_with_object({}) do |(k, v), h|
      key_str =
        if k.is_a?(Time)
          k.utc.iso8601
        elsif k.is_a?(Date)
          k.iso8601
        elsif k.nil?
          "null"
        else
          k.to_s
        end
      h[key_str] = normalize(v)
    end
  when Array
    obj.map { |v| normalize(v) }
  when Time
    obj.utc.iso8601
  when Date
    obj.iso8601
  when Symbol
    obj.to_s
  else
    obj
  end
end

normalized = normalize(data)
%w[openapi swagger].each do |ver_key|
  if normalized.key?(ver_key) && normalized[ver_key].is_a?(Numeric)
    normalized[ver_key] = normalized[ver_key].to_s
  end
end

if !normalized.key?("openapi") && !normalized.key?("swagger")
  warn("WARN: Root element does not contain '\''openapi'\'' or '\''swagger'\'' field.")
end

json_str = minify_flag ? JSON.generate(normalized) : JSON.pretty_generate(normalized)
File.write(out_path, json_str, encoding: "UTF-8")
' "$SPEC_FILE" "$TEMP_SPEC" "$MINIFY" 2>"$TEMP_ERR"; then
      YAML_CONVERTED=true
    else
      log_error "YAML validation failed for '$SPEC_FILE':"
      cat "$TEMP_ERR" >&2
      exit 1
    fi
  fi

  # 3. Try yq (mikefarah/yq or kislyuk/yq)
  if [ "$YAML_CONVERTED" = false ] && command -v yq >/dev/null 2>&1; then
    YAML_TOOL_USED="yq"
    if yq --version 2>&1 | grep -qi "mikefarah"; then
      YQ_OK=false
      if yq -o=json '.' "$SPEC_FILE" > "$TEMP_SPEC" 2>"$TEMP_ERR"; then
        YQ_OK=true
      fi
    else
      YQ_OK=false
      if yq '.' "$SPEC_FILE" > "$TEMP_SPEC" 2>"$TEMP_ERR"; then
        YQ_OK=true
      fi
    fi

    if [ "$YQ_OK" = false ]; then
      log_error "YAML validation failed for '$SPEC_FILE':"
      cat "$TEMP_ERR" >&2
      exit 1
    fi

    # Verify converted output is a single valid JSON object
    if command -v jq >/dev/null 2>&1; then
      if [ "$(jq -s 'length' "$TEMP_SPEC" 2>/dev/null || echo 0)" != "1" ] || ! jq -e 'type == "object"' "$TEMP_SPEC" >/dev/null 2>&1; then
        log_error "YAML error: specification must be a single YAML object/mapping"
        exit 1
      fi
      if [ "$MINIFY" = true ]; then
        jq -c . "$TEMP_SPEC" > "${TEMP_SPEC}.min" && mv "${TEMP_SPEC}.min" "$TEMP_SPEC"
      fi
    elif command -v python3 >/dev/null 2>&1; then
      if ! python3 -c "
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
if not isinstance(data, dict):
    sys.stderr.write('YAML error: root element must be a YAML object/mapping\n')
    sys.exit(1)
if sys.argv[2] == 'true':
    with open(sys.argv[1], 'w', encoding='utf-8') as out:
        json.dump(data, out, separators=(',', ':'), ensure_ascii=False)
" "$TEMP_SPEC" "$MINIFY" 2>"$TEMP_ERR"; then
        log_error "YAML validation failed for '$SPEC_FILE':"
        cat "$TEMP_ERR" >&2
        exit 1
      fi
    fi
    YAML_CONVERTED=true
  fi

  # 4. Try node + js-yaml or yaml package
  if [ "$YAML_CONVERTED" = false ] && command -v node >/dev/null 2>&1; then
    if node -e "
try { require('js-yaml'); process.exit(0); } catch (e) {}
try { require('yaml'); process.exit(0); } catch (e) {}
process.exit(1);
" >/dev/null 2>&1; then
      YAML_TOOL_USED="node (yaml)"
      if node -e "
const fs = require('fs');
const specPath = process.argv[1];
const outPath = process.argv[2];
const minifyFlag = process.argv[3] === 'true';
const raw = fs.readFileSync(specPath, 'utf8');

let docs = [];
try {
  let jsyaml = null;
  try { jsyaml = require('js-yaml'); } catch (_) {}
  if (jsyaml) {
    jsyaml.loadAll(raw, (doc) => docs.push(doc));
  } else {
    const yamlPkg = require('yaml');
    const parsedDocs = yamlPkg.parseAllDocuments(raw);
    for (const d of parsedDocs) {
      if (d.errors && d.errors.length > 0) {
        throw new Error(d.errors[0].message);
      }
      docs.push(d.toJSON());
    }
  }
} catch (err) {
  console.error('YAML syntax error: ' + err.message);
  process.exit(1);
}

if (docs.length === 0) {
  console.error('YAML error: specification file contains no YAML documents');
  process.exit(1);
}
if (docs.length > 1) {
  console.error('YAML error: multiple YAML documents found (' + docs.length + '); expected a single OpenAPI/Swagger document');
  process.exit(1);
}

const data = docs[0];
if (!data || typeof data !== 'object' || Array.isArray(data)) {
  console.error('YAML error: root element must be a YAML object/mapping');
  process.exit(1);
}

for (const k of ['openapi', 'swagger']) {
  if (typeof data[k] === 'number') data[k] = String(data[k]);
}
if (!('openapi' in data) && !('swagger' in data)) {
  console.error(\"WARN: Root element does not contain 'openapi' or 'swagger' field.\");
}

const out = minifyFlag ? JSON.stringify(data) : JSON.stringify(data, null, 2);
fs.writeFileSync(outPath, out, 'utf8');
" "$SPEC_FILE" "$TEMP_SPEC" "$MINIFY" 2>"$TEMP_ERR"; then
        YAML_CONVERTED=true
      else
        log_error "YAML validation failed for '$SPEC_FILE':"
        cat "$TEMP_ERR" >&2
        exit 1
      fi
    fi
  fi

  if [ "$YAML_CONVERTED" = false ]; then
    log_error "No YAML parser found to process '$SPEC_FILE'."
    log_error "Please install one of: python3 with PyYAML (pip install pyyaml), ruby, yq, or node with js-yaml."
    exit 1
  fi

  # Surface non-fatal warnings emitted by YAML converter (e.g. missing openapi/swagger field)
  if [ -s "$TEMP_ERR" ]; then
    while IFS= read -r err_line; do
      case "$err_line" in
        WARN:*)
          log_warn "${err_line#WARN: }"
          ;;
      esac
    done < "$TEMP_ERR"
  fi

  if [ ! -s "$TEMP_SPEC" ]; then
    log_error "YAML conversion produced an empty specification."
    exit 1
  fi

  log_info "YAML converted to JSON using ${C_CYAN}${YAML_TOOL_USED}${C_RESET}"
fi

# Escape closing </script> sequences safely in JSON so HTML <script> tags cannot break
if grep -qi "</script" "$TEMP_SPEC"; then
  sed 's/<\//<\\\//g' "$TEMP_SPEC" > "${TEMP_SPEC}.safe" && mv "${TEMP_SPEC}.safe" "$TEMP_SPEC"
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
SPEC_FORMAT_UPPER="$(printf '%s' "$SPEC_FORMAT" | tr '[:lower:]' '[:upper:]')"

echo ""
log_success "${C_BOLD}Bundle built successfully!${C_RESET}"
echo -e "  ${C_GRAY}•${C_RESET} Specification:  ${C_CYAN}$SPEC_FILE${C_RESET} ($SPEC_SIZE, $SPEC_FORMAT_UPPER)"
echo -e "  ${C_GRAY}•${C_RESET} Template:       ${C_CYAN}$TEMPLATE_FILE${C_RESET}"
echo -e "  ${C_GRAY}•${C_RESET} Theme:          ${C_CYAN}$THEME${C_RESET} ($THEME_FILE)"
echo -e "  ${C_GRAY}•${C_RESET} Server URL:     $([ -n "$SERVER_URL" ] && echo -e "${C_CYAN}$SERVER_URL${C_RESET} (overridden)" || echo -e "${C_GRAY}Default from specification${C_RESET}")"
echo -e "  ${C_GRAY}•${C_RESET} Output:         ${C_GREEN}${C_BOLD}$OUTPUT_FILE${C_RESET} ($BUNDLE_SIZE, $TOTAL_LINES lines)"
echo -e "  ${C_GRAY}•${C_RESET} Remote URL:     $([ "$DISABLE_LOAD_URL" = true ] && echo -e "${C_YELLOW}Disabled (omitted)${C_RESET}" || echo -e "${C_GREEN}Enabled${C_RESET}")"
echo -e "  ${C_GRAY}•${C_RESET} File Upload:    $([ "$DISABLE_UPLOAD" = true ] && echo -e "${C_YELLOW}Disabled (omitted)${C_RESET}" || echo -e "${C_GREEN}Enabled${C_RESET}")"
echo -e "  ${C_GRAY}•${C_RESET} Standalone:     ${C_BOLD}Yes (Open directly in any modern web browser)${C_RESET}"
echo ""
