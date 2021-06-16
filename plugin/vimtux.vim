" File: vimtux.vim
" Code by: C. Brauner <christianvanbrauner [at] gmail [dot] com>,
"          C. Coutinho <kikijump [at] gmail [dot] com>,
"          K. Borges <kassioborges [at] gmail [dot] com>
" Maintainer: C. Brauner <christianvanbrauner [at] gmail [dot] com>,

if exists("g:loaded_vimtux") && g:loaded_vimtux
    finish
endif

let g:loaded_vimtux = 1

" Send keys to tmux.
function! ExecuteKeys(keys)
    if !exists("b:vimtux")
        if exists("g:vimtux")
            " This bit sets the target on buffer basis so every tab can have its
            " own target.
            let b:vimtux = g:vimtux
        else
            call <SID>TmuxVars()
        end
    end
    call system("tmux send-keys -t " . s:TmuxTarget() . " " . a:keys)
endfunction

function! SendKeysToTmux(keys)
    for k in split(a:keys, '\s')
        call <SID>ExecuteKeys(k)
    endfor
endfunction

" Function to send a key that asks for user input.
function! ExecuteKeysPrompt()
    call inputsave()
    let  l:command = input("Enter Keycode: ")
    call inputrestore()
    call ExecuteKeys(l:command)
endfunction

" Function to send text that asks for user input.
function! SendToTmuxPrompt()
    call inputsave()
    let  l:text = input("Enter Text: ")
    if empty(l:text)
        return
    endif
    call inputrestore()
    call SendToTmux(l:text)
    call ExecuteKeys("Enter")
endfunction


" Main function.
function! SendToTmux(text)
    if !exists("b:vimtux")
        if exists("g:vimtux")
            " This bit sets the target on buffer basis so every tab can have its
            " own target.
            let b:vimtux = g:vimtux
        else
            call <SID>TmuxVars()
        end
    end
    let oldbuffer = system(shellescape("tmux show-buffer"))
    call <SID>SetTmuxBuffer(a:text)
    call system("tmux paste-buffer -t " . s:TmuxTarget())
    call <SID>SetTmuxBuffer(oldbuffer)
endfunction

" Setting the target.
function! s:TmuxTarget()
    if len(b:vimtux['pane']) == 1
    return '"' . b:vimtux['session'] . '":' . b:vimtux['window'] . "." . b:vimtux['pane']
else 
    return b:vimtux['pane']
end
endfunction

function! s:SetTmuxBuffer(text)
    let  buf = substitute(a:text, "'", "\\'", 'g')
    call system("tmux load-buffer -", buf)
endfunction

" Session completion.
function! TmuxSessionNames(A,L,P)
    return <SID>TmuxSessions()
endfunction

" Window completion.
function! TmuxWindowNames(A,L,P)
    return <SID>TmuxWindows()
endfunction

" Pane completion.
function! TmuxPaneNumbers(A,L,P)
    return <SID>TmuxPanes()
endfunction

function! s:TmuxSessions()
    let sessions = system("tmux list-sessions | sed -e 's/:.*$//'")
    return sessions
endfunction

" To set the TmuxTarget globally rather than locally substitute 'g:' for all
" instances of 'b:' below and delete the 'if exists("g:vimtux") let b:vimtux =
" g:vimtux' condition in the definition of the 'SendToTmux(text)' function
" above.
function! s:TmuxWindows()
    return system('tmux list-windows -t "' . s:vimtux['session'] . '" | grep -e "^\w:" | sed -e "s/\s*([0-9].*//g"')
endfunction

function! s:TmuxPanes()
    return system('tmux list-panes -t "' . s:vimtux['session'] . '":' . s:vimtux['window'] . " | sed -e 's/:.*$//'")
endfunction

" check session/window/pane name
function! s:CheckName(what, names)
    let checkname = 0
    for name in a:names
        if name == s:vimtux[a:what]
            let checkname += 1
        endif
    endfor
    if checkname == 0
        redraw
        echohl WarningMsg | echomsg a:what . ' ' . s:vimtux[a:what] . ' does not exist!' | echohl None
    endif
    return checkname
endfunction


