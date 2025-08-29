# Release Guide

This document provides comprehensive guidance for maintainers on releasing new versions of the fasti gem.

## Overview

This project uses GitHub Actions workflows for automated releases with a three-stage process:

1. **Release Preparation** (Manual) - Creates release branch and updates version files
2. **Release Validation** (Automatic) - Validates release PR before merge
3. **Release Publish** (Automatic) - Publishes gem and creates GitHub release

## Quick Start

To create a new release:

1. **Prepare Release**:
   - Navigate to the GitHub repository
   - Go to **Actions** → **Release Preparation**
   - Click **Run workflow**
   - Enter the version number (e.g., `1.0.0`)

2. **Review and Merge**:
   - The workflow will create a release branch and pull request automatically
   - Review the generated PR (version bump, CHANGELOG update)
   - Merge the PR when ready

3. **Automatic Publishing**:
   - After PR merge, the **Release Publish** workflow runs automatically
   - Creates git tag and pushes to GitHub
   - Builds and publishes gem to RubyGems
   - Creates GitHub release with assets
   - Cleans up release branch

## Workflow Details

### 1. **Release Preparation** (Manual)
- **Trigger**: Manual execution via Actions tab
- **Purpose**: Creates and configures release branch
- **Actions**:
  - Creates `release-v{version}` branch
  - Updates `VERSION` constant in `lib/{gem}/version.rb`
  - Updates `CHANGELOG.md` with release date and new unreleased section
  - Commits changes and pushes branch
  - Creates pull request automatically

### 2. **Release Validation** (Automatic on PR)
- **Trigger**: PR creation/updates for `release-v*` branches
- **Purpose**: Pre-merge validation to prevent release failures
- **Actions**:
  - :white_check_mark: Validates semantic version format
  - :white_check_mark: Checks version consistency between branch and file
  - :white_check_mark: Verifies git tag doesn't already exist
  - :white_check_mark: Confirms version not yet published on RubyGems
  - :white_check_mark: Validates RubyGems API key is configured
  - :white_check_mark: Runs quality checks (RuboCop + RSpec)
  - :white_check_mark: Validates CHANGELOG.md format
  - :white_check_mark: Ensures release branch contains only version and changelog updates

### 3. **Release Publish** (Automatic on merge)
- **Trigger**: Merge of `release-v*` PR to main
- **Purpose**: Actual gem publishing and release creation
- **Actions**:
  - Creates and pushes git tag via `rake release`
  - Builds and publishes gem to RubyGems
  - Creates GitHub Release with gem attachment
  - Removes release branch automatically

## Requirements

### RubyGems API Key Setup

For automated gem publishing, you need to configure the RubyGems API key:

#### 1. Generate API Key on RubyGems.org
- Log in to [RubyGems.org](https://rubygems.org)
- Go to **Profile** → **API Keys**
- Click **New API Key**
- Enter a name (e.g., "GitHub Actions for [repository-name]")
- Select appropriate scopes (typically "Push rubygems")
- Copy the generated API key

#### 2. Add to GitHub Secrets
- Go to your GitHub repository
- Navigate to **Settings** → **Secrets and variables** → **Actions**
- Click **New repository secret**
- Name: `RUBYGEMS_API_KEY`
- Value: paste your API key from step 1
- Click **Add secret**

**Note**: The workflow will fail with clear instructions if this secret is not configured.

### Optional: Branch Protection Rules

To prevent merging release PRs with missing secrets or validation failures:

#### 1. Go to Repository Settings
- Navigate to **Settings** → **Branches**

#### 2. Add Branch Protection Rule
- Click **Add rule**
- Branch name pattern: `main`

#### 3. Configure Protection Settings
- :white_check_mark: **Require status checks to pass before merging**
- :white_check_mark: **Require branches to be up to date before merging**
- In **Status checks that are required**, add:
  - `validate-release` (from Release Validation workflow)

#### 4. Save Changes
- Click **Create** or **Save changes**

With this setup, release PRs cannot be merged if:
- RubyGems API key is missing
- Version validation fails
- Quality checks don't pass
- CHANGELOG.md format is incorrect

## Workflow Features

- **:lock: Pre-merge validation**: Comprehensive checks before PR merge (Release Validation)
- **:clipboard: Version validation**: Semantic versioning format and consistency verification
- **:test_tube: Quality gates**: RuboCop linting and RSpec tests must pass
- **:key: Secret validation**: Ensures RubyGems API key is properly configured
- **:memo: Automated changelog**: Updates CHANGELOG.md with UTC release dates
- **:closed_lock_with_key: Security**: Secure credential handling with proper file permissions
- **:broom: Cleanup**: Automatic release branch removal after successful publishing
- **:shield: Duplicate protection**: Prevents accidental re-releases of same version
- **:file_folder: File restriction**: Ensures release branches only contain version/changelog changes
- **:arrows_counterclockwise: Reusability**: Generic workflows adaptable to other Ruby gems
- **:zap: Efficiency**: Eliminates duplicate validations across workflows

## Troubleshooting

### If release workflow fails:

#### 1. Missing RubyGems API key
- Configure the secret as described above
- Go to **Actions** → **Release Publish** → **Re-run jobs**

#### 2. Disallowed files in release branch
- **What happens**: Release Validation workflow fails with detailed error message
- **PR cannot be merged**: Branch protection prevents merge until validation passes
- **Error shows**: List of disallowed files and allowed file patterns
- **To fix**:
  ```bash
  # Option 1: Remove disallowed changes from release branch
  git checkout release-v1.0.0
  git reset --soft HEAD~1  # Undo last commit
  git reset HEAD file1.rb file2.rb  # Unstage disallowed files
  git commit --amend  # Re-commit with only allowed files
  git push --force-with-lease
  
  # Option 2: Extract disallowed changes to separate feature branch
  # 1. Create feature branch from main
  git checkout main && git pull origin main
  git checkout -b feature/extracted-changes
  
  # 2. Cherry-pick disallowed changes from release branch
  git cherry-pick <commit-hash-with-disallowed-changes>
  git push -u origin feature/extracted-changes
  
  # 3. Remove disallowed changes from release branch
  git checkout release-v1.0.0
  git rebase -i HEAD~n  # Change 'pick' to 'drop' for disallowed commits
  git push --force-with-lease
  
  # 4. Create separate PR for feature branch (normal development flow)
  ```

#### 3. Before gem publishing
Simply re-run the workflow or re-merge the PR

#### 4. After gem publishing
- The gem cannot be re-published with the same version
- Create GitHub Release manually if needed:
  ```bash
  gh release create v1.0.0 --title "Gem Name v1.0.0" --notes "Release notes"
  ```
- For new fixes, use a patch version (e.g., 1.0.1) instead

## Important Notes

- **Regular development PRs are unaffected**: Only `release-v*` branches trigger release workflows
- **Branch protection recommended**: Set up branch protection rules to enforce validation
- **Reusable across projects**: Workflows use `${{ github.event.repository.name }}` as default gem name
- **UTC timestamps**: All release dates in CHANGELOG.md use UTC timezone for consistency