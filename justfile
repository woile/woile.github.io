# Update dependencies
update:
    nix flake update
    cargo update

# Build styles and site
build:
    tailwindcss -i input.css -o static/style.css
    sukr

# Serve site
serve:
    miniserve public --index index.html

# Watch styles
twatch:
    tailwindcss -i ./input.css -o static/style.css --watch
