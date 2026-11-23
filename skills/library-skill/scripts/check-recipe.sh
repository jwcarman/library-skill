#!/usr/bin/env bash
# Builds a skill's recipe into a copy of a fixture app and runs the fixture's build there, so every
# code block an agent copies is proven to compile and pass the project's tests and gates. Run it in
# the library's CI.
#
# The recipe marks each block it means literally with an HTML comment on the line before it:
#   <!-- file: <path> -->      the block is that whole file, relative to the app's root;
#   <!-- files: <dir>/ -->     a Java block of several top-level public types: its package and
#                              imports, then one file per type, named for it;
#   <!-- fragment: <name> -->  a piece of an existing file; the fragments program puts it in place:
#                              `<fragments> <name> <block file> <app dir>` (exit 3: unknown name).
# After every block, `<fragments> --finish <app dir>` makes any edit the recipe gives only in words.
#
# Usage: check-recipe.sh <recipe.md> <fixture dir> <fragments program> -- <build command>
#   The build command runs in the copy, through bash -c. ADAPT: the copy goes to a fresh temp dir
#   unless RECIPE_APP_DIR names one (a fixture with relative links must sit where they resolve).
set -euo pipefail

if [ "$#" -lt 5 ] || [ "$4" != "--" ]; then
  echo "usage: $(basename "$0") <recipe.md> <fixture dir> <fragments program> -- <build command>" >&2
  exit 2
fi
recipe="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
fixture="$(cd "$2" && pwd)"
fragments="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"
shift 4
build="$*"
app="${RECIPE_APP_DIR:-$(mktemp -d)/app}"

rm -rf "$app"
mkdir -p "$app"
(cd "$fixture" && tar --exclude=./target --exclude=./build --exclude=./node_modules \
  --exclude=./frontend/node_modules --exclude=./frontend/dist -cf - .) | (cd "$app" && tar -xf -)

python3 - "$recipe" "$app" "$fragments" <<'PY'
import re, subprocess, sys, tempfile
from pathlib import Path

recipe, app, fragments = Path(sys.argv[1]).read_text(), Path(sys.argv[2]), sys.argv[3]
blocks = re.findall(r"<!-- (file|files|fragment): (\S+) -->\n( *)```\w*\n(.*?)\n\3```", recipe, re.S)
if not blocks:
    sys.exit("check-recipe: no marked blocks in the recipe")

def dedent(indent, body):
    return "\n".join(line[len(indent):] if line.startswith(indent) else line for line in body.split("\n")) + "\n"

def run_fragments(*args):
    return subprocess.run([sys.executable, fragments, *args]).returncode

for kind, target, indent, body in blocks:
    body = dedent(indent, body)
    if kind == "file":
        path = app / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body)
    elif kind == "files":
        head, *types = re.split(r"(?m)^(?=public (?:final |abstract |sealed )*(?:interface|record|class|enum|@interface) )", body)
        if not types:
            sys.exit(f"check-recipe: files: {target} holds no public type")
        for code in types:
            name = re.match(r"public (?:\w+ )*?(?:interface|record|class|enum|@interface) (\w+)", code).group(1)
            path = app / target / f"{name}.java"
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(head + code.rstrip() + "\n")
    else:
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as block:
            block.write(body)
        code = run_fragments(target, block.name, str(app))
        if code == 3:
            sys.exit(f"check-recipe: unknown fragment: {target} (add it to {Path(fragments).name})")
        if code != 0:
            sys.exit(f"check-recipe: fragment {target} failed")

if run_fragments("--finish", str(app)) != 0:
    sys.exit("check-recipe: the fragments program's --finish failed")
print(f"check-recipe: wrote {len(blocks)} blocks", file=sys.stderr)
PY

echo "check-recipe: building $app" >&2
(cd "$app" && bash -c "$build")
echo "check-recipe: ok, the recipe's code builds and passes the fixture's checks" >&2
