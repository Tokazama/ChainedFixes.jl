module ChainedFixes

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end ChainedFixes

using Base: Fix1, Fix2, tail

export @nfix, and, ⩓, or, pipe_chain, ⩔

include("chained_core.jl")
using .ChainedCore

end # module