" Set variables for TmuxTarget().
function! s:TmuxVars()
    let s:vimtux = {}
    if exists('b:vimtux') == 0
        let b:vimtux = {}
    endif

    let names = split(s:TmuxSessions(), "\n")
    if len(names) == 1
        if stridx(names[0], 'no server running') == -1
            let s:vimtux['session'] = names[0]
        else
            echohl WarningMsg | echomsg names[0] | echohl None
            return b:vimtux
        endif
    else
        let s:vimtux['session'] = ''
    endif
    while empty(s:vimtux['session'])
        call inputsave()
        let s:vimtux['session'] = input("session name: ", "", "custom,TmuxSessionNames")
        call inputrestore()
        if s:CheckName('session', names) == 0
            let s:vimtux['session'] = ''
            echo 'sessions running:'
            for name in names
                echohl Identifier | echo name | echohl None
            endfor
        endif
    endwhile

    let windows = split(s:TmuxWindows(), "\n")
    if len(windows) == 1
        let window = windows[0]
    else
        call inputsave()
        let window = input("window name: ", "", "custom,TmuxWindowNames")
        call inputrestore()
        if empty(window)
            let window = windows[0]
        endif
    endif

    let s:vimtux['window'] =  substitute(window, ":.*$" , '', 'g')

    let panes = split(s:TmuxPanes(), "\n")
    if len(panes) == 1
        let s:vimtux['pane'] = panes[0]
    else
        let s:vimtux['pane'] = input("pane number: ", "", "custom,TmuxPaneNumbers")
        if empty(s:vimtux['pane'])
            let s:vimtux['pane'] = panes[0]
        endif
    endif

    let b:vimtux = s:vimtux
    call CheckTmuxTarget()
endfunction

