
function! latte#util#Preview(name, contents) " {{{
    " Show a preview window with the given name and contents
    " Arguments:
    "  - "name" The name of the window
    "  - "contents" A string or array of strings

    let contents = a:contents
    let name = substitute(a:name, ' ', '\\ ', 'g')
    exe 'pedit +:call\ s:FillWindow(contents) ' . name
endfunction " }}}

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

function! s:FillWindow(contents) " {{{

    setlocal modifiable

    " prepare contents
    let contents = a:contents

    if type(contents) == type('')
        " convert to an array, safely
        let asStr = contents
        unlet contents
        let contents = split(asStr, '\n')
    endif
    call append(0, contents)
    retab
    call cursor(1, 1)

    setlocal wrap
    setlocal nomodified
    setlocal nomodifiable
    setlocal readonly
    setlocal nolist
    setlocal noswapfile
    setlocal nobuflisted
    setlocal buftype=nofile
    setlocal bufhidden=wipe

    nnoremap <buffer> <silent> q :q<cr>
endfunction " }}}
