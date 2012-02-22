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
  :ruby Hack.to_mmd
endfunction

" command definitions
command HackVim :call <SID>Test()

ruby << EOF

module Hack

  def self.to_mmd
    buff = current_buffer
    md = buff.length.times.inject("") do |lines, lineno|
      lines << buff[lineno + 1].to_s
      lines
    end
    puts "markdown?"
    puts %x{echo '#{md.to_s}' | mmd}
    puts "end markdown"
  end

  def self.current_buffer
    VIM::Buffer.current
  end

end

EOF
