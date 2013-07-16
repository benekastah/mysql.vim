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

function! s:get_query_or_line()
  if mode() == 'n'
    let query = getline('.')
  else
    let query = s:get_visual_selection()
  endif
  return query
endfunction

function! s:get_query_or_word()
  if mode() == 'n'
    let query = expand('<cword>')
  else
    let query = s:get_visual_selection()
  endif
  return query
endfunction

function! mysql#GetCommand(host, user, pwd, db)
  if exists("b:command_getter") && b:command_getter
    return b:command_getter(a:host, a:user, a:pwd, a:db)
  elseif s:command_getter
    return s:command_getter(a:host, a:user, a:pwd, a:db)
  endif
  let cmd = 'mysql -h '.a:host.' -u '.a:user.' -p'.a:pwd.' '.a:db.' --table'
  return cmd
endfunction

function! mysql#RunQuery(host, user, pwd, db, query)
  if (len(a:query) <= 0)
    return ''
  endif
  let cmd = mysql#GetCommand(a:host, a:user, a:pwd, a:db)
  let result = system(cmd, a:query)
  return result
endfunction

function! mysql#EnvRunQuery(query)
  if exists("b:host") && b:host
    return mysql#RunQuery(b:host, b:username, b:password, b:database, a:query)
  else
    return mysql#RunQuery(s:host, s:username, s:password, s:database, a:query)
  endif
endfunction

let s:mysql_buffer_number = -1
function! mysql#Query()
  let query = s:get_query_or_line()
  call mysql#DisplayResult(query)
endfunction

function! mysql#DisplayResult(query)
  let result = mysql#EnvRunQuery(a:query)
  let query_display = s:trim(substitute(a:query, '\\n', '\n', 'g'))
  let result_list = split(query_display, '\n') + [''] + split(result, '\n')

  " Delete the current mysql query result buffer, if any.
  if (s:mysql_buffer_number >= 0 && bufexists(s:mysql_buffer_number))
    execute 'bwipeout' s:mysql_buffer_number
  endif

  " Output result_list to a split buffer
  split [\ MySql\ query\ ]
  let s:mysql_buffer_number = bufnr('%')
  normal! ggdG
  setlocal buftype=nofile
  call append(0, result_list)
endfunction

function! mysql#DescTable()
  let tablename = s:get_query_or_word()
  call mysql#DisplayResult('desc `'.tablename.'`;')
endfunction

function! mysql#Auth(host, username, password, database)
  let s:host = a:host
  let s:username = a:username
  let s:password = a:password
  let s:database = a:database
endfunction

function! mysql#BufferAuth(host, username, password, database)
  let b:host = a:host
  let b:username = a:username
  let b:password = a:password
  let b:database = a:database
endfunction

function! mysql#SetCommandGetter(fn)
  let s:command_getter = a:fn
endfunction

function! mysql#BufferSetCommandGetter(fn)
  let b:command_getter = a:fn
endfunction

call mysql#Auth(0, 0, 0, 0)
call mysql#SetCommandGetter(0)

map <leader>q <esc>:call mysql#Query()<CR>
map <leader>d <esc>:call mysql#DescTable()<CR>
