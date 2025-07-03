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

## 🛠️ Integrating Third-Party CSS (e.g., vue-multiselect) with Sprockets and Webpacker

### Problem
Some third-party Vue components (like `vue-multiselect`) provide their CSS in `node_modules`, but Sprockets (Rails' asset pipeline) does **not** process CSS imports from `node_modules` by default. This can cause missing styles in production, even if everything works in development.

### Solution

**To include third-party CSS in your Sprockets-managed styles:**

1. **Copy the CSS file from `node_modules` to your assets:**
   ```sh
   cp node_modules/vue-multiselect/dist/vue-multiselect.min.css app/assets/stylesheets/_vue_multiselect.scss
   ```
   - Rename it with a leading underscore and `.scss` extension to make it a Sprockets partial.

2. **Import the partial in your main SCSS file:**
   ```scss
   // In app/assets/stylesheets/application.scss
   @import "vue_multiselect";
   ```

3. **Commit and deploy as usual.**
   - Sprockets will now include the styles in your main CSS bundle, and they will work in production.

### Troubleshooting

- If styles are still missing, make sure the file is present in `app/assets/stylesheets/` and the import path matches the filename (without the underscore or extension).
- After copying and importing, always commit and push to Heroku, then check the compiled CSS in production.