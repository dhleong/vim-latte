func! latte#util#exe#FindInProject(name)
    let cwd = expand('%:p:h')

    while len(cwd) > 3
        let path = cwd . '/' . a:name
        if executable(path)
            return path
        endif

        let cwd = fnamemodify(cwd, ':h')
    endwhile

    return ''
endfunc
