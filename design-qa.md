# Analysis Detail Design QA

Final result: passed

## Comparison target

- Live source: `https://tp-86.replit.app/analyses/33511`
- Source viewport: 440 x 956 CSS pixels (iPhone 16 Pro Max preset).
- Source result capture: `/private/tmp/tradepilot-web-iphone16-result.png`.
- Mobile viewport: 440 x 956 logical pixels at 3x density.
- Mobile captures: `/private/tmp/tradepilot-mobile-detail-parity.png`, `/private/tmp/tradepilot-mobile-detail-lower.png`, and `/private/tmp/tradepilot-mobile-adaptive-current-2.png`.
- Adaptive state: Mini, trading capital $1,000, loss limit $1,000, Aggressive.

## Source-of-truth state

- The live web result is `WAIT`, not Buy or Sell.
- It displays a $1,000 hard loss maximum, $500 usable risk, and $500 reserved risk.
- Both directions remain reviewable as conditional reference scenarios; copy-as-entry is disabled.
- The page order is header and timeframe, directional bias, chart, Suggested Levels, Fundamental Context, Market Context Summary, Adaptive Trading Plan, Technical Indicators, Price alerts, then feedback and footer content.

## Implemented parity

- The mobile reading order matches the responsive web order. Desktop-only columns reflow to one mobile column.
- The header uses the saved outcome instead of a hard-coded Pending state.
- Suggested Levels, Fundamental Context, Market Context Summary, Adaptive Trading Plan, Technical Indicators, and Price alerts use the same hierarchy, dark surfaces, thin borders, yellow primary action, and semantic market colors.
- The Adaptive form includes the fixed account profile, account tiers, capital, loss limit, risk styles, theoretical margin capacity, snapshot time, Create recommendation, and Understand the details.
- A saved neutral/Wait decision stays `WAIT` even when the technical tally leans to one side. The result displays the unconfirmed-direction warning and conditional scenarios instead of inventing a recommendation.
- Editing capital or loss limit clears the old result so stale financial output cannot remain visible.
- Pro and Beginner invalidation rules are read from their correct API fields; the details badge is derived from saved rules.

## Comparison history

### Iteration 1

- P1: the mobile outcome chip always displayed Pending. Fixed by mapping the saved outcome enum.
- P1: Understand the details used a fixed count. Fixed by counting the saved invalidation rules.
- P2: the lower sections used a different order. Fixed to match the live responsive page.

### Iteration 2

- P1: a neutral high-risk snapshot could be converted into a directional plan by the technical tally. Fixed in the shared recommendation builder; the exact Mini / $1,000 / $1,000 / Aggressive state now remains conditional `WAIT`.
- P1: changed financial input could leave a stale recommendation on screen. Fixed by clearing the result when either input changes.
- P2: theoretical margin capacity and the web's WAIT decision hierarchy were missing. Added using the existing rule model and UI components.

## Finish gate

- Visual hierarchy: PASS — responsive source and mobile captures use the same section hierarchy and priority.
- Responsive layout: PASS — 440 x 956 viewport has single-column reflow and no horizontal overflow in the checked screens.
- Content parity: PASS — labels and result semantics mirror the live web state and remain localized.
- Interaction states: PASS — conditional plans disable copy-as-entry; money edits invalidate stale output; disclosures remain scrollable.
- Accessibility: PASS — semantic text remains available, tap targets use existing app controls, and the large-text widget test passes.
- Runtime: PASS — targeted analyzer reports no issues; 23 focused model/widget tests pass; `git diff --check` passes.
- P0/P1/P2 findings: none remaining.

## Remaining P3

- Web and mobile sessions expose different saved history records, so data-dependent prices and copy cannot be pixel-compared on the same analysis ID. Shared layout and the requested recommendation state are covered by live-source inspection and deterministic tests.

# History Design QA

Final result: passed

## Comparison target

- Live source: `https://tp-86.replit.app/history`.
- Source viewport: 440 x 956 CSS pixels using the iPhone 16 Pro Max responsive preset.
- Source captures: `/private/tmp/tradepilot-web-history-summary-viewport.png` and `/private/tmp/tradepilot-web-history-list-viewport.png`.
- Mobile viewport: 440 x 956 logical pixels at 3x density.
- Mobile captures: `/private/tmp/tradepilot-mobile-history-summary-new.png` and `/private/tmp/tradepilot-mobile-history-summary-lower-new.png`.
- Side-by-side review: `/private/tmp/tradepilot-history-summary-comparison.png`.

## Implemented parity

