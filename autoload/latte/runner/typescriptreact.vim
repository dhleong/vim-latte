

function! s:MochaRunner() dict
    return latte#runner#javascript#runMocha(self,
                \ ['-r', 'ts-node/register'])
endfunction

function! latte#runner#typescriptreact#Runner()
    " TODO other runners?
    return function('s:MochaRunner')
endfunction

