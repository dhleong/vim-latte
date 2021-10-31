func! latte#runner#javascript#JestExecutable() " {{{
    return latte#util#exe#FindInProject('node_modules/.bin/jest')
endfunc " }}}

func! latte#runner#javascript#MochaExecutable() " {{{
    return latte#util#exe#FindInProject('node_modules/.bin/mocha')
endfunc " }}}

func! s:JestRunner() dict
    return latte#runner#javascript#jest#Run(self, [])
endfunc

func! s:MochaRunner() dict
    return latte#runner#javascript#mocha#Run(self, [])
endfunc

func! latte#runner#javascript#Runner()
    if latte#runner#javascript#JestExecutable() !=# ''
        return function('s:JestRunner')
    endif

    if latte#runner#javascript#MochaExecutable() !=# ''
        return function('s:MochaRunner')
    endif

    echom 'No runners available'
endfunc
