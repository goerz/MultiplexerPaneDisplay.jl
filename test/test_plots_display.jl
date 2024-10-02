using Test
using TmuxPaneDisplay
using IOCapture: IOCapture
using Logging
using Plots

@testset "plots dry run" begin

    c = IOCapture.capture(passthrough = false) do
        withenv("JULIA_DEBUG" => TmuxPaneDisplay) do
            TmuxPaneDisplay.enable(
                target_pane = "test:0.0",
                tmpdir = ".",
                nrows = 1,
                dry_run = true,
                imgcat_cmd = "imgcat -H {height} -W {width} '{file}'"
            )
            fig1 = scatter(rand(100))
            display(fig1)
            fig2 = scatter(rand(100))
            display(fig2)
            TmuxPaneDisplay.set_options(nrows = 2, echo_filename = false)
            display(fig2)
            TmuxPaneDisplay.disable()
        end
    end
    expected_lines = [
        # Activation
        "Activating TmuxPaneDisplay for 1 row(s) using tmux target test:0.0",
        # Initializing the pane
        "`tmux send-keys -t test:0.0 \"PS1=''\" Enter`",
        "`tmux send-keys -t test:0.0 'stty -echo' Enter`",
        "`tmux send-keys -t test:0.0 clear Enter`",
        # Showing fig1
        "Saving image/png representation of Plots.Plot{Plots.GRBackend} object",
        "001.png",
        "`tmux display -p '#{pane_index}'` -> current pane <orig pane>",
        "`tmux select-pane -t test:0.0`",
        "`tmux send-keys -t test:0.0 clear Enter`",
        "`tmux display -p -t test:0.0 '#{pane_width}'` -> pane width 80",
        "`tmux display -p -t test:0.0 '#{pane_height}'` -> pane height 24",
        "`tmux send-keys -t test:0.0 \"echo \\\"001.png\\\"; imgcat -H 21 -W 78 './001.png'\" Enter`",
        "`tmux select-pane -t '<orig pane>'`",
        # Showing fig2
        "002.png",
        "`tmux send-keys -t test:0.0 \"echo \\\"002.png\\\"; imgcat -H 21 -W 78 './002.png'\" Enter`",
        # Set options
        "Info: Activating TmuxPaneDisplay for 2 row(s)",
        # Re-showing fig2
        "Saving image/png representation of Plots.Plot{Plots.GRBackend} object to ./003.png",
        "`tmux send-keys -t test:0.0 \"imgcat -H 10 -W 78 './002.png'\" Enter`",
        "`tmux send-keys -t test:0.0 \"imgcat -H 10 -W 78 './003.png'\" Enter`",
        # Deactivation
        "Deactivating TmuxPaneDisplay",
        "`tmux send-keys -t test:0.0 \"PS1='> '\" Enter`",
        "`tmux send-keys -t test:0.0 'stty echo' Enter`",
    ]
    for line in expected_lines
        res = @test contains(c.output, line)
        if res isa Test.Fail
            @error "Test failure" line
        end
    end

end

# TODO: only write files
