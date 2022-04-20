
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

call plug#end()

" =============================================================================
" # Editor settings
" =============================================================================
set noshowmode
if has('nvim')
  au TextYankPost * silent! lua vim.highlight.on_yank()
end
