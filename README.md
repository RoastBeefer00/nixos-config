# nixos-config

## Post-switch: herdr plugin setup (one-time, not declarative)

herdr manages its own plugin registry in `~/.config/herdr/plugins/` and cannot
be wired up purely through Nix. Run these once after `darwin-rebuild switch` / `nixos-rebuild switch`:

```bash
# Register the vendored plugin (symlinked into ~/.config/herdr/plugins/ by home-manager)
herdr plugin link ~/.config/herdr/plugins/vim-herdr-navigation

# Plugins with a build step (cannot live in the read-only Nix store)
herdr plugin install Crokily/herdr-lazygit        # lazygit split pane (prefix+ctrl+g)
herdr plugin install smarzban/herdr-file-viewer   # git-aware file/diff viewer (prefix+f)
herdr plugin install tdi/herdr-worktree-setup     # mise/direnv/.env on new worktree
herdr plugin install yankewei/herdr-focus-notify  # macOS agent-done notifications

herdr server reload-config   # after any config.toml change (server caches it)
```
