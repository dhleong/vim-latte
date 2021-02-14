function! s:RustTestRunner() dict

    let run = latte#util#NewRunState()

    let file = expand('%:p:r') " NOTE: removing the .rs extension
    let srcIndex = stridx(file, '/src')
    if srcIndex < 0
        echom "Couldn't determine crate root"
        return
    endif

    let projectRoot = file[0:srcIndex]

    " filter results by tests declared in the file we're editing
    let cratePath = split(file[srcIndex + 4:], '/')
    if len(cratePath) && cratePath[-1] ==# 'mod'
        let cratePath = cratePath[:-2]
    endif

    let pathFilter = [ join(cratePath, '::') ]

    "
    " test runner callbacks
    let callbacks = {}
    function callbacks.started(msg) closure
        let testName = get(a:msg, 'name', '')
        if testName ==# ''
            return
        endif
        let run.total = run.total + 1
    endfunction
    function callbacks.failed(msg) closure
        let testName = get(a:msg, 'name', '')
        if testName !=# ''
            call self.stdout(a:msg.stdout)
            call run.fail()
            call self.state(run)
        endif
    endfunction
    function callbacks.ok(msg) closure
        if get(a:msg, 'name', '') !=# ''
            call run.pass()
            call self.state(run)
        endif
    endfunction

    "
    " job callbacks
    function! OnOutput(channel, msg) closure
        try
            let line = json_decode(a:msg)
        catch
            call self.stdout(a:msg)
            return
        endtry

        if type(line) == v:t_none
            call self.stdout(a:msg)
            return
        endif

        if line.type !=# 'test'
            " ignore?
            return
        endif

        if has_key(callbacks, line.event)
            " just pass along to the callback
            call call(callbacks[line.event], [line], self)
        endif
    endfunction

    function! OnExit(channel, exitCode) closure
        if a:exitCode == 0
            call self.success()
        else
            call self.failure()
        endif
    endfunction

    let opts = {'out_mode': 'nl',
              \ 'out_cb': 'OnOutput',
              \ 'exit_cb': 'OnExit',
              \ 'env': {
              \     'RUST_BACKTRACE': 1,
              \ },
              \ 'cwd': projectRoot}
    return job_start([
        \ 'cargo', 'test',
        \ ] + pathFilter + [
        \ '--',
        \ '-Z', 'unstable-options',
        \ '--format', 'json',
        \ ], opts)
endfunction

function! latte#runner#rust#Runner()
    return function('s:RustTestRunner')
endfunction


