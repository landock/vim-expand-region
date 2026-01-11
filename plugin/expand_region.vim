vim9script
# =============================================================================
# File: expand_region.vim
# Author: Terry Ma
# Forked By: Mike Easley
# Description: Incrementally select larger regions of text in visual mode by
# repeating the same key combination
# Last Modified: January 21, 2014
# =============================================================================

var save_cpo = &cpo
set cpo&vim

# Init global vars
expand_region#Init()

# =============================================================================
# Mappings
# =============================================================================
if get(g:, 'expand_region_use_defaults', 1)
    if !hasmapto('<Plug>(expand_region_expand)')
        nmap + <Plug>(expand_region_expand)
        vmap + <Plug>(expand_region_expand)
    endif
    if !hasmapto('<Plug>(expand_region_shrink)')
        vmap _ <Plug>(expand_region_shrink)
        nmap _ <Plug>(expand_region_shrink)

    endif
endif

nnoremap <silent> <Plug>(expand_region_expand)
            \ :<C-U>call expand_region#Next('n', '+')<CR>
nnoremap <silent> <Plug>(expand_region_shrink)
            \ :<C-U>call expand_region#Next('v', '-')<CR>
# Map keys differently depending on which mode is desired
if expand_region#UseSelectMode()
    snoremap <silent> <Plug>(expand_region_expand)
                \ :<C-U>call expand_region#Next('v', '+')<CR>
    snoremap <silent> <Plug>(expand_region_shrink)
                \ :<C-U>call expand_region#Next('v', '-')<CR>
else
    xnoremap <silent> <Plug>(expand_region_expand)
                \ :<C-U>call expand_region#Next('v', '+')<CR>
    xnoremap <silent> <Plug>(expand_region_shrink)
                \ :<C-U>call expand_region#Next('v', '-')<CR>
endif

&cpo = save_cpo
