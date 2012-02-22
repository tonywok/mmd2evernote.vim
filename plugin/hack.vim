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
function! s:EvernoteNewNote(notebook, title)
  :ruby Evernote.render(VIM::evaluate("a:notebook"), VIM::evaluate("a:title"))
endfunction

function! s:EvernoteSaveNote()
  :ruby Evernote.save
endfunction

" command definitions
command! -nargs=* Enew call <SID>EvernoteNewNote(<f-args>)
command! Esave :call <SID>EvernoteSaveNote()

ruby << EOF

require 'tempfile'

module Evernote
  extend self

  # Open new scratch buffer
  #
  def render(notebook, title)
    VIM::command("silent edit evernote:#{notebook}_#{title}")
    VIM::command("setlocal buftype=nofile")
    VIM::command("setlocal bufhidden=hide")
    VIM::command("setlocal noswapfile")

    metadata = note_boilerplate(notebook, title)

    metadata.length.times do |num|
      VIM::Buffer.current.append(num, metadata[num])
    end
  end

  # Pipe content to mmd to get html
  # Use applescript to add html to evernote
  #
  def save
    html = ""
    IO.popen("mmd", "r+") do |stream|
      parse_content.each_line { |line| stream << line }
      stream.close_write
      stream.each_line { |line| html << line }
    end

    write_to_evernote = <<-OSA
      tell application "Evernote"
        create note title #{quote parse_title} with html #{quote escape html} notebook #{quote parse_notebook} tags {#{parse_tags}}
      end tell
    OSA

    IO.popen("osascript", "w") do |stream|
      stream.puts write_to_evernote
    end

    VIM::command("redraw")
  end

  def parse_content
    content_range = (5..(buffer.length))
    content_range.to_enum.inject([]) do |lines, line_num|
      lines << buffer[line_num]
    end.join("\n")
  end

  def parse_notebook
    buffer[1].slice(10..-1).strip
  end

  def parse_title
    buffer[2].slice(10..-1).strip
  end

  def parse_tags
    buffer[3].slice(10..-1).split(",").map do |tag|
      "\"#{tag.strip}\""
    end.join(",")
  end

  def note_boilerplate(notebook, title)
    ["Notebook : #{notebook}",
     "Title    : #{title}",
     "Tags     : "]
  end

  def buffer
    VIM::Buffer.current
  end

  def escape(str)
    str.to_s.gsub(/(?=["\\])/, '\\')
  end

  def quote(str)
    '"' << str.to_s << '"'
  end

end

EOF