" Set variables for TmuxTarget() by using a popup_menu
function! s:TmuxPopup()
    let s:vimtux = {}
    let s:tmuxsessions = split(s:TmuxSessions(), "\n")
    if len(s:tmuxsessions) == 1
        call s:CbSession(1)
    else
        let Session = {id, index -> s:CbSession(index)}
        call popup_menu(s:tmuxsessions, #{callback: Session, title: 'session name:', })
    endif
endfunction

" Callback function when selecting session name
function! s:CbSession(index)
    let s:vimtux['session'] = s:tmuxsessions[a:index - 1]
    let s:sessionwindows = split(s:TmuxWindows(), "\n")
    if len(s:sessionwindows) == 1
        call s:CbWindow(1)
    else
        let Window = {id, index -> s:CbWindow(index)}
        call popup_menu(s:sessionwindows, #{callback: Window, title: 'window name:', })
    endif
endfunction

" Callback function when selecting window name
function! s:CbWindow(index)
    let s:vimtux['window'] = substitute(s:sessionwindows[a:index - 1], ":.*$", '', 'g')
    let s:windowpanes = split(s:TmuxPanes(), "\n")
    if len(s:windowpanes) == 1
        call s:CbPane(1)
    else
        let Pane = {id, index -> s:CbPane(index)}
        call popup_menu(s:windowpanes, #{callback: Pane, title: 'pane number:', })
    endif
endfunction

" Callback function when selecting pane number
function! s:CbPane(index)
    let s:vimtux['pane'] = s:windowpanes[a:index - 1]
    let b:vimtux = s:vimtux
    call CheckTmuxTarget()
endfunction

" check current target
function! CheckTmuxTarget()
    if exists('b:vimtux') && empty(b:vimtux) == 0
        redraw
        echohl None | echon 'sending to session:' |
                    \ echohl Identifier | echon b:vimtux['session'] |
                    \ echohl None | echon ' window:' |
                    \ echohl Identifier | echon b:vimtux['window'] |
                    \ echohl None | echon ' pane:' |
                    \ echohl Identifier | echon b:vimtux['pane'] |
                    \ echohl None 
    else
        echomsg 'no tmux target defined'
    endif
endfunction

" fzf session selection
function! s:TmuxFZF()
    let s:tmuxsessions = split(s:TmuxSessions(), "\n")
    if len(s:tmuxsessions) == 1
        call s:CbSessionFZF(s:tmuxsessions[0])
    else
        call fzf#run({'sink': 'WindowCmd', 'source': s:tmuxsessions, 'options': ['--header=session name:', '--cycle']})
    endif
endfunction

" fzf window selection
function! s:CbSessionFZF(session)
    let s:vimtux = {}
    let s:vimtux['session'] = a:session
    let s:sessionwindows = split(s:TmuxWindows(), "\n")
    if len(s:sessionwindows) == 1
        call s:CbWindowFZF(s:sessionwindows[0])
    else
        call fzf#run({'sink': 'PaneCmd', 'source': s:sessionwindows, 'options': ['--header=window name:', '--cycle']})
    endif
endfunction

" fzf pane selection
function! s:CbWindowFZF(window)
    let s:vimtux['window'] = substitute(a:window, ":.*$", '', 'g')
    let s:windowpanes = split(s:TmuxPanes(), "\n")
    if len(s:windowpanes) == 1
        call s:CbPaneFZF(s:windowpanes[0])
    else
        call fzf#run({'sink': 'WriteToVimtux', 'source': s:windowpanes, 'options': ['--header=pane number:', '--cycle']})
    endif
endfunction

function! s:CbPaneFZF(pane)
    let s:vimtux['pane'] = a:pane
    let b:vimtux = s:vimtux
    call CheckTmuxTarget()
endfunction

command! -nargs=1 -buffer WindowCmd call s:CbSessionFZF(<f-args>)
command! -nargs=1 -buffer PaneCmd call s:CbWindowFZF(<f-args>)
command! -nargs=1 -buffer WriteToVimtux call s:CbPaneFZF(<f-args>)

" Send to tmux with motion pending
function! s:SendToTmuxMotion(type)
  if a:type == 'line'
    let lines = { 'start': line("'["), 'end': line("']") }
    silent exe lines.start . "," . lines.end . "y"
    silent exe "normal! `]j0"
    " silent exe "normal! `]j0zz"
    call SendToTmux(@")
  else
    silent exe "normal! `[v`]y`]l"
    " silent exe "normal! `[v`]y`]lzz"
    call SendToTmux(@")
    call ExecuteKeys('Enter')
  endif
endfunction

" <Plug> definition for SendToTmux().
vmap <unique> <Plug>SendSelectionToTmux y :call SendToTmux(@")<CR>

" <Plug> definition for SendSelectionToTmu().
nmap <unique> <Plug>NormalModeSendToTmux V <Plug>SendSelectionToTmux

" <Plug> definition for SetTmuxVars().
if exists("g:vimtux_fzf") && g:vimtux_fzf && g:loaded_fzf_vim
    nmap <unique> <Plug>SetTmuxVars :call <SID>TmuxFZF()<CR>
elseif exists('*popup_menu') && exists("g:vimtux_popup") && g:vimtux_popup
    nmap <unique> <Plug>SetTmuxVars :call <SID>TmuxPopup()<CR>
else
    nmap <unique> <Plug>SetTmuxVars :call <SID>TmuxVars()<CR>
endif

" <Plug> definition for "C-c" shortcut.
nmap <unique> <Plug>ExecuteKeysCc :call ExecuteKeys("c-c")<CR>

" <Plug> definition for "C-l" shortcut.
nmap <unique> <Plug>ExecuteKeysCv :call ExecuteKeys("c-l")<CR>

" <Plug> definition for "C-l" shortcut in bash vi editing mode.
nmap <unique> <Plug>ExecuteKeysCl :call ExecuteKeys("c-[ c-l i")<CR>


" <Plug> definition for ExecuteKeysPrompt().
nmap <unique> <Plug>ExecuteKeysPlug :call ExecuteKeysPrompt()<CR>

" <Plug> definition for SendToTmuxPrompt().
nmap <unique> <Plug>SendToTmuxPlug :call SendToTmuxPrompt()<CR>

command! -nargs=* Tmux call SendToTmux('<Args><CR>')

" <Plug> definition for CheckTmuxTarget().
nmap <unique> <Plug>CheckTmux :call CheckTmuxTarget()<CR>

" <Plug> definition for SendToTmuxMotion opfunc.
nmap <unique> <Plug>NormalModeSendToTmuxMotion :set opfunc=<SID>SendToTmuxMotion<CR>g@

" " One possible way to map keys in .vimrc.
" " vimtux.vim variables.
" " Key definition for SendToTmux() <Plug>.
" vmap <Space><Space> <Plug>SendSelectionToTmux
" 
" " Key definition for SendSelectionToTmux() <Plug>.
" nmap <Space><Space> <Plug>NormalModeSendToTmux
" 
" " Key definition for SetTmuxVars() <Plug>
" nmap <Space>r <Plug>SetTmuxVars
" 
" " Key definition for "C-c" shortcut.
" nmap <C-c> <Plug>ExecuteKeysCc
" 
" " Key definition for "C-l" shortcut in bash vi editing mode.
" nmap <C-l> <Plug>ExecuteKeysCl
" 
" " Key definition for "C-l" shortcut.
" nmap <C-x> <Plug>ExecuteKeysCv
" 
" " Key definition for ExecuteKeysPrompt() <Plug>.
" nmap <Leader>sk <Plug>ExecuteKeysPlug
" 
" " Key definition for SendToTmuxPrompt() <Plug>.
" nmap <Leader>sp <Plug>SendTextToTmuxPlug
" 
" " Key definition for ExecuteKeysPrompt() <Plug>.
" nmap <Leader>sk <Plug>ExecuteKeysPlug
" 
" " Key definition for SendToTmuxPrompt() <Plug>.
" nmap <Leader>sp <Plug>SendToTmuxPlug

" TODO 
" Make popup nvim compatible
" Make NormalModeSendToTmuxMotion vim-repeat compatible (atm vim-repeat is too greedy)
" Add option to select tmux server
