#!/usr/bin/env python3
"""Puts a recipe's fragments in place for check-recipe.sh. This one is roux's: copy it and ADAPT
every function to your library's fixture (each is one recipe fragment and where it goes).

    fragments.py <name> <block file> <app dir>   put one fragment in place; exit 3 for an unknown name
    fragments.py --finish <app dir>              the edits the recipe gives only in words

A fragment is a piece of an existing file: a changeset inside a changelog, an entry in a registry,
an import and an item in a list. Put it where an agent would, so the build proves the recipe's words
about where it goes, not just its code.
"""
import sys
from pathlib import Path


def insert_before(path, anchor, text):
    source = path.read_text()
    at = source.rindex(anchor)
    path.write_text(source[:at] + text + source[at:])


def insert_after(path, anchor, text):
    source = path.read_text()
    at = source.index(anchor) + len(anchor)
    path.write_text(source[:at] + text + source[at:])


def changelog(body, app):
    """A new Liquibase changelog: the recipe shows its changeSet; the header is the roles file's."""
    changelogs = app / "src/main/resources/db/changelog"
    roles = (changelogs / "roles.xml").read_text()
    header = roles[: roles.index(">", roles.index("<databaseChangeLog")) + 1]
    (changelogs / "ranks.xml").write_text(header + "\n" + body + "</databaseChangeLog>\n")
    insert_before(changelogs / "db.changelog-master.xml", "</databaseChangeLog>",
                  '  <include file="classpath:db/changelog/ranks.xml"/>\n')


def roles(body, app):
    """A changeset appended to roles.xml, inside its root (the recipe shows the closing tag)."""
    changeset = "\n".join(line for line in body.split("\n")
                          if "</databaseChangeLog>" not in line and not line.strip().startswith("<!--"))
    insert_before(app / "src/main/resources/db/changelog/roles.xml", "</databaseChangeLog>",
                  changeset.strip("\n") + "\n")


def query_keys(body, app):
    insert_after(app / "frontend/src/queryKeys.ts", "export const queryKeys = {\n", body)


def nav(body, app):
    """An import and an entry: the import goes first in the file, the entry last in the list."""
    imports, entry = [part for part in body.split("\n\n") if part.strip()]
    path = app / "frontend/src/shell/nav.ts"
    path.write_text(imports.split("//")[0].rstrip() + "\n" + path.read_text())
    insert_before(path, "]);", "  " + entry.strip() + "\n")


FRAGMENTS = {"changelog": changelog, "roles": roles, "query-keys": query_keys, "nav": nav}


def finish(app):
    """The recipe says in words: list the new Permissions class in PermissionClasses.ALL."""
    insert_after(app / "src/test/java/app/identity/PermissionClasses.java",
                 "static final Class<?>[] ALL = {\n", "    Permissions.class,\n")


if __name__ == "__main__":
    if sys.argv[1] == "--finish":
        finish(Path(sys.argv[2]))
        sys.exit(0)
    name, block, app = sys.argv[1], Path(sys.argv[2]).read_text(), Path(sys.argv[3])
    if name not in FRAGMENTS:
        sys.exit(3)
    FRAGMENTS[name](block, app)
