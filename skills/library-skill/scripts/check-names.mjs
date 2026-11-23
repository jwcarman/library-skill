#!/usr/bin/env node
// Every public name of the library appears in backticks in each docs folder you name, so an agent can
// find it by name and a new API cannot ship without the skill mentioning it.
//
// Public names: the top-level public types of the Java sources (class, interface, record, enum,
// annotation) and the names exported by the TypeScript entry points (`export { a, b as c }`).
// A name counts as documented when it appears inside a `backtick span` on one line of a .md file in
// the folder (not README.md).
//
// Usage: node check-names.mjs <config.json>
// Config (paths relative to "root", itself relative to the config file; "*" matches one path segment):
//   {
//     "root": "..",                                  ADAPT: the library's checkout
//     "java": ["src/main/java"],                      ADAPT: source roots ("modules/*/src/main/java")
//     "ts": ["web/lib/src/*/index.ts"],              ADAPT: entry points, or []
//     "exclude": ["MyAutoConfiguration"],             ADAPT: public names users never write
//     "docs": ["skills/mylib/references"]             ADAPT: each folder must mention every name
//   }
// Exits 1 with one line per problem ("missing from <docs>: <name> (<file>)"), else prints
// "ok: N public names documented".
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";

if (process.argv.length !== 3) {
  console.error("usage: node check-names.mjs <config.json>");
  process.exit(2);
}
const configFile = resolve(process.argv[2]);
const config = JSON.parse(readFileSync(configFile, "utf8"));
const root = resolve(dirname(configFile), config.root ?? ".");
const exclude = new Set(config.exclude ?? []);
const problems = [];
const rel = (file) => relative(root, file);

// Paths with "*" segments, expanded against the file system.
function expand(pattern) {
  let paths = [root];
  for (const segment of pattern.split("/")) {
    paths = paths.flatMap((path) => {
      if (segment !== "*") return [join(path, segment)];
      return existsSync(path) && statSync(path).isDirectory() ? readdirSync(path).sort().map((e) => join(path, e)) : [];
    });
  }
  return paths.filter((path) => existsSync(path));
}

function files(dir, suffix) {
  return readdirSync(dir)
    .sort()
    .flatMap((entry) => {
      const path = join(dir, entry);
      if (statSync(path).isDirectory()) return files(path, suffix);
      return path.endsWith(suffix) ? [path] : [];
    });
}

const javaType = /^public\s+(?:(?:final|abstract|sealed|non-sealed|static)\s+)*(?:class|interface|record|enum|@interface)\s+(\w+)/m;

function tsExports(file) {
  const source = readFileSync(file, "utf8").replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, "");
  if (/export\s+\*\s+from/.test(source)) {
    // Following `export *` needs the module graph; asking for explicit names keeps this check honest.
    problems.push(`unresolvable export * in ${rel(file)}: list the names explicitly`);
  }
  const names = [];
  for (const [, body] of source.matchAll(/export\s+(?:type\s+)?\{([^}]*)\}/g)) {
    for (const item of body.split(",")) {
      const entry = item.trim().replace(/^type\s+/, "");
      if (entry) names.push(entry.split(/\s+as\s+/).pop().trim());
    }
  }
  for (const [, name] of source.matchAll(/export\s+(?:declare\s+)?(?:async\s+)?(?:function\*?|const|let|class|interface|type|enum)\s+([A-Za-z_$][\w$]*)/g)) {
    names.push(name);
  }
  return names;
}

const publicNames = []; // { name, file }
for (const pattern of config.java ?? []) {
  const roots = expand(pattern);
  if (roots.length === 0) problems.push(`no Java sources at ${pattern}`);
  for (const dir of roots) {
    for (const file of files(dir, ".java")) {
      const match = javaType.exec(readFileSync(file, "utf8"));
      if (match && !exclude.has(match[1])) publicNames.push({ name: match[1], file });
    }
  }
}
for (const pattern of config.ts ?? []) {
  const entries = expand(pattern);
  if (entries.length === 0) problems.push(`no TypeScript entry points at ${pattern}`);
  for (const file of entries) {
    for (const name of tsExports(file)) if (!exclude.has(name)) publicNames.push({ name, file });
  }
}

function backtickNames(dir) {
  const names = new Set();
  if (!existsSync(dir)) return names;
  for (const file of files(dir, ".md")) {
    if (file.endsWith("README.md")) continue;
    for (const [, span] of readFileSync(file, "utf8").matchAll(/`([^`\n]+)`/g)) {
      for (const [identifier] of span.matchAll(/[A-Za-z_$][\w$]*/g)) names.add(identifier);
    }
  }
  return names;
}

for (const docs of config.docs ?? []) {
  const documented = backtickNames(join(root, docs));
  const reported = new Set();
  for (const { name, file } of publicNames) {
    if (documented.has(name) || reported.has(name)) continue;
    reported.add(name);
    problems.push(`missing from ${docs}: ${name} (${rel(file)})`);
  }
}

if (problems.length > 0) {
  for (const line of problems) console.log(line);
  process.exit(1);
}
console.log(`ok: ${new Set(publicNames.map(({ name }) => name)).size} public names documented`);
