" =============================================================================
" File: expand_region.vim
" Author: Terry Ma
" Forked By: Mike Easley
" Description: Incrementally select larger regions of text in visual mode by
" repeating the same key combination
" Last Modified: January 10, 2026
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Init global vars
call expand_region#init()

" =============================================================================
" Mappings
" =============================================================================
if get(g:, 'expand_region_use_defaults', 1)
    if !hasmapto('<Plug>(expand_region_expand)', 'n')
        nnoremap <silent> + <Plug>(expand_region_expand)
        vnoremap <silent> + <Plug>(expand_region_expand)
    endif
    if !hasmapto('<Plug>(expand_region_shrink)', 'n')
        vnoremap <silent> _ <Plug>(expand_region_shrink)
        nnoremap <silent> _ <Plug>(expand_region_shrink)
    endif
endif

nnoremap <silent> <Plug>(expand_region_expand)
            \ :<C-U>call expand_region#next('n', '+')<CR>
nnoremap <silent> <Plug>(expand_region_shrink)
            \ :<C-U>call expand_region#next('v', '-')<CR>
" Map keys differently depending on which mode is desired
if expand_region#use_select_mode()
    snoremap <silent> <Plug>(expand_region_expand)
                \ :<C-U>call expand_region#next('v', '+')<CR>
    snoremap <silent> <Plug>(expand_region_shrink)
                \ :<C-U>call expand_region#next('v', '-')<CR>
else
    xnoremap <silent> <Plug>(expand_region_expand)
                \ :<C-U>call expand_region#next('v', '+')<CR>
    xnoremap <silent> <Plug>(expand_region_shrink)
                \ :<C-U>call expand_region#next('v', '-')<CR>
endif

let &cpo = s:save_cpo
unlet s:save_cpo
