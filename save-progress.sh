#!/bin/bash

# Exit on any error
set -e

# Ensure Git is initialized
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "❌ Error: This is not a Git repository. Initialize Git first."
    exit 1
fi

# Get current timestamp
TIMESTAMP=$(date "+%d-%m-%Y-%H%M")

# Extract the latest entries from README.md using macOS compatible grep
LATEST_FEATURE=$(grep -m1 "^- .* Improved" README.md | sed 's/^- //' | sed 's/[[:space:]]*[[:punct:]]*[[:space:]]*//' || echo "code-cleanup-and-organization")
LATEST_BUGFIX=$(grep -m1 "^- .* Removed" README.md | sed 's/^- //' | sed 's/[[:space:]]*[[:punct:]]*[[:space:]]*//' || echo "General bug fixes and stability improvements")
LATEST_OPTIMIZATION=$(grep -m1 "^- .* Reorganized" README.md | sed 's/^- //' | sed 's/[[:space:]]*[[:punct:]]*[[:space:]]*//' || echo "Performance and structure improvements")
LATEST_UIUX=$(grep -m1 "^- .* Unified" README.md | sed 's/^- //' | sed 's/[[:space:]]*[[:punct:]]*[[:space:]]*//' || echo "User experience and interface improvements")

# Create a descriptive feature name from the changes
if [[ "$LATEST_FEATURE" == *"camera"* ]]; then
    FEATURE_DESCRIPTION="camera-improvements"
elif [[ "$LATEST_OPTIMIZATION" == *"structure"* ]]; then
    FEATURE_DESCRIPTION="file-restructure"
elif [[ "$LATEST_BUGFIX" == *"redundant"* ]]; then
    FEATURE_DESCRIPTION="remove-redundant-components"
else
    FEATURE_DESCRIPTION="code-cleanup-and-organization"
fi

# Create branch name using feature and timestamp
BRANCH_NAME="${FEATURE_DESCRIPTION}-${TIMESTAMP}"

echo "🔍 Detected latest updates:"
echo "📌 New Feature: $LATEST_FEATURE"
echo "🐞 Bug Fix: $LATEST_BUGFIX"
echo "⚡ Optimization: $LATEST_OPTIMIZATION"
echo "🎨 UI/UX Update: $LATEST_UIUX"
echo "🚀 Creating branch: $BRANCH_NAME"

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "🔍 Uncommitted changes detected. Proceeding with commit..."
else
    echo "✅ No changes detected. Exiting..."
    exit 0
fi

# Create and switch to new branch
git checkout -b "$BRANCH_NAME"

# Stage all files
git add .

# Skip Configuration.swift only if it exists
if [ -f "Resources/Configuration/Configuration.swift" ]; then
    git reset Resources/Configuration/Configuration.swift
fi

# Backup old README and prepare new content
README_TEMP="README.md.tmp"

# Preserve existing README content
cp README.md "$README_TEMP"

# Append new changes at the top while keeping the previous content intact
cat > README.md <<EOL
# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes ($TIMESTAMP)

### New Features
- 🌐 $LATEST_FEATURE

### Bug Fixes
- 🛠️ $LATEST_BUGFIX

### Code Optimizations
- ⚡️ $LATEST_OPTIMIZATION

### UI/UX Changes
- 🎨 $LATEST_UIUX

$(cat "$README_TEMP")  # Append previous README content
EOL

# Remove temp file
rm "$README_TEMP"

# Commit changes
echo "📌 Committing changes..."
git add README.md
git commit -m "Update project with latest changes ($TIMESTAMP)"

# Push new branch
echo "🚀 Pushing branch to GitHub..."
git push -u origin "$BRANCH_NAME"

# Switch to main, pull latest changes, merge new branch
echo "🔄 Switching to main and merging changes..."
git checkout main
git pull origin main  # Ensure main is up-to-date
git merge "$BRANCH_NAME" --no-ff -m "Merge $BRANCH_NAME into main"

# Push merged changes to GitHub
git push origin main

# Return to the new branch
git checkout "$BRANCH_NAME"

echo "✅ Progress saved successfully!"
echo "🔄 New branch created: $BRANCH_NAME"
echo "📝 README updated with timestamp: $TIMESTAMP"
echo "🚀 Changes pushed and merged into main"
