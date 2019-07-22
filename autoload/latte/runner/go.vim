

function! s:GoTestRunner() dict

    let run = latte#util#NewRunState()
    let outputByTest = {}

    " TODO filter results by tests declared
    " in the file we're editing?

    "
    " test runner callbacks
    let callbacks = {}
    function callbacks.run(msg) closure
        let testName = get(a:msg, 'Test', '')
        if testName !=# ''
            let outputByTest[testName] = []
            let run.total = run.total + 1
        endif
    endfunction
    function callbacks.fail(msg) closure
        let testName = get(a:msg, 'Test', '')
        if testName !=# ''
            for line in outputByTest[testName]
                call self.stdout(line)
            endfor
            call run.fail()
            call self.state(run)
        endif
    endfunction
    function callbacks.pass(msg) closure
        if get(a:msg, 'Test', '') !=# ''
            call run.pass()
            call self.state(run)
        endif
    endfunction

    function callbacks.output(msg) closure
        let trimmed = substitute(a:msg.Output, '\n$', '', '')
        let testName = get(a:msg, 'Test', '')
        if testName !=# ''
            " associate output with the specific test
            call add(outputByTest[a:msg.Test], trimmed)
        else
            call self.stdout(trimmed)
        endif
    endfunction

    "
    " job callbacks
    function! OnError(channel, msg) closure
        call self.stderr(a:msg)
    endfunction

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

        if has_key(callbacks, line.Action)
            " just pass along to the callback
            call call(callbacks[line.Action], [line], self)
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
              \ 'err_cb': 'OnError',
              \ 'exit_cb': 'OnExit'}
    let file = expand('%:p')
    return job_start(['go', 'test', '.', '-json'], opts)
endfunction

function! latte#runner#go#Runner()
    return function('s:GoTestRunner')
endfunction

