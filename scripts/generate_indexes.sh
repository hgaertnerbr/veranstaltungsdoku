#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

is_generic_title () {
  # alles kleinschreiben und prüfen
  local t="$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/^ *//; s/ *$//')"
  case "$t" in
    "zusammenfassung"|"kurzfassung"|"summaries"|"zusammenfassung des vortrags"|"kurzfassung des vortrags"|"summary"|"abstract")
      return 0 ;;
  esac
  # sehr kurze Titel ebenfalls als generisch werten
  [ ${#t} -lt 8 ] && return 0
  return 1
}

prettify_name () {
  # Bindestriche -> Leerzeichen; doppelte Leerzeichen entfernen
  echo "$1" | sed 's/-/ /g; s/  \+/ /g'
}

first_markdown_heading () {
  # erste Markdown-Überschrift extrahieren (egal ob #, ##, ###)
  local file="$1"
  grep -m1 -E '^[[:space:]]*#{1,6}[[:space:]]+' "$file" 2>/dev/null | sed 's/^[[:space:]]*#\{1,6\}[[:space:]]\+//' || true
}

generate_index () {
  local dir="$1"    # summaries | transcripts
  local ext="$2"    # md | txt
  local header="$3" # Überschrift der Index-Seite

  local out="$repo_root/$dir/index.md"
  mkdir -p "$repo_root/$dir"

  {
    echo "# $header"
    echo

    local count=0
    while IFS= read -r -d '' file; do
      local rel="${file#$repo_root/$dir/}"
      local base="$(basename "$rel")"
      local name_noext="${base%.*}"

      local link_text=""
      if [[ "$ext" == "md" ]]; then
        local h="$(first_markdown_heading "$file")"
        if is_generic_title "$h"; then
          link_text="$(prettify_name "$name_noext")"
        else
          link_text="$h"
        fi
      else
        link_text="$(prettify_name "$name_noext")"
      fi

      echo "- [$link_text](./$base)"
      count=$((count+1))
    done < <(find "$repo_root/$dir" -maxdepth 1 -type f -name "*.$ext" -print0 | sort -z)

    echo
    echo "_$count Dateien_"
  } > "$out"
}

generate_index "summaries"  "md"  "Summaries"
generate_index "transcripts" "txt" "Transcripts"

echo "Fertig: summaries/index.md und transcripts/index.md aktualisiert."
