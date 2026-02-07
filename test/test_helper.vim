" =============================================================================
" Test Helper Functions for vim-expand-region
" Provides utilities to verify actual selection content
" =============================================================================

" Get current visual selection as string
" Returns empty string if no selection exists
" Note: expand_region#next() leaves Vim in visual mode, so we yank to capture
function! TestGetSelection() abort
  " Save current register state
  let save_reg = getreg('"')
  let save_regtype = getregtype('"')

  " Yank selection without exiting visual mode
  silent normal! ""y

  " Get yanked text
  let selection = getreg('"')

  " Restore register
  call setreg('"', save_reg, save_regtype)

  return selection
endfunction

" Assert selection equals expected using Vim script
" Returns 1 if match, 0 otherwise
function! TestAssertSelection(expected) abort
  let actual = TestGetSelection()
  if actual !=# a:expected
    echohl ErrorMsg
    echom printf("Selection mismatch!\nExpected: '%s'\nActual:   '%s'", a:expected, actual)
    echohl None
  endif
  return actual ==# a:expected
endfunction

" Reset buffer and state between tests
" Clears buffer, resets visual marks, and ensures clean state
function! TestResetBuffer() abort
  " Exit any mode back to normal mode
  execute "normal! \<Esc>\<Esc>"
  
  " Switch to a fresh buffer to completely reset state
  enew!
  
  " Clear all marks and registers
  delmarks!
  let @" = ''
  let @/ = ''
  let @0 = ''
  let @1 = ''
  let @2 = ''
  let @3 = ''
  let @4 = ''
  let @5 = ''
  let @6 = ''
  let @7 = ''
  let @8 = ''
  let @9 = ''
  
  " Ensure we're in a clean state
  set nomodified
  call cursor(1, 1)
endfunction
