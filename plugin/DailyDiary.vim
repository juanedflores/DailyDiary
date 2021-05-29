function! DailyDiaryFloating() abort
    " Define the size of the floating window
    let width = 70
    let height = 40

    " Create the scratch buffer displayed in the floating window
    let buf = nvim_create_buf(v:true, v:false)

		" Set mappings in the buffer to close the window easily
		let closingKeys = ['<Esc>', '<CR>']
		for closingKey in closingKeys
				call nvim_buf_set_keymap(buf, 'n', closingKey, ':q<CR>', {'silent': v:true, 'nowait': v:true, 'noremap': v:true})
		endfor

    " Get the current UI
    let ui = nvim_list_uis()[0]

    " Create the floating window
    let opts = {'relative': 'editor',
                \ 'width': width,
                \ 'height': height,
                \ 'col': (ui.width/2) - (width/2),
                \ 'row': (ui.height/2) - (height/2),
                \ 'anchor': 'NW',
                \ 'style': 'minimal',
								\ 'border': 'double'
                \ }


    let win = nvim_open_win(buf, 1, opts)

		" open vimwiki diary in the buffer
		execute("call vimwiki#diary#make_note(0)")
endfunction

