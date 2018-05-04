
function latte#runner#Get()
    let ft = &filetype
    let runners = get(g:, 'latte#runners', {})
    if has_key(runners, ft)
        return runners[ft]
    endif

    let auto_runner = 'latte#runner#' . ft . '#Runner'
    let Fn = function(auto_runner)
    if Fn == 0
        throw 'No runner found for `' . ft . '`'
    endif

    try
        " NOTE: we have to call it on a separate line like this
        " so vim is happy
        let Result = Fn()
        return Result
    catch /^Vim\%((\a\+)\)\=:E117/
        " 'Unknown function'
        throw 'No runner found for `' . ft . '`'
    endtry
endfunction

