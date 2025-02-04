# vimtux

## Fork Related Things
This fork extends the original plugin [`brauner/vimtux`](https://github.com/brauner/vimtux)
by adding the following functionalities listed below.
Note that I extended this plugin shortly after I started to use Vim, so don't expect
neither a clean vimscript syntax nor added functionalities without bugs! So far, however,
I'm more than happy with the actual state of this forked plugin...

### Added Functionalities
- Add option to select tmux pane visually, either by `popup_menu` (`let g:vimtux_popup = 1`) or by `fzf` (`let g:vimtux_fzf = 1`)
- Add function to show/check currently selected pane: `CheckTmux`
- Add function to send text to tmux using motions (`.` repeatable): `NormalModeSendToTmuxMotion`

### My (Fork-Related) Settings and Mappings
```vim
" choose pane visually
if has('nvim')
    let g:vimtux_fzf = 1
else
    let g:vimtux_popup = 1
endif

" motion mapping (r because I'm mostly using vimtux for R scripting)
" now I can send text by using motion commands, e.g. <leader>rap, etc.
" these commands are repeatable using .
nmap <silent> <leader>r <Plug>NormalModeSendToTmuxMotion
" check currently selected pane
nmap <leader>S <Plug>CheckTmux
```

## Installation
- `Vundle`:
    - In your `.vimrc` place `Plugin 'brauner/vimtux'` between
      `call vundle#begin()` and  `call vundle#end()`. Then open
      `vim` and install with `:PluginInstall`.
- `Pathogen`:
    - use:
    ```{.sh}
    cd ~/.vim/bundle
    git clone https://github.com/brauner/vimtux.git
    ```

This is a simple Vim script to send text, commands and keys from a Vim
buffer to a running tmux session. its main objective is to stay as simple
as possible following the famous KISS principle. This means it does not
rely on the presence of any external files, programming languages
whatsoever and it will stay that way. Forever. Period. It does exactly
what it was designed for no more no less: Send text, commands and keys to
any Tmux session via Vim. You will find the details below.

**Note:** If you use version of tmux ealier than 1.3, you should use the stable
branch. The version available in that branch isn't aware of panes so it
will paste to pane 0 of the window.

(1) vimtux provides the ability to send multiple keys to a tmux target at
once.

(2) The tmux target is set on buffer basis. This means that every tab in
Vim can have its own tmux target. (E.g. you could have a tab in which you
edit a Python script and send text and keys to a Python repl and another
tab in which you edit an R script and send text and keys to an R repl.)

(3) vimtux allows you to refer to panes and windows either via their
dynamic identifier which is a simple number. Or via their unique
identifier. For panes their unique identifier is a number prefixed with
`%` and for windows a number prefixed with `@`.

a) Demonstrative Reference/Dynamic Reference:

· Panes: If you choose to refer to a pane via its dynamic identifier the
target of any given send function in this script will change when you
insert a new pane before the pane you used.

· Windows (slightly more complex to explain): Assume you have set
`set-window-option -g automatic-rename on` in your `~/.tmux.conf`. This is
quite useful when you want to have an easy way of seeing what program is
currently running in any given tmux window. But it is not very useful when
you switch programs in a tmux window a lot but still want to be able to
send commands and keys from the same window or pane to these different
programs. Because refering to the window via its name given to it by the
program currently running will break the connection between the window
running the program and the window you are sending commands and keys from
once that program is exited.

b) Proper Name/Static Reference: If you choose to refer to a pane via its
unique identifier the target of any given send function in this script
will stay fixed.

b) Proper Name/Static Reference: If you choose to refer to a window via
its unique identifier the target of any given send function in this script
will stay fixed while allowing that the program currently running in that
window is setting the name for that session.

Tip: You can find out the unique identifier of a pane by either passing
`tmux list-panes -t x` where `x` is the name of the session. Or (the
easier way) you let the unique identifier of every pane be shown in your
tmux status bar with the option `#D`; e.g.: `set -g status-left '#D'`.
(All possible options about what to display in the statusbar can be found
via `man tmux` or some internet searching.)

I suggest using something like this in your `.tmux.conf`:

\# Status bar.

`set -g status-interval 2`

`set -g status-right '[#D|#P|#T] '`

`set -g status-left '[#{session_id}|#S]'`

`set-option -g status-justify centre`

\# Disable showing the default window list component and trim it to a more
specific format.

`set-window-option -g window-status-current-format '[#F|#{window_id}|#I|#W|#{window_panes}]'`

`set-window-option -g window-status-format '[#F|#{window_id}|#I|#W|#{window_panes}]'`

which gives you: `#{session_id} := unique session ID`, `#S := session
title`, `#F := window flags` (Info about which windows is active etc.),
`#{window_id} := unique window ID`, `#I := window index`, `#W := window
title`, `#{window_panes} := number of active panes in current window`, `#D
:= unique pane number`, `#P := dynamic pane number`, `#T := pane title`,
The characters `[`, `]` and `|` are just used to secure visibility and do
not have any further meaning.

A last hint: If you fancy it you can rename panes. Just issue `printf
'\033]2;%s\033\\' 'hello'` in any pane and observe how `#T` will change.

(For fun: Consider including `#D` and `#P` in your statusbar for a moment
in order to see how tmux changes the dynamic window number for every pane
that comes after the one you just opened and how `#D` stays fixed.)

(4) Keybindings are not set automatically for you. Instead, you can map
whatever you'd like to one of the plugin-specific bindings in your
`.vimrc` file.

## Setting Keybindings

To get the old defaults, put the following in your `.vimrc`:

``` vim
vmap <C-c><C-c> <Plug>SendSelectionToTmux
nmap <C-c><C-c> <Plug>NormalModeSendToTmux
nmap <C-c>r <Plug>SetTmuxVars
```

To send a selection in visual mode to vim, set the following in your `.vimrc`:

``` vim
vmap <your_key_combo> <Plug>SendSelectionToTmux
```

To grab the current method that a cursor is in normal mode, set the following:

``` vim
nmap <your_key_combo> <Plug>NormalModeSendToTmux
```

Use the following to reset the session, window, and pane info:

``` vim
nmap <your_key_combo> <Plug>SetTmuxVars
```

Have a command you run frequently, use this:

``` vim
nmap <your_key_combo> :Tmux <your_command><CR>
```

More info about the `<Plug>` and other mapping syntax can be found
[here](http://vim.wikia.com/wiki/Mapping_keys_in_Vim_-_Tutorial_(Part_3) ).

## Tip

You don't need to be in a `tmux` session in order to send text or keys to
another tmux session. The only requirement is that you are in a `vim`
session. Hence, you can send keys to any `tmux` session from any
(non-`tmux`) `vim` session.
