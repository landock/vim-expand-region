vim9script
# =============================================================================
# File: expand_region.vim
# Author: Terry Ma
# Last Modified: March 30, 2013 (original); migrated 2026
# =============================================================================

var save_cpo = &cpo
set cpo&vim

var saved_pos = []
var cur_index = -1
var candidates = []

export def Init(): void
  if get(g:, 'expand_region_init', 0)
    return
  endif

  g:expand_region_init = 1
  g:expand_region_text_objects = get(g:, 'expand_region_text_objects', {
        \ "iw": 0,
        \ "iW": 0,
        \ "i\"": 0,
        \ "i'": 0,
        \ "i]": 1,
        \ "ib": 1,
        \ "iB": 1,
        \ "il": 0,
        \ "ip": 0,
        \ "ie": 0
        \})
  g:expand_region_use_select_mode = get(g:, 'expand_region_use_select_mode', 0)
enddef

export def CustomTextObjects(arg1: any, arg2: any = v:null): void
  if arg2 == v:null
    call extend(g:expand_region_text_objects, arg1)
    return
  endif
  var ft = arg1
  var dict_value = arg2
  var ft_key = 'expand_region_text_objects_' .. ft
  var ft_dict = {}
  if !has_key(g:, ft_key)
    call extend(g:, { [ft_key]: {} })
    ft_dict = get(g:, ft_key)
    call extend(ft_dict, g:expand_region_text_objects)
  else
    ft_dict = get(g:, ft_key)
  endif
  extend(ft_dict, dict_value)
enddef

export def UseSelectMode(): bool
  return g:expand_region_use_select_mode || index(split(&selectmode, ','), 'cmd') != -1
enddef

export def Next(mode: string, direction: string): void
  ExpandRegion(mode, direction)
enddef

expand_region#Init()

# =============================================================================
# Helpers
# =============================================================================

def SortTextObject(l: any, r: any): number
  return l.length - r.length
enddef

def ComparePos(l: list<number>, r: list<number>): number
  return l[1] == r[1] ? l[2] - r[2] : l[1] - r[1]
enddef

def IsCursorInside(pos: list<number>, region: dict<any>): bool
  if ComparePos(pos, region.start_pos) < 0
    return false
  endif
  if ComparePos(pos, region.end_pos) > 0
    return false
  endif
  return true
enddef

def RemoveDuplicate(input: any): void
  var idx = len(input) - 1
  while idx >= 1
    if input[idx].length == input[idx - 1].length &&
          \ input[idx].start_pos == input[idx - 1].start_pos
      call remove(input, idx)
    endif
    idx -= 1
  endwhile
enddef

def GetCandidateDict(text_object: string): dict<any>
  var winview = winsaveview()
  silent! normal! v
  execute 'silent! normal ' .. text_object
  silent! normal! \<Esc>
  var selection = GetVisualSelection()
  var ret = {
        \ 'text_object': text_object,
        \ 'start_pos': selection.start_pos,
        \ 'end_pos': selection.end_pos,
        \ 'length': selection.length
        \}
  if text_object == "i'" && ret.length > 0
    var line = getline(ret.start_pos[1])
    var start_idx = ret.start_pos[2] - 1
    var end_idx = ret.end_pos[2]
    if start_idx < 1 || end_idx > len(line) || line[start_idx - 1] != "'" || line[end_idx - 1] != "'"
      ret.length = 0
    endif
  endif
  winrestview(winview)
  return ret
enddef

def GetConfiguration(): dict<any>
  if exists('b:expand_region_text_objects')
    return b:expand_region_text_objects
  endif
  var configuration = {}
  for ft in split(&ft, '\.')
    var ft_key = 'expand_region_text_objects_' .. ft
    if has_key(g:, ft_key)
      call extend(configuration, get(g:, ft_key))
    endif
  endfor
  if empty(configuration)
    call extend(configuration, g:expand_region_text_objects)
  endif
  return configuration
enddef

