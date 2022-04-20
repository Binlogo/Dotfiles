
" Fish doesn't play all that well with others
set shell=/bin/bash

set nocompatible
filetype off

let mapleader = "\<Space>"

" =============================================================================
" # PLUGINS
" =============================================================================
call plug#begin()

" Vim enhancement
Plug 'editorconfig/editorconfig-vim'
Plug 'justinmk/vim-sneak'

" GUI enhancement
Plug 'itchyny/lightline.vim'
Plug 'andymass/vim-matchup'

" Language & LSP
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'neovim/nvim-lspconfig'
Plug 'simrat39/rust-tools.nvim'

" Fuzzy finder
Plug 'airblade/vim-rooter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()

" =============================================================================
" # Editor settings
" =============================================================================
set noshowmode
if has('nvim')
  au TextYankPost * silent! lua vim.highlight.on_yank()
end

" =============================================================================
" # KEYMAPS
" =============================================================================
imap jk <Esc>
imap kj <Esc>
imap jj <Esc>
imap kk <Esc>

map <C-k> 5k
map <C-j> 5j

map <C-K> 10k
map <C-J> 10j

" ============================================================================
" # FZF & RG
" ============================================================================

let $FZF_DEFAULT_OPTS .= ' --inline-info'

" All files
command! -nargs=? -complete=dir AF
  \ call fzf#run(fzf#wrap(fzf#vim#with_preview({
  \   'source': 'fd --type f --hidden --follow --exclude .git --no-ignore . '.expand(<q-args>)
  \ })))

if exists('$TMUX')
  let g:fzf_layout = { 'tmux': '-p90%,60%' }
else
  let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.6 } }
endif

command! -bar MoveBack if &buftype == 'nofile' && (winwidth(0) < &columns / 3 || winheight(0) < &lines / 3) | execute "normal! \<c-w>\<c-p>" | endif
nnoremap <silent> <Leader><Leader> :MoveBack<BAR>Files<CR>
nnoremap <silent> <Leader><Enter>  :MoveBack<BAR>Buffers<CR>
nnoremap <silent> <Leader>C        :Colors<CR>
nnoremap <silent> <Leader>L        :Lines<CR>
nnoremap <silent> <Leader>`        :Marks<CR>

" for Rg search
nnoremap <silent> <Leader>s        :RG<CR>
nnoremap <silent> <Leader>rg       :RG<CR>

function! s:plug_help_sink(line)
  let dir = g:plugs[a:line].dir
  for pat in ['doc/*.txt', 'README.md']
    let match = get(split(globpath(dir, pat), "\n"), 0, '')
    if len(match)
      execute 'tabedit' match
      return
    endif
  endfor
  tabnew
  execute 'Explore' dir
endfunction

command! PlugHelp call fzf#run(fzf#wrap({
  \ 'source': sort(keys(g:plugs)),
  \ 'sink':   function('s:plug_help_sink')}))

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let options = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  let options = fzf#vim#with_preview(options, 'right', 'ctrl-/')
  call fzf#vim#grep(initial_command, 1, options, a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

