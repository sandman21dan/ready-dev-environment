-- svelte-language-server. Note the binary is `svelteserver`, not
-- `svelte-language-server` -- that is the bin name the npm package ships.
--
-- Unlike tsserver, this one formats with Prettier internally (it bundles
-- prettier-plugin-svelte and honours the project's .prettierrc), so formatting
-- on save is safe here and is enabled in `format_rules`.
return {
  cmd = { 'svelteserver', '--stdio' },
  filetypes = { 'svelte' },
  root_markers = { 'svelte.config.js', 'svelte.config.mjs', 'svelte.config.ts', 'package.json', '.git' },
  settings = {
    svelte = {
      plugin = {
        -- Diagnostics for the <script> and <style> blocks too.
        svelte = { compilerWarnings = { ['css-unused-selector'] = 'ignore' } },
      },
    },
  },
}
