" Author: w0rp <devw0rp@gmail.com>
" Description: APIs for working with asynchronous sockets, with an API
" normalised between Vim 8 and NeoVim. Socket connections only work in NeoVim
" 0.3+, and silently do nothing in earlier NeoVim versions.

let s:channel_map = get(s:, 'channel_map', {})

function! s:VimOutputCallback(channel, data) abort
    let l:channel_id = ch_info(a:channel).id

    " Only call the callbacks for jobs which are valid.
    if l:channel_id > 0 && has_key(s:channel_map, l:channel_id)
        call ale#util#GetFunction(s:channel_map[l:channel_id].callback)(l:channel_id, a:data)
    endif
endfunction

function! s:NeoVimOutputCallback(channel_id, data, event) abort
    let l:info = s:channel_map[a:channel_id]

    " TODO: Check a:event. What are the values?
    let l:info.last_line = ale#util#JoinNeovimOutput(
    \   a:channel_id,
    \   l:info.last_line,
    \   a:data,
    \   l:info.mode,
    \   ale#util#GetFunction(l:info.out_cb),
    \)
endfunction

" TODO: Close callback?
"
" Open a socket for a given address. The following options are accepted:
"
" callback - A callback for receiving input. (required)
"
" A channel ID will be returned if the socket is opened.
function! ale#socket#Open(address, options) abort
    let l:mode = get(a:options, 'mode', 'raw')
    let l:Callback = a:options.callback

    let l:channel_info = {
    \   'mode': l:mode,
    \   'callback': a:options.callback,
    \}

    if !has('nvim')
        " Vim
        let l:channel_info.channel = ch_open(a:address, {
        \   'mode': l:mode,
        \   'waittime': 0,
        \   'callback': function('s:VimOutputCallback'),
        \})
        let l:vim_info = ch_info(l:channel_info.channel)
        let l:channel_id = !empty(l:vim_info) ? l:vim_info.id : 0
    elseif exists('*chansend') && exists('*sockconnect')
        " NeoVim 0.3+
        try
            let l:channel_id = sockconnect('tcp', a:address, {
            \   'on_data': function('s:NeoVimOutputCallback'),
            \})
        catch /connection failed/
            let l:channel_id = 0
        endtry

        let l:channel_info.channel = l:channel_id
    else
        " Other Vim versions.
        let l:channel_id = 0
    endif

    if l:channel_id > 0
        let s:channel_map[l:channel_id] = l:channel_info
    endif

    return l:channel_id
endfunction

function! ale#socket#Send(channel_id, data) abort
    if !has_key(s:channel_map, a:channel_id)
        return
    endif

    let l:channel = s:channel_map[a:channel_id].channel

    if has('nvim')
        call chansend(l:channel, a:data)
    else
        call ch_sendraw(l:channel, a:data)
    endif
endfunction

function! ale#socket#Close(channel_id) abort
    if !has_key(s:channel_map, a:channel_id)
        return
    endif

    let l:channel = remove(s:channel_map, a:channel_id).channel

    if has('nvim')
        silent! call chanclose(l:channel)
    else
        if ch_status(l:channel) is# 'open'
            call ch_close(l:channel)
        endif
    endif
endfunction
