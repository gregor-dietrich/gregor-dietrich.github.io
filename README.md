# gregor-dietrich.github.io

Personal blog built with [Hugo](https://gohugo.io/) and the
[PaperMod](https://github.com/adityatelange/hugo-PaperMod) theme, deployed to
GitHub Pages at <https://gregor-dietrich.github.io/>.

## Setup

Install Hugo (extended edition) and git.

**macOS:**

```sh
brew install hugo git
```

**Debian / Ubuntu:** Debian's own `hugo` package usually lags behind, so install
the official `.deb` at the same version CI uses (`HUGO_VERSION` in
`.github/workflows/hugo.yml`):

```sh
HUGO_VERSION=0.167.0
ARCH=$(dpkg --print-architecture)   # amd64 or arm64
wget -O /tmp/hugo.deb "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${ARCH}.deb"
sudo apt install /tmp/hugo.deb git
```

Then clone, including the theme:

```sh
git clone --recurse-submodules git@github.com:gregor-dietrich/gregor-dietrich.github.io.git
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

Every push to `main` builds and deploys the site through
`.github/workflows/hugo.yml` (about a minute). Check progress with
`gh run watch` or in the repo's Actions tab.

## Maintenance

- Site config (title, menu, social links): `hugo.yaml`
- Update the theme: `git submodule update --remote themes/PaperMod`, then commit
- Update Hugo in CI: bump `HUGO_VERSION` in `.github/workflows/hugo.yml` to match `hugo version` locally

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

3. Add the deploy workflow: copy `.github/workflows/hugo.yml` from this repo
   (it's based on GitHub's Hugo starter workflow, which is also offered under
   Settings → Pages once Actions is the source).

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
