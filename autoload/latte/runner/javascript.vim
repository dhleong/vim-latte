
function! s:MochaRunner() dict

    let run = latte#util#NewRunState()

    function! OnOutput(channel, msg) closure
        try
            let line = json_decode(a:msg)
        catch
            call self.stdout(a:msg)
            return
        endtry

        let type = line[0]
        let info = line[1]
        if type == 'start'
            let run.total = info.total
        elseif type == 'pass'
            call run.pass()
        elseif type == 'fail'
            call run.fail()

            let regex = self.file . ':\([0-9]*\):\([0-9]*\)'
            let match = matchlist(info.stack, regex)
            let lnum = match[1]
            let col = match[2]
            call self.lineError(lnum, col, info.err, info.stack)
        endif

        call self.state(run)
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
              \ 'exit_cb': 'OnExit'}
    let file = expand('%:p')
    let job = job_start(['mocha', '--reporter=json-stream', file], opts)
endfunction

function! latte#runner#javascript#Runner()
    " TODO other runners?
    return function('s:MochaRunner')
endfunction
