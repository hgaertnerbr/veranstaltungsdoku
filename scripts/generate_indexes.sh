#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

is_generic_title () {
  local t
  # klein + trim + umlaute belassen
  t="$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  case "$t" in
    "zusammenfassung"|"kurzfassung"|"summary"|"abstract"|"summaries"|"zusammenfassung des vortrags"|"kurzfassung des vortrags")
      return 0 ;;
  esac
  # sehr kurz → generisch
  [ ${#t} -lt 8 ] && return 0
  return 1
}

prettify_name () {
  # Bindestriche/Unterstriche → Leerzeichen; doppelte Leerzeichen entfernen
  echo "$1" | sed 's/[-_]/ /g; s/  \+/ /g'
}

first_markdown_heading () {
  # 1) BOM entfernen, 2) erste MD-Heading-Zeile (#..######) extrahieren, 3) # + Spaces strippen
  local file="$1"
  awk '
    NR==1 { sub(/^\xef\xbb\xbf/,"") }           # BOM weg
    /^[[:space:]]*#{1,6}[[:space:]]+/ {
      gsub(/^[[:space:]]*#+[[:space:]]+/,"",$0) # führende ### + Spaces
      print; exit
    }
  ' "$file" 2>/dev/null || true
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

    # alphabetisch, robust gegen Leerzeichen
    while IFS= read -r -d '' file; do
      local rel="${file#$repo_root/$dir/}"
      local base="$(basename "$rel")"
      local name_noext="${base%.*}"

      local link_text=""
      if [[ "$ext" == "md" ]]; then
        local h="$(first_markdown_heading "$file")"
        if is_generic_title "${h:-}"; then
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
