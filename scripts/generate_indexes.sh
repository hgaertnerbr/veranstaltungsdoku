#!/usr/bin/env bash
set -euo pipefail

# Repo-Root relativ zu diesem Skript ermitteln (funktioniert auch mit Leerzeichen im Pfad)
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

generate_index () {
  local dir="$1"    # z. B. summaries
  local ext="$2"    # md|txt
  local header="$3" # z. B. Summaries

  local out="$repo_root/$dir/index.md"
  mkdir -p "$repo_root/$dir"

  {
    echo "# $header"
    echo
    local count=0

    # Dateien alphabetisch, null-separiert (robust bei Leerzeichen)
    while IFS= read -r -d '' file; do
      local rel="${file#$repo_root/$dir/}"   # relativer Pfad unterhalb des Ordners
      local name_noext="${rel%.*}"

      if [[ "$ext" == "md" ]]; then
        # Erste Markdown-Überschrift als Linktext (falls vorhanden)
        local title
        title="$(grep -m1 '^#' "$file" | sed 's/^#\+ *//' || true)"
        [[ -z "${title:-}" ]] && title="$name_noext"
        echo "- [$title](./$rel)"
      else
        echo "- [$name_noext](./$rel)"
      fi
      count=$((count+1))
    done < <(find "$repo_root/$dir" -maxdepth 1 -type f -name "*.$ext" -print0 | sort -z)

    echo
    echo "_$count Dateien_"
  } > "$out"
}

generate_index "summaries"  "md"  "Summaries"
generate_index "transcripts" "txt" "Transcripts"

echo "Fertig: summaries/index.md und transcripts/index.md aktualisiert."
