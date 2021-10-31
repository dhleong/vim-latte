

function! s:MochaRunner() dict
    return latte#runner#javascript#runMocha(self,
                \ ['-r', 'ts-node/register'])
endfunction

function! latte#runner#typescript#Runner()
    if latte#runner#javascript#MochaExecutable() !=# ''
        " TODO other runners?
        return function('s:MochaRunner')
    endif

    return latte#runner#javascript#Runner()
endfunction
