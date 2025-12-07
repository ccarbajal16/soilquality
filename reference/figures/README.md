# Package Logo

Place your package logo here as `logo.png`

## Requirements

- **File name**: `logo.png`
- **Format**: PNG with transparent background (recommended)
- **Size**: 240x278 pixels or similar aspect ratio
- **Location**: This directory (`man/figures/logo.png`)

## Usage

The logo will automatically appear in:

1. **GitHub README** - Top right corner
2. **pkgdown website** - Navigation bar and favicon
3. **Package documentation**

## How It Works

- The logo is referenced in `README.md` as: `<img src="man/figures/logo.png" align="right" height="139" alt="" />`
- The logo is configured in `_pkgdown.yml` with: `logo: man/figures/logo.png`
- pkgdown automatically uses it for the website favicon and navbar

Once you add `logo.png` to this directory, commit and push it with your other changes.
