module Tmux

import ..AbstractMultiplexerPaneDisplay
import ..send_cmd
import ..get_pane_dimensions
import ..requires_switching
import ..get_current_pane
import ..select_pane


struct TmuxPaneDisplay <: AbstractMultiplexerPaneDisplay
    target_pane::String
    tmpdir::String
    imgcat::String
    bin::String  # TODO: this needs a better name
    nrows::Int64
    redraw_previous::Int64
    dry_run::Bool
    only_write_files::Bool
    use_filenames_as_title::Bool  # TODO: this needs a better name
    clear::Bool
    sleep_secs::Float64
    files::Vector{String}  # Absolute paths of generated files
    titles::Vector{String}  # Title for each file
end


const _imgcat = "wezterm imgcat --height {height} --width {width} '{file}'"


# TODO: documentation
function TmuxPaneDisplay(;
    target_pane,
    tmpdir = mktempdir(),
    imgcat = _imgcat,
    bin = "tmux",
    nrows = 1,
    clear = true,
    redraw_previous = (clear ? (nrows - 1) : 0),
    dry_run = false,
    only_write_files = false,
    use_filenames_as_title = true,
    sleep_secs = (contains(string(target_pane), ":") ? 0.0 : 0.5),
    files = String[],  # internal
    titles = String[],  # internal
)
    # TODO: check that target_pane is either "session:window.pane" or "pane"
    TmuxPaneDisplay(
        string(target_pane),
        tmpdir,
        imgcat,
        bin,
        nrows,
        redraw_previous,
        dry_run,
        only_write_files,
        use_filenames_as_title,
        clear,
        sleep_secs,
        files,
        titles,
    )
end


function Base.summary(io::IO, d::TmuxPaneDisplay)
    msg = "TmuxPaneDisplay for $(d.nrows) row(s) using $(d.bin) target $(d.target_pane)"
    attribs = String[]
    if !d.use_filenames_as_title
        push!(attribs, "echo off")
    end
    if !d.clear
        push!(attribs, "do not clear")
    end
    if d.only_write_files
        push!(attribs, "only write files")
    end
    if d.redraw_previous > 0
        push!(attribs, "redraw previous $(d.redraw_previous)")
    end
    if d.dry_run
        push!(attribs, "dry run")
    end
    if length(attribs) > 0
        msg *= " (" * join(attribs, ", ") * ")"
    end
    write(io, msg)
end


function send_cmd(d::TmuxPaneDisplay, cmd_str::AbstractString)
    target_pane = d.target_pane
    tmux = d.bin
    cmd = `$tmux send-keys -t $target_pane $cmd_str Enter`
    if d.dry_run
        @debug "$cmd (dry run)"
    else
        @debug "$cmd"
        run(cmd)
    end
end


requires_switching(::TmuxPaneDisplay) = true


function select_pane(d::TmuxPaneDisplay, pane)
    tmux = d.bin
    cmd = `$tmux select-pane -t $pane`
    if d.dry_run
        @debug "$cmd (dry run)"
    else
        @debug "$cmd"
        run(cmd)
    end
end


function get_current_pane(d::TmuxPaneDisplay)
    tmux = d.bin
    cmd = `$tmux display -p '#{pane_index}'`
    if d.dry_run
        pane = "<orig pane>"
        @debug "$cmd -> current pane $pane (dry run)"
    else
        pane = strip(read(cmd, String))
        @debug "$cmd -> current pane $pane"
    end
    return pane
end


function get_pane_dimensions(d::TmuxPaneDisplay, pane)
    tmux = d.bin
    cmd = `$tmux display -p -t $pane '#{pane_width}'`
    if d.dry_run
        width = 80
        @debug "$cmd -> pane width $width (dry run)"
    else
        width = parse(Int64, strip(read(cmd, String)))
        @debug "$cmd -> pane width $width"
    end
    cmd = `$tmux display -p -t $pane '#{pane_height}'`
    if d.dry_run
        height = 24
        @debug "$cmd -> pane height $height (dry run)"
    else
        height = parse(Int64, strip(read(cmd, String)))
        @debug "$cmd -> pane height $height"
    end
    return width, height
end


end
