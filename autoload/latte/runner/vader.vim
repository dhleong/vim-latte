function! s:findProjectRoot()
    let dir = expand('%:p')
    while 1
        let next = fnamemodify(dir, ':h')
        if next ==# dir
            " got to root and found nothing
            return ''
        endif

        if isdirectory(next . '/plugin') || isdirectory(next . '/autoload')
            return next
        endif

        let dir = next
    endwhile
endfunction

function! s:VaderTestRunner() dict
    let run = latte#util#NewRunState()

    "
    " job callbacks
    function! OnError(channel, msg) closure
        call self.stderr(a:msg)
    endfunction

    function! OnExit(channel, exitCode) closure
        if a:exitCode == 0
            call self.success()
        else
            call self.failure()
        endif
    endfunction

    let vaderPath = '~/.vim/bundle/vader.vim' " FIXME

    let opts = {'err_cb': 'OnError',
              \ 'exit_cb': 'OnExit'}
    let file = expand('%:p')

    let projectRoot = s:findProjectRoot()

    return job_start([
        \ 'vim', '-esNu', 'NORC',
        \ '--cmd', 'set rtp+=' . vaderPath,
        \ '--cmd', 'set rtp+=' . projectRoot,
        \ '-c', 'Vader! -q ' . file,
        \ ],
        \ opts)
endfunction

function! latte#runner#vader#Runner()
    return function('s:VaderTestRunner')
endfunction

