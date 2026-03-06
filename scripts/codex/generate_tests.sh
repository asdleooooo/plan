#!/usr/bin/env bash
set -euo pipefail

mkdir -p tests
cat > tests/generated_smoke_test.md <<'EOF'
# Generated test placeholder

- Unit tests: TODO
- Integration tests: TODO
- E2E smoke tests: TODO
EOF

echo "Generated tests/generated_smoke_test.md"
