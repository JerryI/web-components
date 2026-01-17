#!/bin/bash

# Script to remove all files from src/ directory except:
# - *.js, *.mjs, *.cjs (JavaScript files)
# - *.json
# - *.css
# - *.tiff, *.tif (TIFF images)
# - Font formats: *.ttf, *.otf, *.woff, *.woff2, *.eot

SRC_DIR="/Users/kirill/Github/web-components/src"

# Find and delete files that don't match the allowed extensions
find "$SRC_DIR" -type f \
  ! -name "*.js" \
  ! -name "*.mjs" \
  ! -name "*.cjs" \
  ! -name "*.json" \
  ! -name "*.css" \
  ! -name "*.tiff" \
  ! -name "*.tif" \
  ! -name "*.ttf" \
  ! -name "*.otf" \
  ! -name "*.woff" \
  ! -name "*.woff2" \
  ! -name "*.eot" \
  -print -delete

# Remove empty directories afterwards
find "$SRC_DIR" -type d -empty -delete

echo "Cleanup complete!"
