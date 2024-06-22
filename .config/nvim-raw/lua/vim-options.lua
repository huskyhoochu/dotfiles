vim.cmd("set nocompatible") -- disable compatibility to old-timevi
vim.cmd("set showmatch") -- show matching
vim.cmd("set ignorecase") -- case insensitive
vim.cmd("set smartcase") -- Override the ignorecase option if searching for capital letters.
vim.cmd("set mouse=v") -- middle-click paste with
vim.cmd("set hlsearch") -- highlight search
vim.cmd("set incsearch") -- incremental search
vim.cmd("set tabstop=2") -- number of columns occupied by a tab
vim.cmd("set softtabstop=2") -- see multiple spaces as tabstops so <BS> does the right thing
vim.cmd("set expandtab") -- converts tabs to white space
vim.cmd("set shiftwidth=2") -- width for autoindents
vim.cmd("set autoindent") -- indent a new line the same amount as the line just typed
vim.cmd("set number") -- add line numbers
vim.cmd("set wildmode=longest,list") -- get bash-like tab completions
vim.cmd("set cc=100") -- set an 100 column border for good coding style
vim.cmd("filetype plugin indent on") -- allow auto-indenting depending on file type
vim.cmd("syntax on") -- syntax highlighting
vim.cmd("set mouse=a") -- enable mouse click
vim.cmd("set clipboard+=unnamedplus") -- using system clipboard
vim.cmd("filetype plugin on")
vim.cmd("set cursorline") -- highlight current cursorline
vim.cmd("set ttyfast") -- Speed up scrolling in Vim
vim.cmd("set history=1000") -- Set the commands to save in history default number is 20.
vim.cmd("set wildmenu") -- Enable auto completion menu after pressing TAB.
vim.cmd("set wildmode=list:longest") -- Make wildmenu behave like similar to Bash completion.
vim.g.mapleader = " "
