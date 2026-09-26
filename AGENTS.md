# Language support

- Before adding or changing language support, search for a dedicated Neovim
  plugin for that language. For PowerShell, evaluate
  https://github.com/theleop/powershell.nvim.
- Check maintenance status, compatibility with this config, and usability before
  choosing it. Prefer a maintained, usable language plugin and reuse existing
  plugins where possible.
- Fall back to direct LSP configuration only when no dedicated plugin exists,
  or available plugins are unmaintained or unusable. Explain the evidence for
  that fallback; do not assume LSP alone is the default.
