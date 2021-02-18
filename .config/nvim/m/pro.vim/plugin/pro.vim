" pro.vim - Simple config management
" Maintainer:   ii14
" Version:      0.1.0

if exists('g:loaded_pro')
  finish
endif
let g:loaded_pro = 1

" Public API -------------------------------------------------------------------

" Select config
command! -nargs=? -bar -bang -complete=customlist,s:Completion Pro
  \ call s:Command(<q-args>, <q-mods>, <bang>0)

" Get selected config name
fun! pro#selected()
  return s:Selected
endfun

" Get list of config names
fun! pro#configs()
  try
    let d = copy(g:pro)
    try
      call remove(d, '_')
    catch
    endtry
    return sort(keys(d))
  catch
    return []
  endtry
endfun

" Private ----------------------------------------------------------------------

let s:Selected = ''
let s:VarsDefault = {}
let s:VarsEmpty = []

fun! s:Command(config, mods, bang) abort
  " Modifiers
  let l:silent = v:false
  let l:verbose = v:false
  for l:mod in split(a:mods, ' ')
    if l:mod ==# 'verbose'
      let l:verbose = v:true
    elseif l:mod ==# 'silent'
      let l:silent = v:true
    else
      echohl ErrorMsg
      echomsg 'Modifer "' . l:mod . '" not allowed'
      echohl None
      return
    endif
  endfor

  " Bang
  let l:config = a:config !=# '' ? a:config : a:bang ? s:Selected : ''
  if l:config !=# ''
    if !s:HasConfig(l:config)
      echohl ErrorMsg
      echomsg 'Config "' . l:config . '" does not exist'
      echohl None
      return
    endif
  endif

  " Verbose
  if l:verbose
    if l:config ==# ''
      let l:configs = get(g:, 'pro', {})
      for l:name in sort(keys(l:configs))
        echohl Function
        echo l:name . (l:name ==# s:Selected ? ' *' : '')
        echohl None
        let l:val = l:configs[l:name]
        for l:key in sort(keys(l:val))
          let l:rhs = l:val[l:key]
          echo '    ' . l:key . ' = ' .
            \ (type(l:rhs) == v:t_string ? l:rhs : string(l:rhs))
        endfor
      endfor
    else
      echohl Function
      echo l:config . (l:config ==# s:Selected ? ' *' : '')
      echohl None
      let l:val = get(get(g:, 'pro', {}), l:config, {})
      for l:key in sort(keys(l:val))
        let l:rhs = l:val[l:key]
        echo '    ' . l:key . ' = ' .
          \ (type(l:rhs) == v:t_string ? l:rhs : string(l:rhs))
      endfor
    endif
    return
  endif

  if l:config ==# ''
    echo s:Selected
  else
    call s:Select(l:config)
  endif
endfun

fun! s:Select(config) abort
  call s:LetDefault()
  let s:Selected = a:config
  if has_key(g:pro, '_')
    call s:LetConfig(g:pro, '_')
  endif
  call s:LetConfig(g:pro, a:config)
  doautocmd User ProUpdate
endfun

fun! s:HasConfig(config)
  return has_key(g:, 'pro') && a:config !=# '_' && has_key(g:pro, a:config)
endfun

fun! s:LetConfig(dict, key) abort
  let exceptions = []

  for [l:key, l:val] in items(get(a:dict, a:key))
    if index(s:VarsEmpty, l:key) == -1 || !has_key(s:VarsDefault, l:key)
      if exists(l:key)
        execute 'let s:VarsDefault[l:key] = ' . l:key
      else
        call add(s:VarsEmpty, l:key)
      endif
    endif
    try
      execute 'let ' . l:key . ' = l:val'
    catch
      call add(exceptions, [l:key, v:exception])
    endtry
  endfor

  if len(exceptions) > 0
    redraw
    echohl ErrorMsg
    echomsg 'Exception occurred in config "'.a:key.'":'
    for exception in exceptions
      echomsg '  In "' . exception[0] . '":'
      echomsg '    ' . exception[1]
    endfor
    echohl None
  endif
endfun

fun! s:LetDefault() abort
  for l:key in s:VarsEmpty
    try
      execute 'unlet ' . l:key
    catch
    endtry
  endfor
  for [l:key, l:val] in items(s:VarsDefault)
    execute 'let ' . l:key . ' = l:val'
  endfor
endfun

fun! s:Completion(ArgLead, CmdLine, CursorPos)
  return filter(pro#configs(), 'v:val =~ "^' . a:ArgLead . '"')
endfun

fun! s:Init()
  if s:Selected ==# '' && s:HasConfig(get(g:, 'pro#default', '_'))
    call s:Select(g:pro#default)
  endif
endfun

" Autocommands -----------------------------------------------------------------

augroup ProVim
  autocmd!
  autocmd VimEnter * call s:Init() | autocmd ProVim SourcePost * call s:Init()
augroup END

" vim: et sw=2 sts=2 tw=80 :
