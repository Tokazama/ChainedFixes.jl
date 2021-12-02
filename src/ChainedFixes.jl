module ChainedFixes

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end ChainedFixes

using Base: Fix1, Fix2, tail

export @nfix, and, ⩓, or, pipe_chain, ⩔, closest

module ChainedCore

using ArrayInterface
using ArrayInterface: to_index
using Base: Fix1, Fix2, tail

export
    # Types
    ArgPosition,
    ArgsTrailing,
    ChainedFix,
    NFix,
    # Constants
    Approx,
    Closest,
    In,
    Less,
    Greater,
    Equal,
    NotEqual,
    LessThanOrEqual,
    GreaterThanOrEqual,
    Not,
    NotIn,
    NotApprox,
    PipeChain,
    EndsWith,
    StartsWith,
    @nfix,
    # Constants
    And,
    Or,
    PipeChain,
    # methods
    and,
    closest,
    getargs,
    getkwargs,
    print_fixed,
    getfxn,
    is_fixed_function,
    ⩓,
    or,
    pipe_chain,
    ⩔

if length(methods(isapprox, Tuple{Any})) == 0
    Base.isapprox(y; kwargs...) = x -> isapprox(x, y; kwargs...)
end
const Approx{Kwargs,T} = typeof(isapprox(Any)).name.wrapper{Kwargs,T}

if length(methods(startswith, Tuple{Any})) == 0
    Base.startswith(s) = Base.Fix2(startswith, s)
end
const StartsWith{T} = Fix2{typeof(startswith),T}
if length(methods(endswith, Tuple{Any})) == 0
    Base.endswith(s) = Base.Fix2(endswith, s)
end

const EndsWith{T} = Fix2{typeof(endswith),T}
const Not{T} = (typeof(!(sum)).name.wrapper){T}
const In{T} = Fix2{typeof(in),T}
const NotIn{T} = (typeof(!in(Any)).name.wrapper){Fix2{typeof(in),T}}
const NotApprox{T,Kwargs} = (typeof(!in(Any)).name.wrapper){Approx{T,Kwargs}}

const Less{T} = Union{Fix2{typeof(<),T},Fix2{typeof(isless),T}}
const Equal{T} = Union{Fix2{typeof(==),T},Fix2{typeof(isequal),T}}
const NotEqual{T} = Fix2{typeof(!=),T}
const Greater{T} = Fix2{typeof(>),T}
const GreaterThanOrEqual{T} = Fix2{typeof(>=),T}
const LessThanOrEqual{T} = Fix2{typeof(<=),T}

"""
    ChainedFix(link, f1, f2)

Internal type for composing functions from [`and`](@ref) and [`or`](@ref). For
example, `and(x::Function, y::Function)` becomes `ChainedFix(and, x, y)`. Calling
`ChainedFix` uses the `link` function to propagate arguments to the linked functions `f1`
and `f2`.

See also: [`and`](@ref), [`or`](@ref), [`pipe_chain`](@ref)
"""
struct ChainedFix{L,F1,F2} <: Function
    "the method the \"links\" `f1` and `f2` (i.e. link(f1, f2))"
    link::L
    "the first position in the `link(x, f1, f2)` call"
    f1::F1
    "the second position in the `link(x, f1, f2)` call"
    f2::F2
end

(cf::ChainedFix)(x) = cf.link(x, cf.f1, cf.f2)

include("pipe_chain.jl")
include("closest.jl")
include("and.jl")
include("or.jl")
include("nfix.jl")
include("to_index.jl")
include("print.jl")
include("utils.jl")

end
using .ChainedCore

end # module

