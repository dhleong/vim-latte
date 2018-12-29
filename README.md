vim-latte
=========

*A pleasant companion for unit testing*

## What

vim-latte is an asynchronous unit test runner for Vim. It is designed to keep you
get out of your way when everything is fine, and do the helpful things you'd expect
when it isn't.

If all the tests for a file pass, vim-latte will echo a nice "All tests passed"
message in green in your status line. If there were errors, vim-latte will fill
the location list with the locations, hop to the first one, and open a preview
window with any relevant output.

Currently, vim-latte has support for:

- Go ([go test](https://golang.org/cmd/go/#hdr-Test_packages))
- Javascript ([mocha](https://mochajs.org/))
- Python ([py.test](http://pytest.org))
- Typescript ([mocha](https://mochajs.org/))

## How

Install with your favorite plugin manager. I like [Plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'dhleong/vim-latte'
```

Then, just invoke using `:call latte#Run()`.

vim-latte doesn't provide any mappings or autocmds by default, because everybody
does things differently. Here's my autocmd for javascript (in an ftplugin):

```vim
if expand('%') =~# '-test.js$'
    augroup RunLatte
        autocmd!
        autocmd BufWritePost <buffer> :call latte#Run()
    augroup END
else
    augroup TryRunLatte
        autocmd!
        autocmd BufWritePost <buffer> :call latte#TryRun()
    augroup END
endif
```

This will automatically run the test whenever I save the test file. The
`latte#TryRun()` function will try to find a previously-executed test window
in the current tabpage and run that, so I can see the results of changes to
a relevant file as soon as I save it.
