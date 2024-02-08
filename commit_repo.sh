#!/bin/bash

# Simple GitHub Push Script
# Edit the variables below with your details

# Configuration - EDIT THESE

TOKEN="${GITHUB_TOKEN:-}"  # Get from environment variable
REPO_URL="https://github.com/chrizfasa424/admin-backend.git"
USER_NAME="chrizfaza"
USER_EMAIL="chrizfaza@gmail.com"
BRANCH="main"

#!/bin/bash

# Secure GitHub Push Script - No hardcoded tokens!

# Configuration - EDIT THESE (except TOKEN)


# Check if token is provided
if [ -z "$TOKEN" ]; then
    echo "❌ Error: GITHUB_TOKEN environment variable not set"
    echo "💡 Set it with: export GITHUB_TOKEN=ghp_your_token_here"
    echo "💡 Or run: GITHUB_TOKEN=ghp_your_token_here bash commit_repo.sh"
    exit 1
fi

# Get commit message from command line or prompt
if [ -z "$1" ]; then
    echo "Enter commit message:"
    read COMMIT_MESSAGE
else
    COMMIT_MESSAGE="$1"
fi

# Remove quotes from commit message if present
COMMIT_MESSAGE=$(echo "$COMMIT_MESSAGE" | sed 's/^"//;s/"$//')

# Extract repo name
REPO_NAME=$(basename "$REPO_URL" .git)

# Create authenticated URL
AUTH_URL=$(echo "$REPO_URL" | sed "s|https://|https://$TOKEN@|")

echo "🚀 Starting push to $REPO_URL"
echo "📝 Commit message: $COMMIT_MESSAGE"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "📁 Initializing git repository..."
    git init
    
    # Configure git
    echo "⚙️ Configuring git..."
    git config user.name "$USER_NAME"
    git config user.email "$USER_EMAIL"
    
    # Add remote
    git remote add origin "$AUTH_URL"
    
    # Create initial branch
    git checkout -b "$BRANCH"
else
    echo "📁 Using existing git repository..."
    
    # Configure git
    echo "⚙️ Configuring git..."
    git config user.name "$USER_NAME"
    git config user.email "$USER_EMAIL"
    
    # Update remote URL with token
    if git remote get-url origin &>/dev/null; then
        git remote set-url origin "$AUTH_URL"
    else
        git remote add origin "$AUTH_URL"
    fi
    
    # Make sure we're on the right branch
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "$BRANCH" ]; then
        # Check if branch exists locally
        if git show-ref --verify --quiet refs/heads/$BRANCH; then
            git checkout "$BRANCH"
        else
            git checkout -b "$BRANCH"
        fi
    fi
fi

# Show current status
echo "📊 Repository status:"
git status --porcelain

# Handle nested git repositories
echo "🔍 Checking for nested git repositories..."
find . -name ".git" -type d | while read gitdir; do
    if [ "$gitdir" != "./.git" ]; then
        parent_dir=$(dirname "$gitdir")
        echo "⚠️ Found nested git repository in: $parent_dir"
        echo "🗑️ Removing .git directory from: $parent_dir"
        rm -rf "$gitdir"
    fi
done

# Add all changes (including untracked files)
echo "📝 Adding all changes..."
git add -A

# Check if there are changes after adding
if git diff --cached --quiet; then
    echo "ℹ️ No changes to commit after adding files"
    
    # List files to help debug
    echo "📂 Files in directory:"
    ls -la
    
    echo "📂 Git status:"
    git status
    
    exit 0
fi

# Show what will be committed
echo "📋 Files to be committed:"
git diff --cached --name-status

# Commit changes
echo "💾 Committing changes..."
git commit -m "$COMMIT_MESSAGE"

if [ $? -ne 0 ]; then
    echo "❌ Failed to commit changes"
    exit 1
fi

# Try to push, handling the case where remote branch doesn't exist
echo "🔄 Pushing to $BRANCH..."

# First, try a regular push
if git push origin "$BRANCH" 2>/dev/null; then
    echo "✅ Successfully pushed!"
else
    echo "⚠️ Regular push failed, trying to set upstream..."
    # If that fails, try setting upstream (for first push)
    if git push -u origin "$BRANCH"; then
        echo "✅ Successfully pushed with upstream set!"
    else
        echo "❌ Push failed!"
        echo "🔍 Checking remote repository status..."
        
        # Try to fetch to see what's on remote
        git fetch origin 2>/dev/null || echo "Could not fetch from remote"
        
        # Show remote branches
        echo "Remote branches:"
        git branch -r 2>/dev/null || echo "No remote branches found"
        
        exit 1
    fi
fi

# Clean up token from remote URL
CLEAN_URL=$(echo "$AUTH_URL" | sed "s|https://$TOKEN@|https://|")
git remote set-url origin "$CLEAN_URL"

echo "🎉 Done!"
echo "🌐 Repository URL: $REPO_URL"