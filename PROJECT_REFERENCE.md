# Project Quick Reference

## Stack
- **Rails:** 7.1.5.1
- **Webpacker:** Yes
- **Sprockets:** Yes
- **Vue:** Yes (no React)
- **Turbo (Hotwire):** Yes
- **Bootstrap:** Yes

## Asset Pipeline
- **Recompile assets:**  
  - `rails assets:precompile`
  - `rails assets:clobber` (to clear old assets)
- **Restart Rails server after SCSS/JS changes:** Recommended
- **Hard refresh browser after asset changes:** Always (`Ctrl+Shift+R` or `Cmd+Shift+R`)

## Theming
- **Theme variables:**  
  - Set on `<body data-theme="...">`
  - Defined in `_dark_theme.scss` and `_light_theme.scss`
- **All theme colors referenced via CSS variables:** Yes (e.g., `var(--card-bg)`)
- **Switching theme:**  
  - Changes `data-theme` on `<body>`
  - All components should use theme variables for colors

## Debugging Tips
- **Check compiled CSS for theme variable blocks** (e.g., `body[data-theme="light"] { --card-bg: ... }`)
- **Use browser console to check CSS variables:**  
  - `getComputedStyle(document.body).getPropertyValue('--card-bg')`
- **If theme changes don't work:**  
  - Recompile assets and restart server
  - Hard refresh browser

## Gotchas
- **Turbo navigation:**  
  - Most UI is in Vue components, so no special re-initialization needed.
  - Any custom JS should use `document.addEventListener('turbo:load', ...)` to work with Turbo. (Already handled.)
- **Vue:**  
  - Using standard Rails+Webpacker+Vue setup.
  - No special plugins or loaders.
- **Bootstrap:**  
  - Bootstrap's default styles may override custom theme variables if not using `!important` or specific selectors.

## Project Tips & Best Practices
- **Consistency:**
  - Always use the same styling and design approach as the rest of the app for new features and UI changes.
- **Localization:**
  - The app supports multiple languages. Always localize new features and UI text.
- **Multitenancy & Devise:**
  - The app is multitenant, enforced via Devise. Always confirm user-specific data access and scoping. Some data is global, but most is per-user.
- **Source Control:**
  - Code is saved in GitHub under the project name: `cotalo2`.
- **Production Environment:**
  - The production environment is hosted on Heroku.