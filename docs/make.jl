using Documenter
using Pkg
using TmuxPaneDisplay


PROJECT_TOML = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
VERSION = PROJECT_TOML["version"]
NAME = PROJECT_TOML["name"]
AUTHORS = join(PROJECT_TOML["authors"], ", ") * " and contributors"
GITHUB = "https://github.com/goerz/TmuxPaneDisplay.jl"

println("Starting makedocs")

PAGES = ["Home" => "index.md",]

makedocs(
    authors = AUTHORS,
    linkcheck = (get(ENV, "DOCUMENTER_CHECK_LINKS", "1") != "0"),
    # Link checking is disabled in REPL, see `devrepl.jl`.
    #warnonly=[:linkcheck,],
    sitename = "TmuxPaneDisplay.jl",
    format = Documenter.HTML(
        prettyurls = true,
        canonical = "https://goerz.github.io/TmuxPaneDisplay.jl",
        footer = "[$NAME.jl]($GITHUB) v$VERSION docs powered by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl).",
    ),
    pages = PAGES,
)

println("Finished makedocs")

deploydocs(; repo = "github.com/goerz/TmuxPaneDisplay.jl.git", push_preview = true)
