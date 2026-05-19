# tutor-indigo scripts

## Sync brand images from the marketing-site CDN

`sync-brand-images-from-cdn.sh` downloads MyLanGo logo and favicon files from the **openedx-cms** Vercel CDN into the Indigo theme static directories used at `tutor images build openedx`.

This follows the upstream Indigo approach (replace files under `tutorindigo/templates/indigo/lms/static/images` and `.../cms/static/images`) without maintaining a second copy of the artwork by hand.

### Source of truth

1. Generate assets in the **openedx-cms** repo: `scripts/generate-mfe-logo.sh` (or `pnpm generate:mfe-logo`).
2. Commit `public/images/*` and deploy Vercel so files are served at e.g. `https://www.mylango.app/images/logo.png`.
3. Run this script to copy those URLs into tutor-indigo theme paths before building the `openedx` image.

MFE apps use runtime URLs from `tutor-plugins-local/mfe_logo_urls_patch.py` (`MYLANGO_MFE_LOGO_CDN_BASE_URL`). LMS/Studio classic UI uses theme static files; this script keeps those files aligned with the same CDN.

### Usage

From the **tutor-indigo** repository root:

```bash
./scripts/sync-brand-images-from-cdn.sh
```

Options:

| Option / env | Description |
|--------------|-------------|
| `--base-url URL` | CDN base URL (no trailing slash). Default: `https://www.mylango.app/images` |
| `MYLANGO_MFE_LOGO_CDN_BASE_URL` | Same as `--base-url` (matches `mfe_logo_urls_patch.py`) |
| `--dry-run` | Print URLs and destination paths only |
| `-h`, `--help` | Show script usage |

Examples:

```bash
./scripts/sync-brand-images-from-cdn.sh --dry-run

MYLANGO_MFE_LOGO_CDN_BASE_URL=https://www.mylango.app/images ./scripts/sync-brand-images-from-cdn.sh

./scripts/sync-brand-images-from-cdn.sh --base-url https://www.mylango.app/images
```

Requires `curl`.

### File mapping

| CDN file | LMS path | CMS path |
|----------|----------|----------|
| `logo.png` | `tutorindigo/templates/indigo/lms/static/images/logo.png` | `tutorindigo/templates/indigo/cms/static/images/studio-logo.png` |
| `logo-white.png` | `tutorindigo/templates/indigo/lms/static/images/logo-white.png` | — |
| `favicon.ico` | `tutorindigo/templates/indigo/lms/static/images/favicon.ico` | `tutorindigo/templates/indigo/cms/static/images/favicon.ico` |

### After syncing

Rebuild the platform image so LMS and Studio serve the updated static files:

```bash
tutor images build openedx
```

Then restart as usual (`tutor local start -d` or your environment’s equivalent).
