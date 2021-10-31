func! latte#runner#javascript#jest#Run(self, jestArgs)
    let jest = latte#runner#javascript#JestExecutable()
    if jest ==# ''
        redraw!
        echo 'latte: No jest executable found'
        return
    endif

    let self = a:self
    let run = latte#util#NewRunState()

    func! OnError(channel, msg) closure
        call self.stderr(a:msg)
    endfunc

    func! OnOutput(channel, result) closure
        call self.stdout(string(a:result))
        call self.state(run)
    endfunc

    func! OnExit(channel, exitCode) closure
        if a:exitCode == 0 && run.failed == 0
            call self.success()
        else
            call self.failure()
        endif
    endfunc

    " Get the project directory in which node_modules/.bin/jest lives:
    let jestParent = fnamemodify(jest, ':h:h:h')

    let opts = {'out_mode': 'json',
              \ 'out_cb': 'OnOutput',
              \ 'err_cb': 'OnError',
              \ 'exit_cb': 'OnExit',
              \ 'cwd': jestParent,
              \ }
    let file = expand('%:p')
    let job = job_start(
                \ [jest] + a:jestArgs +
                \ ['--runTestsByPath', file],
                \ opts)
endfunc
