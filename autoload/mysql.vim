function! s:get_visual_selection()
  let [sline, scol, soff]=getpos("'<")[1:]
  let [eline, ecol, eoff]=getpos("'>")[1:]
  if sline>eline || (sline==eline && scol>ecol)
      let [sline, scol, eline, ecol]=[eline, ecol, sline, scol]
  endif
  let lchar=len(matchstr(getline(eline), '\%'.ecol.'c.'))
  if lchar>1
      let ecol+=lchar-1
  endif
  return join(s:get_vrange([sline, scol], [eline, ecol]), "\n")
endfunction

function! s:get_vrange(start, end)
    let [sline, scol]=a:start
    let [eline, ecol]=a:end
    let text=[]
    let ellcol=col([eline, '$'])
    let slinestr=getline(sline)
    if sline==eline
        if ecol>=ellcol
            call extend(text, [slinestr[(scol-1):], ""])
        else
            call add(text, slinestr[(scol-1):(ecol-1)])
        endif
    else
        call add(text, slinestr[(scol-1):])
        let elinestr=getline(eline)
        if (eline-sline)>1
            call extend(text, getline(sline+1, eline-1))
        endif
        if ecol<ellcol
            call add(text, elinestr[:(ecol-1)])
        else
            call extend(text, [elinestr, ""])
        endif
    endif
    return text
endfunction

function! s:trim(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! MySql#run_query(user, pwd, query)
  let command = 'mysql -u '.a:user.' -p'.a:user.' '.a:pwd.' --table'
  let result = system(command, a:query)
  return result
endfunction

function! MySql#query_to_buffer()
  let query = s:get_visual_selection()
  if (len(query) <= 0)
    return
  endif
  let result = MySql#run_query(s:username, s:password, query)

  let query_display = s:trim(substitute(query, '\\n', '\n', 'g'))
  let query_title = substitute(query_display, '\s+', ' ', 'g')
  echo query_title
  " let result_list = split(query_display, '\n') + [''] + split(result, '\n')
  let result_list = split(result, '\n')

  " Delete the current mysql query result buffer, if any.
  if (exists('s:mysql_buffer_name') && bufexists(s:mysql_buffer_name))
    execute 'bdelete' s:mysql_buffer_name
  endif
  let s:mysql_buffer_name = '[ MySql query: '.query_title.' ]'
  " Output result_list to a split buffer
  execute 'split' s:mysql_buffer_name
  normal! ggdG
  setlocal buftype=nofile
  call append(0, result_list)
endfunction

function! MySql#auth(username, password)
  let s:username = a:username
  let s:password = a:password
endfunction

map <leader>q <esc>:call MySql#query_to_buffer()<CR>
