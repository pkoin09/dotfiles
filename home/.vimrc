set nocp
filetype plugin on

call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
call plug#end()

set grepprg=rg\ --vimgrep\ --smart-case\ --follow
