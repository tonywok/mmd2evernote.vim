" Exit quickly when already loaded
if exists("g:loaded_hack")
  finish
endif

" Exit quickly if running in compat mode
if &compatible
  echohl ErrorMsg
  echohl none
  finish
endif

" Check for teh Rubies!
if !has("ruby")
  echohl ErrorMsg
  echon "Sorry, you need teh Rubies"
  finish
endif

" loaded flag
let g:loaded_hack = "true"

" vimscript wrappers
function! s:Test()
  :ruby Hack.new.foobar
endfunction

" command definitions
command HackVim :call <SID>Test()

ruby << EOF

class Hack

  def current_buffer
    VIM::Buffer.current
  end

  def foobar
    foo = %x{ls ./}
    puts foo
  end

end

EOF
