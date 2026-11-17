# Develpment Resources

Reusable files that get copied into projects, never consumed in place.
Resources is the source; a project is the destination. Nothing here is
referenced by any running system.

## Layout

```text
resources/
├── licenses/     full license texts, ready to be copied as LICENSE
├── templates/    document skeletons: PR, issue, bug, feature, ADR, postmortem, project README
├── config/       shared configuration files: .editorconfig, gitignore/<stack>
└── README.md
```

No subfolders by project, language or date.

## Licenses

Name pattern: `license.<SPDX>.template`, where `<SPDX>` is the lowercase
SPDX identifier from https://spdx.org/licenses (`license.mit.template` is
the MIT license). Texts are the canonical SPDX texts, verbatim, with
their official placeholders. The placeholders differ per license and are
replaced when the license is copied into a project.

| File                             | License                       | Placeholders                           |
| -------------------------------- | ----------------------------- | -------------------------------------- |
| `license.mit.template`           | MIT                           | `<year>` `<copyright holders>`         |
| `license.apache-2.0.template`    | Apache 2.0                    | `[yyyy]` `[name of copyright owner]`   |
| `license.agpl-3.0-only.template` | GNU AGPL 3.0 only             | `<year>` `<name of author>` (appendix) |
| `license.gpl-3.0-only.template`  | GNU GPL 3.0 only              | `<year>` `<name of author>` (appendix) |
| `license.lgpl-3.0-only.template` | GNU LGPL 3.0 only             | `<year>` `<name of author>` (appendix) |
| `license.mpl-2.0.template`       | Mozilla Public License 2.0    | none                                   |
| `license.bsd-2-clause.template`  | BSD 2-Clause                  | `<year>` `<owner>`                     |
| `license.bsd-3-clause.template`  | BSD 3-Clause                  | `<year>` `<owner>`                     |
| `license.isc.template`           | ISC                           | `<year>` `<owner>`                     |
| `license.unlicense.template`     | The Unlicense (public domain) | none                                   |

The GPL family and Apache 2.0 are applied by a notice in the appendix of
the text; the full text is still what goes in `LICENSE`. Pick the
`-only` variants deliberately: `-or-later` is a different identifier and
a different grant.

To add a license, fetch the canonical text from spdx.org (or the
`text/` folder of github.com/spdx/license-list-data) and keep it
verbatim. Do not reformat, do not translate. Add a row to the table.

## Templates

Plain Markdown, section-based. HTML comments guide the author and are
hidden on render: they state what a section must contain and when it is
acceptable to leave it empty. Placeholders use the `{{name}}` form
(`{{title}}`, `{{number}}`, `{{date:YYYY-MM-DD}}`) and are filled by a
human, not by tooling.

Current set:

- `pr.md` — pull request description.
- `issue.md` — work that is neither a defect nor a feature: refactor,
  tech debt, migration, upgrade, chore, investigation.
- `bug.md` — bug report, reproducible from the written steps alone.
- `feature.md` — feature request, problem before solution.
- `adr.md` — architecture decision record, immutable once accepted.
- `postmortem.md` — blameless incident postmortem with action items.
- `README.md` — project README skeleton.

A template is the shortest document that fully covers its purpose. Copy
the file, delete sections that do not apply, keep the reasoning sections
even when the change feels small.

## Using a resource

Copy, then edit the copy. Never edit a resource to fit one project.

```bash
# license: copy as LICENSE, then replace the placeholders
cp ~/dev/resources/licenses/license.apache-2.0.template ./LICENSE

# templates: copy under the name the destination expects
cp ~/dev/resources/templates/adr.md ./docs/adr/0007-use-event-sourcing.md
cp ~/dev/resources/templates/pr.md  ./.github/pull_request_template.md
cp ~/dev/resources/templates/README.md ./README.md
```

## Config

One file per purpose. Gitignore variants are named by stack and prefixed
with the target file (`gitignore/java.gitignore`), because the name of
the file inside the project is always `.gitignore`. Config files are
starting points: copy them into the project and adjust there, never the
other way around.

- `.editorconfig` — UTF-8, LF, final newline, trimmed whitespace; 4
  spaces by default, 2 for web and data formats, tabs for Makefile and
  Go, CRLF for `.bat`. Lockfiles and the Gradle wrapper are left alone.
- `gitignore/java.gitignore` — Maven, Gradle and Spring Boot; IDE and OS
  files; secrets. Build wrappers stay tracked.
- `gitignore/python.gitignore` — bytecode, virtual environments, build
  and test output, tooling caches; IDE and OS files; secrets.

```bash
cp ~/dev/resources/config/.editorconfig ./.editorconfig
cp ~/dev/resources/config/gitignore/java.gitignore ./.gitignore
```

Stacks combine: a project with two stacks gets one `.gitignore` built
from both files, with duplicates removed. Add a stack by adding
`gitignore/<stack>.gitignore`; keep `.env.example` tracked and every
secret pattern in.

## Creating and verifying this workspace

The layout above, and the files in it, are created by `bootstrap.sh` from
the `dev-bootstrap` repository (it lives outside `~/dev`). Run it from
that repository:

```bash
./bootstrap.sh apply --dry-run   # preview what would be created
./bootstrap.sh apply             # create missing dirs, seed missing files
./bootstrap.sh check             # verify the layout; exit 1 if anything is missing
./bootstrap.sh sync              # copy live READMEs from ~/dev back into skeleton/
```

- The target is `~/dev`. Override it with `DEV_ROOT=/path ./bootstrap.sh apply`.
- `apply` never overwrites and never deletes. A file that already exists
  in `~/dev` is left alone, even if `skeleton/` has a newer version.
- To ship a new license, template or config file, put it in
  `skeleton/resources/` at its final path, then run `apply`.
- After the first apply, the files in `~/dev` are the working copies.
  When you edit one there, run `sync` and commit, so `dev-bootstrap`
  stays a valid fresh-machine fallback. `check` reports `changed` for
  files where the live copy and the skeleton differ.
- Direction matters: `sync` copies live over skeleton. If you edited
  `skeleton/` directly and the live file exists, copy your change to
  `~/dev` first, or `sync` will overwrite it.

This README is the source of truth. If a rule changes, change it here
first, then in the files.
