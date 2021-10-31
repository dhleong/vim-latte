let s:cwdir = expand('<sfile>:p:h')
let s:mocha_runner = s:cwdir . '/mocha-runner.js'

func! s:cleanStack(stack)
    let result = substitute(a:stack, '[ ]*at Proxy\..*/chai/.*\n', '', 'g')
    let result = substitute(result, '[ ]*at <anonymous>$', '', 'g')
    return trim(result)
endfunc

func s:string(v)
    if type(a:v) ==# type('')
        return a:v
    endif

    return string(a:v)
endfunc

func s:computeDiff(actual, expected)
    " TODO fancy diff
    let expectedAsString = s:string(a:expected)
    let actualAsString = s:string(a:actual)

    if count(expectedAsString, "\n") > 0
        return "Expected:\n" . expectedAsString
            \. "\n\nActual:\n" . actualAsString
    endif

    return "Expected:\n  " . expectedAsString
        \. "\n\nActual:\n  " . actualAsString
endfunc

func! latte#runner#javascript#mocha#Run(self, mochaArgs) " {{{
    " Old implementation for mocha-based runners, using json-stream
    " Arguments:
    " - "self" The self implicit var for the parent dict function
    " - "mochaArgs" List of extra args to pass to mocha

    let mocha = latte#runner#javascript#MochaExecutable()
    if mocha ==# ''
        redraw!
        echo 'latte: No mocha executable found'
        return
    endif

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
            " call self.stdout(a:msg)
            return
        elseif type(line) != type([])
            call self.stdout(string(a:msg))
            return
        elseif len(line) < 2
            call self.stdout(string(a:msg))
            return
        endif

        let type = line[0]
        let info = line[1]
        if type ==# 'start'
            let run.total = info.total
        elseif type ==# 'pass'
            call run.pass()
        elseif type ==# 'end'
            " just nop
        elseif type ==# 'fail'
            call run.fail()

            let regex = self.file . ':\([0-9]*\):\([0-9]*\)'
            let match = matchlist(info.stack, regex)
            if len(match)
                let lnum = match[1]
                let col = match[2]
                let diff = ''

                if get(info, 'showDiff', 0) && has_key(info, 'actual') && has_key(info, 'expected')
                    let diff = "\n\n" . s:computeDiff(info.actual, info.expected)
                endif

                call self.lineError(lnum, col, info.err, s:cleanStack(info.stack) . diff)
            else
                call self.stderr(info.fullTitle)
                call self.stderr(repeat('=', len(info.fullTitle)))
                call self.stderr(info.err)
                call self.stderr(' ')

                if has_key(info, 'actual') && has_key(info, 'expected')
                    call self.stderr(s:computeDiff(info.actual, info.expected))
                    call self.stderr(' ')
                endif

                call self.stderr(s:cleanStack(info.stack))
            endif
        else
            call self.stdout(string(line))
        endif

        call self.state(run)
    endfunction

    function! OnExit(channel, exitCode) closure
        if a:exitCode == 0 && run.failed == 0
            call self.success()
        else
            call self.failure()
        endif
    endfunction

    let opts = {'out_mode': 'nl',
              \ 'out_cb': 'OnOutput',
              \ 'err_cb': 'OnError',
              \ 'exit_cb': 'OnExit'}

    let debug = get(b:, 'DEBUG', '')
    if debug !=# ''
        let opts.env = {'DEBUG': debug}
    endif

    let file = expand('%:p')
    let job = job_start(
                \ [mocha] + a:mochaArgs +
                \ ['--reporter=' . s:mocha_runner, file],
                \ opts)
endfunc " }}}
