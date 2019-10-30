
" TODO be configurable:
hi FailBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#bb0000
hi PassBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#00bb00
hi StatBar term=reverse ctermfg=white ctermbg=green guifg=#f0f0f0 guibg=#333333

let s:config_defaults = {
    \ 'extend_ale': 1,
    \ 'extend_syntastic': 1,
    \ 'list_open': 0,
    \ 'jump_to_error': 1,
    \ }

function! s:EchoBar(type, msg) " {{{
    if a:type ==# 'fail'
        echohl FailBar
    elseif a:type ==# 'pass'
        echohl PassBar
    elseif a:type ==# 'stat'
        echohl StatBar
    endif

    " clear anything old out
    echo ''

    let message = a:msg
    if len(message) >= &columns - 1
        " take the *last* text since that seems to be the most likely place
        " for relevant messages (maybe not always though...?)
        let start = len(message) - &columns - 2
        let message = message[start :]
    else
        let message = message . repeat(' ', &columns - strlen(message) - 1)
    endif

    let oldshowcmd = &showcmd
    set noshowcmd
    redraw!
    echom message
    echohl None
    let &showcmd = oldshowcmd
endfunction " }}}

function! s:CreateCallbacks() " {{{
    let locList = []
    let winnr = winnr()
    let tabnr = tabpagenr()
    let bufnr = bufnr('')
    let filename = expand('%')
    let errorsByLine = {}
    let stdout = []

    let callbacks = {
                \ 'file': filename,
                \ '_hasExited': 0
                \ }

    function callbacks.lineError(line, col, error, extra, ...) closure
        " Optional Param:
        " - "printErrorWithExtra" (default: True)

        let printErrorWithExtra = a:0 && a:1

        if !has_key(errorsByLine, a:line)
            let errorsByLine[a:line] = []
        endif

        call add(errorsByLine[a:line], {
                \ 'text': a:error,
                \ 'extra': a:extra})

        if len(a:extra)
            if printErrorWithExtra
                call add(stdout, a:error)
            endif

            call add(stdout, a:extra)
        endif

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

    function callbacks.stderr(msg) closure
        " TODO distinguish stderr and stdout
        if len(a:msg)
            echom 'latte: ' . a:msg
            call add(stdout, a:msg)
        endif
    endfunction

    function callbacks.stdout(msg) closure
        if len(a:msg)
            echom 'latte: ' . a:msg
            call add(stdout, a:msg)
        endif
    endfunction

    function callbacks.success(...) closure
        let self._hasExited = 1
        let self._exitSuccess = 1

        echo ''
        lclose
        pclose

        let msg = 'All tests passed!'
        if a:0
            let msg = a:1
        endif

        let inSameTab = tabpagenr() == tabnr
        if inSameTab
            call setbufvar(bufnr, 'latte_ran', 1)
        endif

        call s:EchoBar('pass', msg)
    endfunction

    function callbacks.failure() closure
        let self._hasExited = 1
        let self._exitSuccess = 0
        let inSameWindow = winnr() == winnr
        let inSameTab = tabpagenr() == tabnr

        if inSameTab
            call setbufvar(bufnr, 'latte_ran', 1)
        endif

        call setloclist(winnr, locList, 'r')
        if latte#Config('extend_syntastic') && exists('g:SyntasticLoclist') && inSameWindow
            let list = g:SyntasticLoclist.New(locList)
            let b:latte_last_list = list

            let global = g:SyntasticLoclist.current()
            call global.extend(list)

            call g:SyntasticHighlightingNotifier.refresh(list)
            call g:SyntasticSignsNotifier.refresh(list)
        else
            " TODO draw markers
            if latte#Config('list_open')
                lopen
            endif
        endif

        if len(stdout) && inSameTab
            " join it all into a string now to avoid
            " lots of concatenations, but also handle
            " newlines in output correctly
            let output = join(stdout, "\n")
            call latte#util#Preview('Test run output', output)
        elseif inSameTab
            pclose
        endif

        if len(locList) && inSameWindow
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
endfunction " }}}

function! latte#Run() " {{{
    if exists('b:latte_last_list')
        " cleanup
        call g:SyntasticHighlightingNotifier.reset(b:latte_last_list)
    endif

    let Runner = latte#runner#Get()
    let callbacks = s:CreateCallbacks()
    let callbacks.Run = Runner

    call s:EchoBar('stat', 'latte: Running test...')

    call callbacks.Run()
endfunction " }}}

" Looks for a test file on the current tabpage and tries to call latte#Run()
" in it
function! latte#TryRun() " {{{
    let sourceWin = winnr()
    for nr in range(1, winnr('$'))
        if nr == sourceWin
            " don't TryRun in the current window; that's what Run is for
            continue
        endif

        let bufnr = winbufnr(nr)
        if bufnr != -1 && getbufvar(bufnr, 'latte_ran', 0)
            " re-run
            exe nr . 'wincmd w'

            " start
            call latte#Run()

            " restore active window
            exe sourceWin . 'wincmd w'

            " done!
            return
        endif
    endfor
endfunc " }}}

function! latte#Config(configName) " {{{
    let prefixed = 'latte_' . a:configName
    return get(b:, prefixed,
        \ get(g:, prefixed, s:config_defaults[a:configName]))
endfunction " }}}
