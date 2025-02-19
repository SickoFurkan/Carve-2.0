#!/bin/bash

# Get current timestamp
TIMESTAMP=$(date "+%d-%m-%Y-%H%M")

# Create new branch name
BRANCH_NAME="new-feature-$TIMESTAMP"

# Create and checkout new branch
git checkout -b $BRANCH_NAME

# Stage all files
git add .

# Unstage Configuration.swift
git reset Configuration.swift

# Update README with latest changes
cat > README.md.tmp << EOL
# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes ($TIMESTAMP)

### New Features
- 🌐 Latest feature updates
- 📱 UI enhancements
- 🔄 Functionality improvements
- 📊 Performance optimizations

### Bug Fixes
- Recent bug fixes
- Stability improvements
- Enhanced error handling

### Code Optimizations
- Code structure improvements
- Performance enhancements
- Improved handling

### UI/UX Changes
- Interface updates
- Design improvements
- Better user experience

### Dependencies
- Package updates
- Integration improvements
- System enhancements

EOL

# Append existing content after new section
tail -n +2 README.md >> README.md.tmp
mv README.md.tmp README.md

# Commit changes
git add README.md
git commit -m "Update project with latest changes ($TIMESTAMP)"

# Push new branch
git push -u origin $BRANCH_NAME

# Merge to main
git checkout main
git merge $BRANCH_NAME
git push origin main

# Return to new branch
git checkout $BRANCH_NAME

echo "✅ Progress saved successfully!"
echo "🔄 New branch created: $BRANCH_NAME"
echo "📝 README updated with timestamp: $TIMESTAMP"
echo "🚀 Changes pushed to GitHub" 