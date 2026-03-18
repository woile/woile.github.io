# woile.dev

> My personal website

## Stack

- `sukr`: content rendering
- `nix`: dev env and build

## Content Guidelines
- **Directory:** All content lives in `content/`.
- **Blog:** Posts are located in `content/blog/`.
- **Frontmatter:** Uses TOML.
- **Date Format:** Dates in TOML frontmatter must be raw datetimes (e.g., `date = 2026-03-10`), **not strings**.

## Commands

### Development

Enter the devenv in your shell, you'll see al the `just` commands available

```sh
nix develop
```

### Building

```sh
nix build .#site
```

Outptuts to `result/`
