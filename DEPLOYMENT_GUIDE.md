# GitHub Pages Deployment Guide for soilquality

This guide explains how to deploy the soilquality package website to
GitHub Pages.

## What Has Been Set Up

The following files have been created to enable automatic website
deployment:

1.  **[\_pkgdown.yml](https://ccarbajal16.github.io/soilquality/_pkgdown.yml)** -
    Configuration for your package website
    - Defines website structure, navigation, and theming
    - Organizes function reference by categories
    - Links to vignettes and documentation
2.  **[.github/workflows/pkgdown.yaml](https://ccarbajal16.github.io/soilquality/.github/workflows/pkgdown.yaml)** -
    GitHub Actions workflow for building and deploying the website
    - Automatically builds the website when you push to the main/master
      branch
    - Deploys to the `gh-pages` branch
    - Triggered on push, pull requests, releases, and manually
3.  **[.github/workflows/R-CMD-check.yaml](https://ccarbajal16.github.io/soilquality/.github/workflows/R-CMD-check.yaml)** -
    GitHub Actions workflow for package checks
    - Runs R CMD check across multiple operating systems (Windows,
      macOS, Ubuntu)
    - Tests with multiple R versions (devel, release, oldrel-1)
    - Ensures package quality and compatibility
4.  **[.Rbuildignore](https://ccarbajal16.github.io/soilquality/.Rbuildignore)** -
    Updated to exclude GitHub-related files from package builds

## How to Enable GitHub Pages

Follow these steps to deploy your website:

### Step 1: Commit and Push Files

``` bash
git add .github/workflows/pkgdown.yaml
git add .github/workflows/R-CMD-check.yaml
git add _pkgdown.yml
git add .Rbuildignore
git add DEPLOYMENT_GUIDE.md
git commit -m "Add GitHub Actions workflows and pkgdown configuration"
git push origin master
```

### Step 2: Enable GitHub Pages in Repository Settings

1.  Go to your GitHub repository:
    <https://github.com/ccarbajal16/soilquality>
2.  Click on **Settings** (top navigation bar)
3.  In the left sidebar, click **Pages**
4.  Under **Source**, select:
    - **Source**: Deploy from a branch
    - **Branch**: `gh-pages`
    - **Folder**: `/ (root)`
5.  Click **Save**

### Step 3: Wait for the Workflow to Complete

1.  Go to the **Actions** tab in your GitHub repository
2.  You should see the “pkgdown” workflow running
3.  Wait for it to complete (usually takes 3-5 minutes)
4.  Once the workflow completes successfully, the `gh-pages` branch will
    be created

### Step 4: Verify Deployment

After the workflow completes and GitHub Pages is enabled:

1.  Your website will be available at:
    **<https://ccarbajal16.github.io/soilquality/>**
2.  It may take a few minutes for the site to become available after the
    first deployment
3.  Check the **Pages** settings to see the deployment status

## Website Structure

Your deployed website will include:

- **Home Page**: Rendered from README.md with installation instructions
  and quick start
- **Function Reference**: All package functions organized by category
  - Main SQI Computation
  - Data Handling
  - PCA and MDS Selection
  - AHP Weighting
  - Scoring Functions
  - Visualization
  - Interactive Tools
  - Example Data
- **Articles/Vignettes**:
  - Introduction to soilquality
  - Advanced Usage
  - AHP Matrices Guide
- **Changelog**: From NEWS.md

## Customization

### Modify Website Appearance

Edit
[\_pkgdown.yml](https://ccarbajal16.github.io/soilquality/_pkgdown.yml)
to customize:

- **Theme**: Change the `template.bootswatch` value (options: cosmo,
  flatly, darkly, etc.)
- **Colors**: Modify `template.bslib.primary`
- **Navigation**: Add/remove navbar items
- **Function grouping**: Reorganize the reference section

### Trigger Manual Deployment

You can manually trigger the workflow:

1.  Go to **Actions** tab
2.  Click on **pkgdown** workflow
3.  Click **Run workflow**
4.  Select the branch (usually `master`)
5.  Click **Run workflow**

## Troubleshooting

### Workflow Fails

1.  Check the **Actions** tab for error messages
2.  Common issues:
    - Missing dependencies: Add them to DESCRIPTION file
    - Vignette build errors: Check vignette code
    - Documentation issues: Run `devtools::document()` locally first

### Website Not Updating

1.  Ensure the workflow completed successfully
2.  Clear your browser cache
3.  Check if GitHub Pages is enabled in Settings
4.  Verify the `gh-pages` branch exists

### Permission Errors

If you see permission errors in the workflow:

1.  Go to **Settings** \> **Actions** \> **General**
2.  Scroll to **Workflow permissions**
3.  Select **Read and write permissions**
4.  Click **Save**

## Local Preview

To preview the website locally before pushing:

``` r
# Install pkgdown if needed
install.packages("pkgdown")

# Build and preview the site
pkgdown::build_site()

# The site will open in your browser
# Files are saved to docs/ directory (ignored by git)
```

## Continuous Integration

The R-CMD-check workflow runs automatically on: - Every push to
main/master - Every pull request - Ensures your package passes R CMD
check on multiple platforms

You can add a badge to your README.md to show the check status:

``` markdown
[![R-CMD-check](https://github.com/ccarbajal16/soilquality/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ccarbajal16/soilquality/actions/workflows/R-CMD-check.yaml)
```

## Additional Resources

- [pkgdown documentation](https://pkgdown.r-lib.org/)
- [GitHub Pages documentation](https://docs.github.com/en/pages)
- [GitHub Actions for R](https://github.com/r-lib/actions)
- [Example pkgdown
  sites](https://github.com/r-lib/pkgdown/blob/main/vignettes/examples.Rmd)

## Next Steps

After deployment:

1.  Update your README.md to point to the new website
2.  Add badges for build status and package version
3.  Consider adding a logo to
    [man/figures/logo.png](https://ccarbajal16.github.io/soilquality/man/figures/logo.png)
4.  Update vignettes with more examples and use cases
5.  Share your package website with the community!
