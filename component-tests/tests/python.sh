#!/bin/bash
set -euo pipefail

pip3 --version

python3 -c "
import hashlib, json

payload = json.dumps({'component': 'python', 'value': 6 * 7})
assert json.loads(payload)['value'] == 42

digest = hashlib.sha256(b'test').hexdigest()
assert digest == '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08'
"
