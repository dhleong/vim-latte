
" TODO be configurable:
hi FailBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#bb0000
hi PassBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#00bb00
hi StatBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#333333

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
    let filename = expand('%')

    let callbacks = {'file': filename}

    function callbacks.lineError(line, col, error, extra) closure
        " TODO put extra somewhere?
        call add(locList, {
                \ 'filename': filename,
                \ 'lnum': a:line,
                \ 'col': a:col,
                \ 'text': a:error
                \ })
    endfunction

    function callbacks.state(state)
        let state = a:state
        let finished = state.passed + state.failed
        if finished == state.total
            return
        endif

        let failed = ''
        if state.failed > 0
            let failed = '; FAILED: ' . state.failed
        endif
        let line = printf('Running: %2d / %2d%s', finished, state.total, failed)
        call s:EchoBar('stat', line)
    endfunction

    function callbacks.success()
        echo ""
        lclose

        let msg = "All tests passed!"
        if a:0
            let msg = a:1
        endif

        call s:EchoBar('pass', msg)
    endfunction

    function callbacks.failure() closure
        call setloclist(winnr, locList, 'r')
        " TODO draw markers
        lopen
        call s:EchoBar('fail', locList[0].text)
    endfunction

    return callbacks
endfunction

function! latte#Run()
    let Runner = latte#runner#Get()
    let callbacks = s:CreateCallbacks()
    let callbacks.Run = Runner
    call callbacks.Run()
endfunction