- The page title, total count, Summary/History switcher, 7D/30D/90D/All range selector, metric grid, insights, instrument focus, and timeframe breakdown follow the responsive web hierarchy.
- The default Summary request now loads the selected 30D range. The all-time total remains in the page header while the metric cards reflect the selected range, matching the web behavior.
- History uses the web search placeholder, filter action, compact analysis rows, five items per page, page/range labels, Previous/Next actions, and Re-analyze action.
- Metrics preserve the backend distinctions between active-valid, TP1, TP2, SL, expired, and invalidated outcomes instead of merging them in the presentation layer.
- The full header and controls participate in the page scroll, matching the responsive web page rather than remaining pinned above the list.
- English and Indonesian labels are generated from the existing localization pipeline; no new package or duplicate data layer was added.

## Comparison history

### Iteration 1

- P1: the 30D selector initially displayed all-time summary data because the first request omitted its range. Fixed at the request call site and retry path.
- P2: page controls stayed fixed while the web header scrolls with the content. Fixed by moving the shared header into both Summary and History scroll views.
- P2: the mobile History rows were denser and exposed confidence/risk fields absent from the responsive web row. Replaced with the web instrument, timeframe, market context, lean, date, outcome, validity, note, and Re-analyze hierarchy.
- P2: TP1 and TP2 were combined. Kept them as separate server-backed metrics throughout the statistics model and summary UI.
- P2: 200% text scaling overflowed the compact row. Fixed by allowing the metadata row to reflow; covered by a widget test.

## Finish gate

- Visual hierarchy: PASS — side-by-side review shows the same header, switcher, range controls, two-column metric grid, and stacked insight order.
- Responsive layout: PASS — checked at 440 x 956; the summary becomes one column at large text and the compact row has no overflow at 200% scaling.
- Content parity: PASS — Summary and History expose the same labels, status categories, filters, breakdowns, and pagination model as the live responsive source.
- Interaction states: PASS — range, metric drill-down, instrument/timeframe focus, filtering, pagination, row opening, and Re-analyze paths are wired to existing provider flows.
- Accessibility: PASS — interactive cards, tabs, and buttons use Material semantics and remain readable at 200% text scaling.
- Runtime: PASS — targeted analyzer reports no issues, 26 focused tests pass, the updated app compiles for the iOS simulator, and `git diff --check` passes.
- P0/P1/P2 findings: none remaining.

## Remaining P3

- The web and mobile authenticated sessions contain different history totals, so numeric values are not expected to be pixel-identical. The final simulator cold start returned to login, so the last request-range correction was verified by code analysis and tests rather than a second authenticated screenshot; it changes fetched counts, not the validated layout.

# Profile Design QA

final result: passed

## Comparison target

- Source visual truth: `https://tp-86.replit.app/profile` in dark mode with a regular user and Level 1 progression.
- Source captures: `/private/tmp/tradepilot-web-profile-viewport.png` and `/private/tmp/tradepilot-web-profile-full.png`.
- Implementation capture: `/private/tmp/tradepilot-mobile-profile-preview.png`.
- Full-view comparison: `/private/tmp/tradepilot-profile-comparison.png`.
- Source capture: 425 x 923 pixels from a 440 x 956 iPhone 16 Pro Max browser viewport.
- Implementation capture: 1320 x 2868 pixels at 3x density, representing 440 x 956 logical pixels.
- Density normalization: the implementation was downsampled to 425 x 923 for the side-by-side comparison.
- State: authenticated regular user, dark theme, Level 1 `seedling`, zero analysis credits.

## Findings

- No actionable P0/P1/P2 differences remain. The responsive hierarchy, card widths, two-column identity row, progression row, Appearance selector, compact settings rows, semantic colors, and copy match the live source.
- Typography: PASS — heading, identity, labels, secondary copy, role badge, and compact control weights preserve the source hierarchy and wrapping.
- Spacing and layout rhythm: PASS — 16-pixel page gutters, 20-pixel card padding, 24-pixel section gaps, compact row padding, radii, and dividers follow the source composition.
- Colors and tokens: PASS — the existing dark theme supplies the black canvas, dark cards, muted text, amber active control, and red destructive action.
- Image and icon fidelity: PASS — the existing avatar and progression components remain real app components; standard Material icons replace the matching settings glyphs without placeholder artwork.
- Copy and content: PASS — Profile now exposes Edit, Appearance, Change Password, Security Question, Privacy & Security, My Alerts, Notification Settings, Analysis Credits, Sign Out, and the shared legal footer in the source order.

## Interaction evidence

- Avatar and Edit open the existing native profile editor.
- Password, security question, price alerts, notification settings, progression, credits, Privacy & Security, and Sign Out are wired to existing native or allowlisted external flows.
- Notification Settings opens directly on its Settings tab.
- Privacy & Security preserves the native biometric lock and routes legal/account deletion through existing secure flows.
- Widget tests cover the responsive structure, safe external-link failure, logout, password validation, passwordless deletion, and 200% text scaling.

