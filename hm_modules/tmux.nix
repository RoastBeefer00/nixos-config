{ ... }:
{
  programs.tmux = {
    enable = true;
    extraConfig = ''
      		#set -g default-shell /etc/profiles/per-user/roastbeefer/bin/fish
      set -g default-terminal "tmux-256color"
      # set -ag terminal-overrides ",xterm-256color:RGB"

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
      		'';
  };
}
