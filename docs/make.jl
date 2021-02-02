using Documenter, ChainedFixes

makedocs(;
    modules=[ChainedFixes],
    format=Documenter.HTML(),
    pages=[
        "ChainedFixes" => "index.md",
    ],
    sitename="ChainedFixes.jl",
    authors="Zachary P. Christensen",
)

deploydocs(
    repo = "github.com/Tokazama/ChainedFixes.jl.git",
)
