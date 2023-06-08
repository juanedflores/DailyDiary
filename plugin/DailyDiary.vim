" A floating window of a taskwiki daily diary buffer.
" Maintainer:	Juan Flores <juanedflores@gmail.com>
" Last Change: 05-29-2021
" Version: 0.1.0
" Repository: https://github.com/juanedflores/DailyDiary
" License: MIT

if exists('g:DailyDiaryLoaded') | finish | endif
let g:DailyDiaryLoaded = 1

"--------------------------------- Verify vars ----------------------------------------
" Wiki Diary Path
if !exists('g:vimwikidiaryPath')
    let g:vimwikidiaryPath = '~/vimwiki/diary'
    " let g:vimwikidiaryPath = '/Users/juanedflores/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Zettelkasten'
endif

let g:diary_isopen = 0
let s:width = 70
let s:height = 40

" Get the current UI
let s:ui = nvim_list_uis()[0]

" Create the floating window
let s:opts = {'relative': 'editor',
             \ 'width': s:width,
             \ 'height': s:height,
             \ 'col': (s:ui.width/2) - (s:width/2),
             \ 'row': (s:ui.height/2) - (s:height/2),
             \ 'anchor': 'NW',
             \ 'style': 'minimal',
             \ 'border': 'double'
             \ }

function! NewDailyDiary() abort
    " Create the scratch buffer displayed in the floating window
    let buf = nvim_create_buf(v:false, v:true)

    let win = nvim_open_win(buf, 1, s:opts)

    " open vimwiki diary in the buffer
    " execute("call vimwiki#diary#make_note(0)")
    execute(":VimwikiMakeDiaryNote")

    let s:diary_buf = bufnr("%")
    let s:diary_name = bufname(s:diary_buf)
    let s:diary_win = win_getid(s:diary_buf)

    " Set mappings in the buffer to close the window easily
    let closingKeys = ['<Esc>']
    for closingKey in closingKeys
        call nvim_buf_set_keymap(s:diary_buf, 'n', closingKey, ':close<CR>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
    endfor
    let g:diary_isopen = 1
endfunction

function! DiaryBufExists()
    if !exists('s:diary_buf') && !exists('s:diary_name')
        return 0
    else 
        return 1
    endif
endfunction

function! DiaryWinShow()
    let win = nvim_open_win(s:diary_buf, 1, s:opts)

    " Get the current UI
    let s:ui = nvim_list_uis()[0]

    " Create the floating window
    let s:opts = {'relative': 'editor',
                 \ 'width': s:width,
                 \ 'height': s:height,
                 \ 'col': (s:ui.width/2) - (s:width/2),
                 \ 'row': (s:ui.height/2) - (s:height/2),
                 \ 'anchor': 'NW',
                 \ 'style': 'minimal',
                 \ 'border': 'double'
                 \ }

    " Set mappings in the buffer to close the window easily
    let closingKeys = ['<Esc>']
    for closingKey in closingKeys
        call nvim_buf_set_keymap(s:diary_buf, 'n', closingKey, ':write | :close<CR>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
    endfor
    let g:diary_isopen = 1
endfunction

function! DailyDiaryToggle()
    if (DiaryBufExists())
        if (g:diary_isopen && bufwinid(s:diary_buf) > 0)
            execute "write"
            call nvim_win_close(s:diary_win, 0)
            let g:diary_isopen = 0
        else
            call DiaryWinShow()
        endif
    else
        call NewDailyDiary()
    endif
endfunction
