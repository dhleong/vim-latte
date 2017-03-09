
" TODO be configurable:
hi FailBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#bb0000
hi PassBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#00bb00
hi StatBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#333333

let s:config_defaults = {
    \ 'extend_syntastic': 1,
    \ 'jump_to_error': 1,
    \ }

function s:EchoBar(type, msg)
    if a:type == 'fail'
        echohl FailBar
    elseif a:type == 'pass'
        echohl PassBar
    elseif a:type == 'stat'
        echohl StatBar
    endif

    " clear anything old out
    echo ""

    let oldshowcmd = &showcmd
    set noshowcmd
    redraw!
    echon a:msg repeat(" ", &columns - strlen(a:msg) - 1)
    echohl None
    let &showcmd = oldshowcmd
endfunction

function s:CreateCallbacks()
    let locList = []
    let winnr = winnr()
    let bufnr = bufnr('')
    let filename = expand('%')

    let callbacks = {
                \ 'file': filename,
                \ '_hasExited': 0
                \ }

    function callbacks.lineError(line, col, error, extra) closure
        " TODO put `extra` somewhere?
        call add(locList, {
                \ 'filename': filename,
                \ 'bufnr': bufnr,
                \ 'lnum': a:line,
                \ 'col': a:col,
                \ 'text': a:error,
                \ 'valid': 1
                \ })
    endfunction

    function callbacks.state(state)
        let state = a:state
        let finished = state.passed + state.failed
        if self._hasExited
            " re-echo exit status
            if self._exitSuccess
                call self.success()
            else
                call self.failure()
            endif
            return
        endif

        let failed = ''
        if state.failed > 0
            let failed = '; FAILED: ' . state.failed
        endif
        let line = printf('Running: %2d / %2d%s', finished, state.total, failed)
        call s:EchoBar('stat', line)
    endfunction

    function callbacks.stdout(msg)
        " TODO: do something with stdout
    endfunction

    function callbacks.success(...)
        let self._hasExited = 1
        let self._exitSuccess = 1

        echo ""
        lclose

        let msg = "All tests passed!"
        if a:0
            let msg = a:1
        endif

        call s:EchoBar('pass', msg)
    endfunction

    function callbacks.failure() closure
        let self._hasExited = 1
        let self._exitSuccess = 0

        call setloclist(winnr, locList, 'r')
        if latte#Config('extend_syntastic') && exists('g:SyntasticLoclist')
            let list = g:SyntasticLoclist.New(locList)
            let b:latte_last_list = list

            let global = g:SyntasticLoclist.current()
            call global.extend(list)

            call g:SyntasticHighlightingNotifier.refresh(list)
            call g:SyntasticSignsNotifier.refresh(list)
        else
            " TODO draw markers
            lopen
        endif

        if len(locList)
            let firstError = locList[0]
            call s:EchoBar('fail', firstError.text)
            if latte#Config('jump_to_error')
                call setpos('.', [firstError.bufnr, firstError.lnum, firstError.col, 0])
            endif
        else
            " TODO
            call s:EchoBar('fail', 'Error')
        endif

    endfunction

    return callbacks
endfunction

function! latte#Run()
    if exists('b:latte_last_list')
        " cleanup
        call g:SyntasticHighlightingNotifier.reset(b:latte_last_list)
    endif

    let Runner = latte#runner#Get()
    let callbacks = s:CreateCallbacks()
    let callbacks.Run = Runner
    call callbacks.Run()
endfunction

function! latte#Config(configName)
    let prefixed = 'latte_' . a:configName
    return get(b:, prefixed,
        \ get(g:, prefixed, s:config_defaults[a:configName]))
endfunction
