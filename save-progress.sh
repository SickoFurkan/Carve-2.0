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

# Extract the latest feature from README.md
LATEST_FEATURE=$(grep -m1 -oP '(?<=### New Features\n- ).*' README.md || echo "update")

# Sanitize feature name (convert to lowercase, replace spaces with hyphens, remove special chars)
CLEAN_FEATURE=$(echo "$LATEST_FEATURE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

# Default to "update" if no feature is found
if [[ -z "$CLEAN_FEATURE" ]]; then
    CLEAN_FEATURE="update"
fi

# Create branch name using feature and timestamp
BRANCH_NAME="${CLEAN_FEATURE}-${TIMESTAMP}"

echo "🔍 Detected latest feature: $LATEST_FEATURE"
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

# Stage all files except Configuration.swift
git add .
git reset Configuration.swift

# Update README with latest changes
README_TEMP="README.md.tmp"
cat > "$README_TEMP" << EOL
# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes ($TIMESTAMP)

### New Features
- 🌐 $LATEST_FEATURE
- 📱 UI enhancements
- 🔄 Functionality improvements
- 📊 Performance optimizations

### Bug Fixes
- 🛠️ Recent bug fixes
- 🔧 Stability improvements
- ⚡️ Enhanced error handling

### Code Optimizations
- 📌 Code structure improvements
- ⚡️ Performance enhancements
- 🎯 Improved code handling

### UI/UX Changes
- 🎨 Interface updates
- 🖌️ Design improvements
- ✨ Better user experience

### Dependencies
- 📦 Package updates
- 🔗 Integration improvements
- ⚙️ System enhancements

EOL

# Append old README content after new section
tail -n +2 README.md >> "$README_TEMP"
mv "$README_TEMP" README.md

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
