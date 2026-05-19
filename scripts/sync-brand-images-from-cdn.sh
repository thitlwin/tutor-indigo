#!/usr/bin/env bash
# Download MyLanGo brand images from the marketing-site CDN (openedx-cms on Vercel)
# into tutor-indigo theme static folders for LMS and CMS.
#
# Source of truth for image bytes: openedx-cms/scripts/generate-mfe-logo.sh → deploy
# public/images/ to Vercel. This script copies those URLs into theme paths used at
# `tutor images build openedx` (see scripts/README.md).
#
# Usage (from tutor-indigo repo root):
#   ./scripts/sync-brand-images-from-cdn.sh
#   ./scripts/sync-brand-images-from-cdn.sh --base-url https://www.mylango.app/images
#   MYLANGO_MFE_LOGO_CDN_BASE_URL=https://www.mylango.app/images ./scripts/sync-brand-images-from-cdn.sh
#   ./scripts/sync-brand-images-from-cdn.sh --dry-run
#
# After syncing, rebuild the openedx image so Studio/LMS serve the new files:
#   tutor images build openedx

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LMS_IMAGES="${REPO_ROOT}/tutorindigo/templates/indigo/lms/static/images"
CMS_IMAGES="${REPO_ROOT}/tutorindigo/templates/indigo/cms/static/images"

DEFAULT_BASE_URL="https://www.mylango.app/images"
BASE_URL="${MYLANGO_MFE_LOGO_CDN_BASE_URL:-${DEFAULT_BASE_URL}}"
DRY_RUN=0

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --base-url)
      BASE_URL="${2:?--base-url requires a URL}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
  esac
done

BASE_URL="${BASE_URL%/}"

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required." >&2
  exit 1
fi

mkdir -p "${LMS_IMAGES}" "${CMS_IMAGES}"

# CDN filename => local path (under repo root)
declare -a DOWNLOADS=(
  "${BASE_URL}/logo.png|${LMS_IMAGES}/logo.png"
  "${BASE_URL}/logo-white.png|${LMS_IMAGES}/logo-white.png"
  "${BASE_URL}/favicon.ico|${LMS_IMAGES}/favicon.ico"
  "${BASE_URL}/favicon.ico|${CMS_IMAGES}/favicon.ico"
  "${BASE_URL}/logo.png|${CMS_IMAGES}/studio-logo.png"
)

download_one() {
  local url="$1"
  local dest="$2"
  local tmp="${dest}.tmp.$$"

  if [[ "${DRY_RUN}" -eq 1 ]]; then
    echo "  would fetch ${url}"
    echo "       -> ${dest}"
    return 0
  fi

  echo "  ${url}"
  echo "  -> ${dest}"
  curl -fSL --retry 3 --retry-delay 2 -o "${tmp}" "${url}"
  mv -f "${tmp}" "${dest}"
}

echo "Syncing tutor-indigo brand images from CDN"
echo "  base URL: ${BASE_URL}"
echo "  LMS dir:  ${LMS_IMAGES}"
echo "  CMS dir:  ${CMS_IMAGES}"
echo

for entry in "${DOWNLOADS[@]}"; do
  url="${entry%%|*}"
  dest="${entry#*|}"
  download_one "${url}" "${dest}"
done

echo
if [[ "${DRY_RUN}" -eq 1 ]]; then
  echo "Dry run complete (no files written)."
else
  echo "Done. Rebuild openedx to bake assets into the image:"
  echo "  tutor images build openedx"
fi
