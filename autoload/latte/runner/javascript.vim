
function! latte#runner#javascript#runMochaStream(self, mochaArgs)"{{{
    " Old implementation for mocha-based runners, using json-stream
    " Arguments:
    " - "self" The self implicit var for the parent dict function
    " - "mochaArgs" List of extra args to pass to mocha

    let self = a:self
    let run = latte#util#NewRunState()

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

        let type = line[0]
        let info = line[1]
        if type ==# 'start'
            let run.total = info.total
        elseif type ==# 'pass'
            call run.pass()
        elseif type ==# 'fail'
            call run.fail()

            let regex = self.file . ':\([0-9]*\):\([0-9]*\)'
            let match = matchlist(info.stack, regex)
            if len(match)
                let lnum = match[1]
                let col = match[2]
                call self.lineError(lnum, col, info.err, info.stack)
            else
                call self.stderr(info.fullTitle)
                call self.stderr(repeat('=', len(info.fullTitle)))
                call self.stderr(info.err)
                call self.stderr(' ')
                call self.stderr(info.stack)
            endif
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
              \ 'err_cb': 'OnError',
              \ 'exit_cb': 'OnExit'}
    let file = expand('%:p')
    let job = job_start(
                \ ['mocha'] + a:mochaArgs +
                \ ['--reporter=json-stream', file],
                \ opts)
endfunction"}}}

function s:computeDiff(actual, expected)
    " TODO fancy diff
    return "Expected:\n  " . string(a:expected) .
        \  "\n\nActual:\n  " . string(a:actual)
endfunction

function! latte#runner#javascript#runMocha(self, mochaArgs)
    " New, shared implementation for mocha-based runners,
    " using json reporter to support diffing
    " Arguments:
    " - "self" The self implicit var for the parent dict function
    " - "mochaArgs" List of extra args to pass to mocha

    let self = a:self
    let run = latte#util#NewRunState()

    let output = ''

    function! OnError(channel, msg) closure
        call self.stderr(a:msg)
    endfunction

    function! OnOutput(channel, msg) closure
        let output = output . a:msg
    endfunction

    function! OnResult(msg) closure
        let stats = a:msg.stats
        let failures = a:msg.failures

        let run.total = stats.tests
        let run.passed = stats.passes
        let run.failed = stats.failures

        for info in failures
            let regex = self.file . ':\([0-9]*\):\([0-9]*\)'
            let match = matchlist(info.err.stack, regex)
            if len(match)
                let lnum = match[1]
                let col = match[2]
                let diff = ''

                if get(info.err, 'showDiff', 0)
                    let diff = "\n\n" . s:computeDiff(info.err.actual, info.err.expected)
                endif

                call self.lineError(lnum, col, info.err.message, info.err.stack . diff)
            else
                call self.stderr(info.fullTitle)
                call self.stderr(repeat('=', len(info.fullTitle)))
                call self.stderr(info.err.message)
                call self.stderr(' ')
                call self.stderr(info.err.stack)
            endif
        endfor

        call self.state(run)
    endfunction

    function! OnExit(channel, exitCode) closure
        try
            let json = json_decode(output)

            if type(json) == v:t_none
                call self.stdout(output)
            else
                call OnResult(json)
            endif
        catch
            echom "ERROR decoding" . v:exception . ' @' . v:throwpoint
            call self.stdout(output)
        endtry

        if a:exitCode == 0
            call self.success()
        else
            call self.failure()
        endif
    endfunction

    " NOTE using mode js or json doesn't seem to ever
    " call OnOutput... sadly
    let opts = {'out_mode': 'raw',
              \ 'out_cb': 'OnOutput',
              \ 'err_cb': 'OnError',
              \ 'exit_cb': 'OnExit'}
    let file = expand('%:p')
    let job = job_start(
                \ ['mocha'] + a:mochaArgs +
                \ ['--reporter=json', file],
                \ opts)
endfunction

function! s:MochaRunner() dict
    return latte#runner#javascript#runMocha(self, [])
endfunction

function! latte#runner#javascript#Runner()
    " TODO other runners?
    return function('s:MochaRunner')
endfunction