## Comparison history

### Iteration 1

- P1: the old mobile page exposed many unrelated cards and did not contain Analysis Credits or Notification Settings. Replaced it with the focused responsive web hierarchy and the missing server-backed credit balance.
- P2: identity and progression were separate cards. Combined them into the single source card with the same avatar, role, level, rank, and edit affordances.
- P2: theme controls, security actions, legal actions, alerts, and journal tools were split across titled sections. Consolidated the source-visible actions into one compact divided settings card.
- P2: My Alerts initially reused older mobile copy. Added the exact responsive-web label and description in both supported locales.
- Post-fix evidence: `/private/tmp/tradepilot-profile-comparison.png` shows the normalized source and implementation after these fixes.

## Focused comparison

- A separate crop was not needed because identity, progression, Appearance, and every settings row remain legible in the 850 x 923 side-by-side comparison.

## Finish gate

- Responsive composition: PASS at 440 x 956 logical pixels.
- Large text: PASS at 200% scaling without overflow.
- Primary interactions: PASS through existing provider, navigator, and secure account flows.
- Static analysis and formatting: PASS.
- P0/P1/P2 findings: none remaining.

## Remaining P3

- The progression emblem uses the existing native TradePilot emblem component, so its internal symbol treatment differs slightly from the web SVG while preserving the same tier palette, level, and rank meaning.

# Guide Design QA

final result: passed

## Comparison target

- Source visual truth: `https://tp-86.replit.app/guide`, captured in the connected browser at a 440 x 956 iPhone responsive viewport.
- Implementation screenshot: `/private/tmp/tradepilot-mobile-guide-final.png`.
- Source pixels/CSS viewport: 440 x 956 pixels at 1x browser density.
- Implementation pixels/CSS viewport: 1320 x 2868 pixels at 3x density, representing 440 x 956 logical pixels.
- State: English, dark theme, Guide list with Quick Start, all categories selected, and no search query.
- Full-view evidence: source and implementation were opened together in one comparison input after the final simulator capture.

## Findings

- No actionable P0/P1/P2 differences remain in the Guide-owned content. The app shell header, live ticker, and bottom navigation were excluded from the isolated Flutter preview because those are supplied by `HomeShell` in production.
- Fonts and typography: PASS — page title, subtitle, quick-start eyebrow/title, category headings, article labels, and muted helper copy use the same hierarchy and wrapping as the source.
- Spacing and layout rhythm: PASS — 16-pixel gutters, 48-pixel search field, 12-pixel card padding, stacked quick-start cards, horizontal category rail, spotlight, and compact article rows follow the responsive source.
- Colors and visual tokens: PASS — existing TradePilot tokens provide the black canvas, elevated dark cards, amber active state, muted labels, borders, and completion state. Mobile borders remain intentionally stronger for low-brightness OLED readability.
- Image and icon fidelity: PASS — the screen contains no raster artwork; native Material icons map to the source's book, sparkle, category, psychology, completion, and chevron glyphs.
- Copy and content: PASS — quick-start order, category order, spotlight, article titles, localized article bodies, related-topic action, and completion action match the current web source.

## Interaction evidence

- Search, clear search, category selection, psychology spotlight, quick-start cards, article cards, inline back action, related article, and completion flow remain functional.
- The article view uses the source hierarchy: inline back action, category badge, title, article blocks, related-topic action, divider, and completion control.
- A widget test covers category filtering, article navigation, and 200% text scaling; the initial large-text overflow in the page-title row was fixed with flexible title layout.

## Comparison history

### Iteration 1

- P1: the old mobile Guide used generic `ListTile` cards with summaries and omitted the web psychology spotlight. Replaced it with source-shaped quick-start, spotlight, category, and article cards.
- P2: the article view used a native title AppBar instead of the web's inline back action, category badge, and article heading. Rebuilt the article header and added the source related-topic action.
- P2: the search field and quick-start cards did not match responsive density. Tightened the search control and set the same quick-start minimum height.
- P2: 200% text scaling overflowed the Guide title row by 53 pixels. Made the title flexible and verified the corrected state in the widget test.
- Post-fix evidence: `/private/tmp/tradepilot-mobile-guide-final.png` compared with the live 440 x 956 browser capture.

## Focused comparison

- No separate crop was needed: the title, search, all three quick-start cards, category rail, psychology spotlight, first category heading, and multiple article rows were legible in the shared full-view comparison.

## Finish gate

- Responsive composition: PASS at 440 x 956 logical pixels.
- Large text: PASS at 200% scaling without overflow.
- Primary interactions: PASS through existing navigation, provider, and progression flows.
- Static analysis, widget test, formatting, and whitespace validation: PASS.
- P0/P1/P2 findings: none remaining.
