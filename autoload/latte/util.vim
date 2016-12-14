
function! latte#util#NewRunState()
    let state = {
        \ 'total': 0,
        \ 'passed': 0,
        \ 'failed': 0
        \ }

    function state.pass() dict
        let self.passed = self.passed + 1
    endfunction

    function state.fail() dict
        let self.failed = self.failed + 1
    endfunction

    return state
endfunction
