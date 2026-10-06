# gregor-dietrich.github.io

Personal blog built with [Hugo](https://gohugo.io/) and the
[PaperMod](https://github.com/adityatelange/hugo-PaperMod) theme, deployed to
GitHub Pages at <https://gregor-dietrich.github.io/>.

## Setup

Install Hugo (extended edition), git, and the linters the
[quality checks](#quality-checks) run.

**macOS:**

```sh
brew install hugo git shellcheck markdownlint-cli2 typos-cli vale actionlint lychee
```

**Debian / Ubuntu:** Debian's own `hugo` package usually lags behind, so install
the official `.deb` at the same version CI uses (`HUGO_VERSION` in
`.github/actions/setup-tools/action.yml`):

```sh
HUGO_VERSION=0.167.0
ARCH=$(dpkg --print-architecture)   # amd64 or arm64
wget -O /tmp/hugo.deb "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${ARCH}.deb"
sudo apt install /tmp/hugo.deb git shellcheck curl npm
```

The other linters aren't packaged (or are outdated) on Debian; after cloning
(below), install them into `~/.local/bin` at the versions CI uses:

```sh
scripts/install-linters.sh   # make sure ~/.local/bin is on your PATH
```

Then clone, including the theme, and run the one-time setup, which installs the
pre-commit hook and downloads Vale's style packages:

```sh
git clone --recurse-submodules git@github.com:gregor-dietrich/gregor-dietrich.github.io.git
cd gregor-dietrich.github.io
scripts/setup.sh
```

The theme is a git submodule in `themes/PaperMod`. If you cloned without
`--recurse-submodules`, run `git submodule update --init`.

## Writing a post

```sh
hugo new content posts/my-essay.md   # creates a draft from archetypes/default.md
hugo server -D                       # preview at http://localhost:1313, drafts included
```

Posts are plain Markdown in `content/posts/` with front matter:

```yaml
---
title: My Essay
date: 2026-10-06
draft: true
tags: [meta]
summary: One-line summary shown in the post list.
---
```

## Publishing

Set `draft: false`, then commit and push:

```sh
git add -A && git commit -m "Add my essay" && git push
```

Every push to `main` runs the [quality checks](#quality-checks), then builds
and deploys the site through `.github/workflows/hugo.yml` (about two minutes).
If a check fails, nothing deploys. Check progress with `gh run watch` or in the
repo's Actions tab. Pushes that only change this README skip the workflow.

Pull requests are optional: they run the checks without deploying, so they're
handy for a long essay that needs several sessions.

## Quality checks

`scripts/lint.sh` runs every check and reports all failures at once:

| Check | What it catches | Config |
| --- | --- | --- |
| markdownlint-cli2 | Markdown structure | `.markdownlint-cli2.yaml` |
| typos | Spelling mistakes | `_typos.toml` |
| Vale | Prose style (proselint, write-good); only errors fail, warnings are advice | `.vale.ini`, accepted words in `.vale/styles/config/vocabularies/Blog/accept.txt` |
| actionlint | Mistakes in the GitHub Actions workflows | |
| shellcheck | Mistakes in `scripts/` | |
| `scripts/check-site.sh` | Hugo build errors and warnings, broken internal links (lychee) | |

It runs in three places:

- **Before every commit**, via the pre-commit hook `scripts/setup.sh` installs
  (quiet unless something fails; skip once with `git commit --no-verify`).
  Run `scripts/lint.sh` yourself to see Vale's warnings too.
- **In CI**, on every push and pull request; deploys wait for it.
- **Weekly**, `.github/workflows/links.yml` checks external links and opens or
  updates a "Broken external links" issue when some are dead, so another
  site's outage never blocks publishing.

## Maintenance

- Site config (title, menu, social links): `hugo.yaml`
- Update the theme: `git submodule update --remote themes/PaperMod`, then commit
- Update Hugo in CI: bump `HUGO_VERSION` in `.github/actions/setup-tools/action.yml` to match `hugo version` locally
- Update the linters in CI: bump the versions at the top of `scripts/install-linters.sh`
- After changing `scripts/hooks/pre-commit.sh`, rerun `scripts/setup.sh` (the hook is installed as a copy)
- `scripts/check-site.sh` tolerates two PaperMod deprecation warnings
  ([hugo-PaperMod#1856](https://github.com/adityatelange/hugo-PaperMod/issues/1856));
  remove `KNOWN_WARNINGS` there once a theme update fixes them
- The favicons in `static/` are 👨🏻‍💻 (man technologist: light skin tone) from
  [Noto Emoji](https://github.com/googlefonts/noto-emoji)'s 2D set, licensed
  under Apache 2.0 (`licenses/noto-emoji.txt`). To change them, replace the
  files and keep the names; PaperMod links all five.

## Setting it up from scratch

How this repo was created, for rebuilding it or making a similar site. Replace
`<user>` with your GitHub username. The `gh` steps need the
[GitHub CLI](https://cli.github.com/) (`brew install gh`, or `sudo apt install gh`
on Debian), logged in with `gh auth login`. Each one also has a web UI
equivalent.

1. Create the site and add the theme:

   ```sh
   hugo new site <user>.github.io --format yaml
   cd <user>.github.io
   git init -b main
   git submodule add --depth=1 https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
   ```

2. Configure it: set `theme: PaperMod` (plus title, menu, etc.) in `hugo.yaml`,
   and add a `.gitignore` for `/public/`, `/resources/_gen/` and
   `/.hugo_build.lock`.

3. Add the deploy workflow: copy `.github/workflows/hugo.yml` and
   `.github/actions/setup-tools/` from this repo (based on GitHub's Hugo
   starter workflow, which is also offered under Settings → Pages once Actions
   is the source). For the quality checks, also copy `scripts/`,
   `.github/workflows/links.yml` and the linter configs (`.markdownlint-cli2.yaml`,
   `_typos.toml`, `.vale.ini`, `.vale/styles/config/`), then run
   `scripts/setup.sh`.

4. Create the GitHub repo. Naming it `<user>.github.io` serves the site at
   `https://<user>.github.io/`; any other name serves it at
   `https://<user>.github.io/<repo>/`.

   ```sh
   gh repo create <user>.github.io --public --source . --remote origin
   ```

   (Web UI: New repository, then `git remote add origin …`.)

5. Make Pages deploy from GitHub Actions instead of a branch:

   ```sh
   gh api -X POST repos/<user>/<user>.github.io/pages -f build_type=workflow
   ```

   (Web UI: repo Settings → Pages → Source: "GitHub Actions".)

6. Commit, push and watch the first deploy:

   ```sh
   git add -A && git commit -m "Set up Hugo blog"
   git push -u origin main
   gh run watch
   ```

Pages on a free account requires a public repo.
