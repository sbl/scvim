
" SCAutoComplete: A plugin for autocompletion of method arguments in the SuperCollider programming language
" Author:         Dionysis Athinaios

" set the variable for the path to the script
 let s:parseScript=expand('<sfile>:p:h').'/SCAutoComplete.rb' 

" AutoComplete options
 autocmd FileType supercollider set completeopt=menuone,preview "longest
 autocmd FileType supercollider set completefunc=SCCompleteFunc
 autocmd FileType supercollider set omnifunc=SCCompleteFunc
 autocmd FileType supercollider call SCAutoCompleteMakeMappings()
 

 "Let user define the mapping if needed
 if !exists('g:sc_auto_complete_key')
     let g:sc_auto_complete_key = 1
 endif


 fun! SCAutoCompleteMakeMappings()
     if g:sc_auto_complete_key
         "Default mapping
         inoremap <buffer> <Tab> <esc>:call SCAutoComplete()<CR>
         "Make the enter key select the item
         inoremap <buffer> <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
     else
         "User mapping
         exec "inoremap <buffer> " . g:sc_auto_complete_key . " <esc>:call SCAutoComplete()<CR>"
         inoremap <buffer> <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
     endif
 endfun

 fun! SCAutoComplete()
     let g:SCAutoCompleteText = strpart(getline('.'), 0, (col('.')))
     let shell_output = system("ruby " . s:parseScript . " " . shellescape(g:SCAutoCompleteText) . " 0")
     echom shell_output
     let shell_output = shell_output[0:strlen(shell_output)-2]
     if shell_output[0:3] == "$NAI"
         "Call the autocomplete function
         call feedkeys("a")
         call feedkeys("\<C-x>\<C-o>")
     elseif shell_output[0:3] == "$OXI"
         let length = strlen(shell_output)
         call SCOpenSplitList(shell_output[4:length])
     elseif shell_output[0:3] == "$NOP"
         call feedkeys("a")
     endif
 endfun

 function! SCOpenSplitList(string)
     " Open a new split and set it up.
     43 vsplit [SC METHOD CHOOSER].sc
     setlocal filetype=supecollider
     setlocal buftype=nofile
     " define mappings
     nnoremap <buffer> l :let g:SCAutoCompleteText = getline('.') \| 
                                      \  call SCFormatSelectedClass() \| 
                                      \  call feedkeys("a") \| 
                                      \  call feedkeys("\<C-x>\<C-o>") \| q<CR>
     normal! ggdG
     call feedkeys("i[SC METHOD CHOOSER]\nPress 'l' to choose:\n")
     call feedkeys("\<esc>")
     call append(1, split(a:string, ","))
 endfunction

 function! SCCompleteFunc(findstart,base)
     if a:findstart
         return col(".")
     else
         call SCPopupMappings()
         let shell_output = system("ruby " . s:parseScript . " " . shellescape(g:SCAutoCompleteText) . " 1")
         let shell_output = shell_output[4:strlen(shell_output)-2]
         " Try to append : if it does not exist already
         " let result = split(shell_output, ",")
         " for i in result
         "     if matchstr(i,":")
         "         let i = i . ":"
         "     end
         " endfor
         return split(shell_output, ",")
     endif
 endfunction

fun! SCFormatSelectedClass()
    let string_array = split(g:SCAutoCompleteText,  " --> ")
    let class_name = string_array[1]
    let g:SCAutoCompleteText = class_name[0:strlen(class_name)-3] . string_array[0] . "("
endfun

fun! SCPopupMappings()
    inoremap <buffer> , ,<space><C-x><C-o>
    imap <buffer> ) <esc>a<right>)
    imap <buffer> ( <esc>a<right>(
    imap <buffer> { <esc>a<right>{
    imap <buffer> [ <esc>a<right>[
    imap <buffer> " <esc>a<right>"
    imap <buffer> ' <esc>a<right>'
    inoremap <buffer> <esc> <esc>:call SCPopupEscUnmap()<CR>
    inoremap <buffer> <C-c> <C-c>:call SCPopupEscUnmap()<CR>
endfun

fun! SCPopupEscUnmap()
    exe ": silent! imapclear <buffer>"
    call SCAutoCompleteMakeMappings()
endfun

