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

function! s:smart_get_query()
  let pstatement_end = ';\s*\(\-\-.*\)\?$'
  let lcur = line('.')
  let colcur = col('.')

  let lprev = search(pstatement_end, 'b')
  if lprev > lcur
    let lprev = 0
  endif
  let lprev = lprev + 1
  call cursor(lcur, colcur)

  if expand('<cword>') == ';'
    let llast = lcur
  else
    let llast = search(pstatement_end)
  endif
  if llast < lcur
    let llast = line('$')
  endif
  call cursor(lcur, colcur)

  let lines = getline(lprev, llast)
  return join(lines, '\n')
endfunction

function! s:trim(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! mysql#GetCommand(host, user, pwd, db)
  let cmd = 'mysql -h '.a:host.' -u '.a:user.' -p'.a:pwd.' '.a:db.' -t'
  return cmd
endfunction

function! mysql#RunQuery(host, user, pwd, db, query)
  if (len(a:query) <= 0)
    return ''
  endif
  let cmd = mysql#GetCommand(a:host, a:user, a:pwd, a:db)
  if exists('b:run_query_fn') && b:run_query_fn
    let result = b:run_query_fn(cmd, a:query)
  elseif s:run_query_fn
    let result = s:run_query_fn(cmd, a:query)
  else
    let result = system(cmd, a:query)
  endif
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
function! mysql#QueryVisual()
  let query = s:get_visual_selection()
  call mysql#DisplayResult(query)
endfunction

function! mysql#QuerySmart()
  let query = s:smart_get_query()
  call mysql#DisplayResult(query)
endfunction

function! mysql#DescTable()
  let tablename = expand('<cword>')
  call mysql#DisplayResult('desc `'.tablename.'`;')
endfunction

function! mysql#DisplayResult(query)
  let query = s:trim(substitute(a:query, '\\n', '\n', 'g'))
  let result = mysql#EnvRunQuery(query)
  " let query_display = substitute(a:query, '\\n', '\n', 'g')
  let result_list = split(query, '\n') + [''] + split(result, '\n')

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

function! mysql#SetRunQueryFn(fn)
  let s:run_query_fn = a:fn
endfunction

function! mysql#BufferSetRunQueryFn(fn)
  let b:run_query_fn = a:fn
endfunction

call mysql#Auth(0, 0, 0, 0)
call mysql#SetRunQueryFn(0)

map <leader>q <esc>:call mysql#QuerySmart()<CR>
map <leader>qv <esc>:call mysql#QueryVisual()<CR>
map <leader>d <esc>:call mysql#DescTable()<CR>