def GetCandidateList(): list<any>
  var save_wrapscan = &wrapscan
  set nowrapscan
  var config = GetConfiguration()
  var candidate_list = []
  for text_object in keys(config)
    call add(candidate_list, GetCandidateDict(text_object))
  endfor
  var recursive_candidates = []
  for candidate in candidate_list
    if !get(config, candidate.text_object, 0)
      continue
    endif
    if candidate.length == 0
      continue
    endif
    var repeat_count = 2
    var previous_length = candidate.length
    while 1
      var test = repeat(candidate.text_object, repeat_count)
      var next_candidate = GetCandidateDict(test)
      if next_candidate.length == 0
        break
      endif
      if next_candidate.length == previous_length
        break
      endif
      call add(recursive_candidates, next_candidate)
      repeat_count += 1
      previous_length = next_candidate.length
    endwhile
  endfor
  &wrapscan = save_wrapscan
  return extend(candidate_list, recursive_candidates)
enddef

def GetVisualSelection(): dict<any>
  var start_pos = getpos("'<")
  var end_pos = getpos("'>")
  if start_pos[1] == 0 || end_pos[1] == 0
    return {
          \ 'start_pos': start_pos,
          \ 'end_pos': end_pos,
          \ 'length': 0
          \}
  endif
  if ComparePos(start_pos, end_pos) == 0
    return {
          \ 'start_pos': start_pos,
          \ 'end_pos': end_pos,
          \ 'length': 0
          \}
  endif
  if ComparePos(start_pos, end_pos) > 0
    var tmp = start_pos
    start_pos = end_pos
    end_pos = tmp
  endif
  var [lnum1, col1] = start_pos[1 : 2]
  var [lnum2, col2] = end_pos[1 : 2]
  if lnum1 <= 0 || lnum2 <= 0 || col1 <= 0 || col2 <= 0
    return {
          \ 'start_pos': start_pos,
          \ 'end_pos': end_pos,
          \ 'length': 0
          \}
  endif
  var lines = getline(lnum1, lnum2)
  if empty(lines)
    return {
          \ 'start_pos': start_pos,
          \ 'end_pos': end_pos,
          \ 'length': 0
          \}
  endif
  lines[-1] = lines[-1][ : col2 - 1]
  lines[0] = lines[0][col1 - 1 : ]
  var sel_len = len(join(lines, "\n"))
  return {
        \ 'start_pos': start_pos,
        \ 'end_pos': end_pos,
        \ 'length': sel_len
        \}
enddef

def ShouldComputeCandidates(mode: string): bool
  if mode == 'v'
    if cur_index >= 0
      var selection = GetVisualSelection()
      if candidates[cur_index].start_pos == selection.start_pos &&
            \ candidates[cur_index].length == selection.length
        return false
      endif
    endif
  endif
  return true
enddef

def ComputeCandidates(cursor_pos: list<number>)
  cur_index = -1
  saved_pos = cursor_pos
  candidates = GetCandidateList()
  filter(sort(candidates, 'SortTextObject'), 'v:val.length > 1')
  filter(candidates, 'IsCursorInside(saved_pos, v:val)')
  RemoveDuplicate(candidates)
enddef

def SelectRegion(): void
  normal! v
  execute 'normal! ' .. candidates[cur_index].text_object
  if expand_region#UseSelectMode()
    normal! \<C-g>
  endif
enddef

def ExpandRegion(mode: string, direction: string): void
  var saved_selectmode = &selectmode
  &selectmode = ''
  var selection = {}
  if mode == 'v'
    selection = GetVisualSelection()
  endif
  if ShouldComputeCandidates(mode)
    if mode == 'v' && cur_index >= 0
      ComputeCandidates(saved_pos)
    else
      ComputeCandidates(getpos('.'))
    endif
    if mode == 'v' && get(selection, 'length', 0) > 0
      var found = -1
      for idx in range(0, len(candidates) - 1)
        if candidates[idx].start_pos == selection.start_pos &&
              \ candidates[idx].length == selection.length
          found = idx
          break
        endif
      endfor
      if found >= 0
        cur_index = found
      endif
    endif
  else
    call setpos('.', saved_pos)
  endif
  if direction == '+'
    if cur_index == len(candidates) - 1
      normal! \<Esc>
    else
      cur_index += 1
      candidates[cur_index].prev_winview = winsaveview()
      call SelectRegion()
    endif
  else
    if cur_index <= 0
      if expand_region#UseSelectMode()
        normal! gV
      endif
    else
      call winrestview(candidates[cur_index].prev_winview)
      cur_index -= 1
      call SelectRegion()
    endif
  endif
  &selectmode = saved_selectmode
enddef

&cpo = save_cpo
