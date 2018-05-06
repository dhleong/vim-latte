
function! s:runnerForId(id)
    let runners = get(g:, 'latte#runners', {})
    if has_key(runners, a:id)
        return runners[a:id]
    endif

    " autodetect based on presence of runner function
    let name = 'latte#runner#' . a:id . '#Runner'
    try
        let Fn = function(name)
        return Fn()
    catch /^Vim\%((\a\+)\)\=:E117/
        " 'Unknown function'
        return 0
    endtry
endfunction

function! latte#runner#Get()
    let ft = &filetype
    let Fn = s:runnerForId(ft)
    if Fn != 0
        return Fn
    endif

    " eg: javascript.jsx
    let dot = stridx(ft, '.')
    if dot != -1
        let altFt = ft[:(dot - 1)]
        let Fn = s:runnerForId(altFt)

        if Fn == 0
            throw 'No runner found for `' . ft . '` or `' . altFt . '`'
        endif

        return Fn
    endif

    throw 'No runner found for `' . ft . '`'
endfunction

