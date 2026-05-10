# UT Austin Brand Assets

This directory holds branding assets for the UT Austin self-hosted Canvas
deployment.

## Status

The SVGs currently checked in are **placeholders** drawn in code. They use UT
Austin's public brand color (Burnt Orange `#BF5700`) but they are NOT the
official UT wordmark, shield, or Longhorn silhouette and they have not been
produced or approved by University Marketing & Communications (UMAC).

## Replacing with official assets

Before going to production, replace each file in this directory with the
official asset downloaded from the UMAC Brand Center:

  https://umac.utexas.edu/brand-center/

Files to replace:

- `ut-logomark.svg`        — top-left global nav mark (small, ~32px tall)
- `ut-mobile-nav-logo.svg` — mobile global nav mark
- `ut-login-logo.svg`      — login page hero logo (large, ~120px tall)

If you also want to override the favicon and Windows tiles, drop them here and
update the matching paths in `app/stylesheets/brandable_variables.json`
(`ic-brand-favicon`, `ic-brand-apple-touch-icon`,
`ic-brand-msapplication-tile-square`, `ic-brand-msapplication-tile-wide`).

Trademark use of UT Austin marks is governed by UMAC; do not deploy without
their authorization.
