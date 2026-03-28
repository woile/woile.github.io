# Update dependencies
update:
    nix flake update

# Build styles and site
build:
    tailwindcss -i ./styles/input.css -o static/style.css --minify
    sukr

# Serve site
serve:
    miniserve public --index index.html

# Watch styles
twatch:
    tailwindcss -i ./styles/input.css -o static/style.css --watch

# Watch (except gitignore) and rebuild
watch:
    watchexec just build
