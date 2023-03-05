{ pkgs, stable-packages }: with pkgs; {
  enable = true;
  viAlias = true;
  vimAlias = true;

  plugins = with vimPlugins; [
    vim-nix
    haskell-vim
    deoplete-nvim
    commentary
  ];
  extraConfig = ''
    set nocompatible
    " ---------------------------------- Plugins -----------------------------------
    if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &rtp) ==# '''
      runtime! macros/matchit.vim
    endif
    filetype plugin indent on
    syntax on
    " ---------------------------------- Settings ----------------------------------
    set autoindent
    set autoread
    set autowrite
    set background=dark
    set backspace=indent,eol,start
    set nobackup
    set belloff=cursor
    set clipboard=unnamedplus
    set cmdwinheight=7
    set complete-=i
    set cursorline
    set colorcolumn=121
    set display=""
    set errorbells
    set expandtab
    set formatoptions+=j
    set nohidden
    set history=1000
    set hlsearch
    set ignorecase
    set incsearch
    set keywordprg=:help
    set laststatus=2
    set lazyredraw
    set list
    set listchars=tab:>-,trail:~,extends:>,precedes:<,nbsp:%
    set nrformats-=octal
    set number
    set relativenumber
    set shiftround
    set shiftwidth=2
    set showcmd
    set noshowmatch
    set showmode
    set sidescrolloff=5
    set smarttab
    set smartcase
    set statusline=%<%F%h%m%r\ (%{strftime(\"%d.%m.%Y\ %H:%M:%S\",getftime(expand(\"%:p\")))})%=%l,%c%V\ %P
    set tabstop=2
    set timeout
    set timeoutlen=8000
    set noundofile
    set novisualbell
    set wildmenu
    set mouse=""
    set nowrap
    " ----------------------------------- Colors -----------------------------------
    colorscheme slate
    hi MatchParen ctermbg=NONE ctermfg=blue
    " -------------------------------- Definitions ---------------------------------
    let g:netrw_liststyle=3
    let g:netrw_bufsettings="noma nomod nonu nobl nowrap ro nu"
    let g:netrw_banner=0
    " -------------------------------- Redefinitons --------------------------------
    " Don't break undo when using <C-U>
    inoremap <C-U> <C-G>u<C-U>

    " History search instead of completion for commands
    cnoremap <C-P> <UP>
    cnoremap <C-N> <DOWN>

    " Unjoin lines. (C-J is originally equivalent to j)
    nnoremap <C-J> a<CR><ESC>k$

    " Make Y consistent with D and C
    nnoremap Y y$

    " Avoid fat-finger ex mode
    nnoremap Q <NOP>

    " Make search under cursor respect case
    nnoremap * /\C\<<C-R><C-W>\><CR>
    nnoremap # #\C\<<C-R><C-W>\><CR>

    " Write after every edit
    inoremap <Esc> <Esc>:w<CR>
    " ------------------------------ Leader Mappings -------------------------------
    let mapleader=" "

    " Clear the highlighting of :set hlsearch.
    nnoremap <silent><Leader>/ :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':'''<CR><CR><C-L>

    " Format file
    function! Format()
      let l:save = winsaveview()
      execute "normal gg=G"
      %s/\s\+$//e
      call winrestview(l:save)
    endfunction
    nnoremap <Leader>ff :call Format()<CR>

    " Show Leader mappings
    noremap <Leader><Leader> :map <Leader><CR>
    " ----------------------------- Autocommands -----------------------------------
    function! ToggleExplorerIfNoFile()
      if @% == ""
        20Lex
      endif
    endfunction

    augroup currentBuffer
      au BufEnter * set cursorline
      au BufEnter * set relativenumber
      au BufEnter * set number

      au BufLeave * set nocursorline
      au BufLeave * set norelativenumber
      au BufLeave * set nonumber
    augroup END
  '';
}
