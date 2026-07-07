#!/usr/bin/env bash
# Inject ~/.agents/AGENTS.md into every Cursor Agent session (sessionStart hook).
# Cursor docs: https://cursor.com/docs/hooks#sessionstart

set -euo pipefail

# Hook input (session metadata); required by the protocol even if unused.
cat > /dev/null

agents_md="${HOME}/.agents/AGENTS.md"
if [[ ! -f "${agents_md}" ]]; then
    printf '{}\n'
    exit 0
fi

exec python3 - "${agents_md}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
content = path.read_text(encoding="utf-8")
payload = {
    "additional_context": (
        "# User-level AGENTS.md (from ~/.agents/AGENTS.md)\n\n" + content
    )
}
sys.stdout.write(json.dumps(payload, ensure_ascii=False))
PY
