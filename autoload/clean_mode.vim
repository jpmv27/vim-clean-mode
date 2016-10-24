" Clean-up distractions

function! s:GoToWindow(nr) abort
    execute a:nr . 'wincmd w'
endfunction

function! s:SaveCurrentSettings() abort
    if exists('b:clean_saved_settings')
        return
    endif

    let b:clean_saved_settings = {}

    let b:clean_saved_settings['spell'] = &spell

    let b:clean_saved_settings['cc'] = &cc

    let b:clean_saved_settings['bws'] = get(b:, 'better_whitespace_enabled')

    let b:clean_saved_settings['syntastic'] = [exists('b:syntastic_skip_checks'), get(b:, 'syntastic_skip_checks', 0), exists('b:syntastic_loclist')]
endfunction

function! s:ApplyCleanSettings() abort
    setlocal nospell

    setlocal cc=

    if get(b:, 'better_whitespace_enabled')
        DisableWhitespace
    endif

    if !get(b:, 'syntastic_skip_checks')
        let b:syntastic_skip_checks = 1
        SyntasticReset
    endif
endfunction

function! s:IsForcedClean() abort
    return &diff || get(b:, 'clean_mode_force') || (index(g:clean_mode_force, &filetype) != -1)
endfunction

function! s:RestorePreviousSettings() abort
    if !exists('b:clean_saved_settings')
        return
    endif

    if b:clean_saved_settings['spell']
        setlocal spell
    endif

    execute 'setlocal cc=' . b:clean_saved_settings['cc']

    if b:clean_saved_settings['bws']
        EnableWhitespace
    endif

    if b:clean_saved_settings['syntastic'][0]
        let b:syntastic_skip_checks = b:clean_saved_settings['syntastic'][1]
    else
        unlet! b:syntastic_skip_checks
    endif

    if b:clean_saved_settings['syntastic'][2]
        SyntasticCheck
    endif

    unlet! b:clean_saved_settings
endfunction

function! s:ApplyCleanMode() abort
    if get(t:, 'clean_mode', s:clean_mode_default) || s:IsForcedClean()
        call s:SaveCurrentSettings()
        call s:ApplyCleanSettings()
    else
        call s:RestorePreviousSettings()
    endif
endfunction

function! s:UpdateAllWindows() abort
    let sw = winnr()

    for wn in range(1, winnr('$'))
        call s:GoToWindow(wn)
        call s:ApplyCleanMode()
    endfor

    call s:GoToWindow(sw)
endfunction

function! s:ToggleCleanMode() abort
    let t:clean_mode = !get(t:, 'clean_mode', s:clean_mode_default)
    call s:UpdateAllWindows()
endfunction

function! s:ToggleDefaultCleanMode() abort
    let s:clean_mode_default = !s:clean_mode_default

    if !exists('t:clean_mode')
        call s:UpdateAllWindows()
    endif
endfunction

function! clean_mode#status() abort
    if s:IsForcedClean()
        return '[F]'
    else
        if !exists('t:clean_mode') && s:clean_mode_default
            return '[D]'
        elseif get(t:, 'clean_mode')
            return '[C]'
        else
            return ''
        endif
    endif
endfunction

function! clean_mode#init() abort
    let s:clean_mode_default = exists('$VIM_FORCE_CLEAN')

    if !exists('g:clean_mode_force')
        let g:clean_mode_force = ['']
    endif

    augroup clean_mode
        autocmd!
        autocmd BufEnter * call s:ApplyCleanMode()
    augroup END

    if v:vim_did_enter
        call s:UpdateAllWindows()
    else
        augroup clean_mode
            autocmd VimEnter * call s:UpdateAllWindows()
        augroup END
    endif

    command! -nargs=0 ToggleCleanMode call s:ToggleCleanMode()
    command! -nargs=0 ToggleDefaultCleanMode call s:ToggleDefaultCleanMode()
endfunction
