
let s:cwdir = expand("<sfile>:p:h")
let s:pytest_runner = s:cwdir . "/python/pytest-runner.py"

function! s:PyTestRunner() dict

    let run = latte#util#NewRunState()

    "
    " test runner callbacks
    let callbacks = {}
    function callbacks.done(msg) closure
        if a:msg.allPassed
            call self.success()
        else
            if a:msg.extra != ''
                call self.stdout(a:msg.extra)
            endif
            call self.failure()
        endif
    endfunction

    function callbacks.test(msg) closure
        if a:msg.pass
            call run.pass()
        else
            call run.fail()

            call self.lineError(a:msg.line, 1, a:msg.error, a:msg.extra)
        endif

        call self.state(run)
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

        if has_key(callbacks, line.t)
            " just pass along to the callback
            call call(callbacks[line.t], [line], self)
        else
            echom "Unknown callback type " . line.t
        endif
    endfunction

    let opts = {'out_mode': 'nl',
              \ 'out_cb': 'OnOutput',
              \ 'err_cb': 'OnError'}
    let file = expand('%:p')
    let job = job_start(['python', s:pytest_runner, file], opts)
endfunction

function! latte#runner#python#Runner()
    " TODO other runners?
    return function('s:PyTestRunner')
endfunction

