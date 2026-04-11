# Update dependencies
update:
    nix flake update

# Build styles and site
build:
    tailwindcss -i ./styles/input.css -o static/style.css --minify
    sukr

# Serve site
serve:
    miniserve --index index.html -q public

# Watch styles
twatch:
    tailwindcss -i ./styles/input.css -o static/style.css --watch

# Watch (except gitignore) and rebuild
watch:
    watchexec just build

date := `date +%Y-%m-%d`
blog_template := f'''
+++
title = "POST_TITLE"
description = "POST_DESCRIPTION"
date = {{date}}
tags = []
+++
'''

# create a new blog post
new_post title='' description='':
    #!/usr/bin/env bash
    SLUG=$(echo "{{ title }}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\{2,\}/-/g' | sed 's/^-//;s/-$//')
    echo '{{ replace(replace(blog_template, "POST_TITLE", title), "POST_DESCRIPTION", description) }}' > "content/blog/${SLUG}.md"
