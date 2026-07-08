{ ... }:
{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      # set -ag terminal-overrides ",xterm-256color:RGB"

      # Forward the CSI-u / kitty keyboard protocol so control keys that are
      # byte-identical to legacy keys (Ctrl+H == Backspace, Ctrl+I == Tab,
      # Ctrl+M == Enter) are disambiguated. Without this, helix's sidekick
      # C-h "navigate back" is indistinguishable from Backspace and only works
      # intermittently. Requires a terminal that supports it (Ghostty does).
      set -s extended-keys on
      set -as terminal-features '*:extkeys'

      set -g prefix C-e
      unbind C-b
      bind-key C-e send-prefix

      unbind %
      bind | split-window -h 

      unbind '"'
      bind - split-window -v

      unbind r
      bind r source-file ~/.tmux.conf

      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 5

      bind -r m resize-pane -Z

      set -g mouse on
      set -wg mode-style bg=blue,fg=black

      set-window-option -g mode-keys vi

      bind-key -T copy-mode-vi 'v' send -X begin-selection # start selecting text with "v"
      bind-key -T copy-mode-vi 'y' send -X copy-selection # copy text with "y"

      unbind -T copy-mode-vi MouseDragEnd1Pane # don't exit copy mode when dragging with mouse

      # remove delay for exiting insert mode with ESC in Neovim
      set -sg escape-time 10

      # tpm plugin
      set -g @plugin 'tmux-plugins/tpm'

      # list of tmux plugins
      set -g @plugin 'christoomey/vim-tmux-navigator'
      # set -g @plugin 'jimeh/tmux-themepack'
      set -g @plugin 'niksingh710/minimal-tmux-status'
      set -g @plugin 'tmux-plugins/tmux-resurrect' # persist tmux sessions after computer restart
      set -g @plugin 'tmux-plugins/tmux-continuum' # automatically saves sessions for you every 15 minutes

      # No extra spaces between icons
      set -g @minimal-tmux-use-arrow true
      set -g @minimal-tmux-right-arrow ""
      set -g @minimal-tmux-left-arrow ""

      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'

      # Don't exit tmux when destroying a session
      set-option -g detach-on-destroy off

      if "test ! -d ~/.tmux/plugins/tpm" \
         "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"
      # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
      run '~/.tmux/plugins/tpm/tpm'

      # Smart split navigation — helix-aware (must be after tpm to override vim-tmux-navigator).
      # When hx/vim/nvim is focused: forward C-h/j/k/l to the editor.
      # Helix's Steel smart-window-* functions navigate splits first; at the edge they
      # call `tmux select-pane` to continue into the next tmux pane.
      # When any other program is focused: navigate tmux panes directly.
      is_hx_or_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\S+\/)?g?(view|l?n?vim?x?|hx)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_hx_or_vim" 'send-keys C-h' 'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_hx_or_vim" 'send-keys C-j' 'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_hx_or_vim" 'send-keys C-k' 'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_hx_or_vim" 'send-keys C-l' 'select-pane -R'
      		'';
  };
}
