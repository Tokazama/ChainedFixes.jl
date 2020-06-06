module ChainedFixes

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end ChainedFixes

using Base: Fix1, Fix2, tail
using Base.Iterators: Pairs

export
    # Types
    ChainedFix,
    NFix,
    # Constants
    And, 
    Approx,
    Or,
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
    EndsWith,
    StartsWith,
    # methods
    and,
    ⩓,
    execute,
    or,
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

# Compose ∘
# schroeder et al., Cerebral cortex 1998
# Schroeder, Mehta, Foxe, Front Biosc, 2001
# Daniel polland - adaptive resonance
struct ChainedFix{L,F1,F2} <: Function
    link::L
    f1::F1
    f2::F2
end

function (cf::ChainedFix{L,F1,F2})(x) where {L,F1<:Function,F2<:Function}
    return cf.link(cf.f1(x), cf.f2(x))
end
(cf::ChainedFix{L,F1,F2})(x) where {L,F1<:Function,F2} = cf.link(cf.f1(x), cf.f2)
(cf::ChainedFix{L,F1,F2})(x) where {L,F1,F2<:Function} = cf.link(cf.f1, cf.f2(x))

"""
    and(x, y)

Synonymous with bitwise `&` operator but may be used to chain multiple `Fix1` or
`Fix2` operations. The `⩓` (`\\And<TAB>`) operator may be used in its place (e.g., `x ⩓ y`).

## Examples
```jldoctest
julia> using ChainedFixes

julia> and(true, <(5))(1)
true

julia> and(<(5), false)(1)
false

julia> and(and(<(5), >(1)), >(2))(3)
true

julia> and(<(5) ⩓ >(1), >(2))(3)  # ⩓ == \\And
true

```
"""
and(x, y) = x & y
and(x::Function, y) = ChainedFix(and, x, y)
and(x, y::Function) = ChainedFix(and, x, y)
and(x::Function, y::Function) = ChainedFix(and, x, y)

and(f1::Less{T}, f2::Less{T}) where {T} = (f1.x < f2.x) ? f1 : f2

and(f1::LessThanOrEqual{T}, f2::LessThanOrEqual{T}) where {T} = (f1.x < f2.x) ? f1 : f2

and(f1::Greater{T}, f2::Greater{T}) where {T} = (f1.x > f2.x) ? f1 : f2

and(f1::GreaterThanOrEqual{T}, f2::GreaterThanOrEqual{T}) where {T} = (f1.x > f2.x) ? f1 : f2

# \And
⩓(x, y) = and(x, y)

"""
    or(x, y)

Synonymous with bitwise `|` operator but may be used to chain multiple `Fix1` or
`Fix2` operations. The `⩔` (`\\Or<TAB>`) operator may be used in its place (e.g., `x ⩔ y`).

## Examples
```jldoctest
julia> using ChainedFixes

julia> or(true, <(5))(1)
true

julia> or(<(5), false)(1)
true

julia> or(<(5) ⩔ >(1), >(2))(3)  # ⩔ == \\Or
true
```
"""
or(x, y) = x | y
or(x::Function, y) = ChainedFix(or, x, y)
or(x, y::Function) = ChainedFix(or, x, y)
or(x::Function, y::Function) = ChainedFix(or, x, y)

or(f1::Less{T}, f2::Less{T}) where {T} = (f1.x > f2.x) ? f1 : f2

or(f1::LessThanOrEqual{T}, f2::LessThanOrEqual{T}) where {T} = (f1.x > f2.x) ? f1 : f2

or(f1::Greater{T}, f2::Greater{T}) where {T} = (f1.x < f2.x) ? f1 : f2

or(f1::GreaterThanOrEqual{T}, f2::GreaterThanOrEqual{T}) where {T} = (f1.x < f2.x) ? f1 : f2

#\Or
⩔(x, y) = or(x, y)

const And{F1,F2} = ChainedFix{typeof(and),F1,F2}

const Or{F1,F2} = ChainedFix{typeof(or),F1,F2}

# TODO Should position args refer to the positions of fixed arguments or new arguments
struct NFix{Positions,F<:Function,Args<:Tuple,Kwargs<:Pairs} <: Function
    f::F
    args::Args
    kwargs::Kwargs

    function NFix{P,F,Args,Kwargs}(
        f::F,
        args::Args,
        kwargs::Kwargs
    ) where {P,F,Args<:Tuple,Kwargs<:Pairs}

        if P isa Tuple{Vararg{Int}}
            return new{P,F,Args,Kwargs}(f, args, kwargs)
        else
            # more specific error
            error("positions must be a tuple of Int")
        end
    end

    function NFix{P}(f::F, args::Args, kwargs::Kwargs) where {P,F,Args<:Tuple,Kwargs<:Pairs}
        return NFix{P,F,Args,Kwargs}(f, args, kwargs)
    end

    NFix{P}(f, args...; kwargs...) where {P} = NFix{P}(f, args, kwargs)

    NFix(f, args::Tuple, kwargs::Pairs) = NFix{()}(f, args, kwargs)

    NFix(f, args...; kwargs...) = NFix(f, args, kwargs)
end

###
### Traits
###

"""
    is_fixed_function(f) -> Bool

Returns `true` if `f` is a callable function that already has arguments fixed to it.
A "fixed" function can only be called on one argument (e.g., `f(arg)`) and all other
arguments are already assigned. Functions that return true should also have `getargs`
defined.
"""
is_fixed_function(::T) where {T} = is_fixed_function(T)
is_fixed_function(::Type{T}) where {T} = false
is_fixed_function(::Type{<:Fix2}) = true
is_fixed_function(::Type{<:Fix1}) = true
is_fixed_function(::Type{<:Approx}) = true
is_fixed_function(::Type{<:ChainedFix}) = true
is_fixed_function(::Type{<:NFix}) = true

"""
    getargs(x) -> Tuple

"""
getargs(x) = (x,)
getargs(x::Fix2) = (getfield(x, :x),)
getargs(x::Fix1) = (getfield(x, :x),)
getargs(x::Approx) = (getfield(x, :y),)
getargs(x::Tuple) = x
getargs(x::NFix) = getfield(x, :args)

"""
    getkwargs(x) -> Pairs
"""
getkwargs(x) = Pairs((), NamedTuple{(),Tuple{}}(()))
getkwargs(x::Approx) = getfield(x, :kwargs)
getkwargs(x::NFix) = getfield(x, :kwargs)

"""
    getfxn(x) -> Function
"""
getfxn(x) = identity
getfxn(x::Function) = x
getfxn(x::NFix) = getfield(x, :f)
getfxn(x::Fix1) = getfield(x, :f)
getfxn(x::Fix2) = getfield(x, :f)


"""
    positions(x) -> Tuple{Vararg{Int}}

Returns positions of new argument calls to `x`. For example, `Fix2` would return (2,)
"""
positions(x) = ()
positions(x::Fix1) = (1,)
positions(x::Fix2) = (2,)
positions(x::NFix{P}) where {P} = P


# makeargs
makeargs(f, argsnew) = makeargs(positions(f), argsnew, getargs(f))
@inline function makeargs(p::NTuple{N,Int}, argsnew::NTuple{M,Any}, args::Tuple) where {N,M}
    if N === M
        return _makeargs(p, argsnew, args)
    else
        throw(ArgumentError("expected $N positional arguments. Received $M"))
    end
end
_makeargs(::Tuple{}, ::Tuple{}, args::Tuple) = args
@inline function _makeargs(p::Tuple, argsnew::Tuple, args::Tuple)
    return _makeargs(tail(p), tail(argsnew), insertarg(args, first(argsnew), first(p)))
end

@inline function insertarg(args::Tuple, newarg, i::Int)
    if i === 1
        return (newarg, args...)
    else
        return (first(args), insertarg(tail(args), newarg, i - 1)...)
    end
end

"""
    execute(f, args...; kwargs...) -> f(args...; kwargs...)

Executes function `f` with provided positional arugments (`args...`) and
keyword arguments (`kwargs...`).
"""
execute(f, args...; kwargs...) = execute(f, args, kwargs)
execute(f, args::Tuple, kwargs::Pairs) = _execute(f, args, kwargs)
execute(f, args::Tuple{}, kwargs::Pairs) = _execute(f, kwargs)
execute(f, ::Tuple{}, ::Pairs{Union{},Union{},NamedTuple{(),Tuple{}},Tuple{}}) = _execute(f)
function execute(f, args::Tuple, ::Pairs{Union{},Union{},NamedTuple{(),Tuple{}},Tuple{}})
    return _execute(f, args)
end

@inline function _execute(f)
    if is_fixed_function(f)
        return getfxn(f)()
    else
        return f()
    end
end

@inline function _execute(f, kwargs::Pairs)
    if is_fixed_function(f)
        return getfxn(f)(; kwargs..., getkwargs(f)...)
    else
        return f(; kwargs...)
    end
end

@inline function _execute(f, args::Tuple)
    if is_fixed_function(f)
        return getfxn(f)(makeargs(f, args)...)
    else
        return f(args...)
    end
end

@inline function _execute(f, args::Tuple, kwargs::Pairs)
    if is_fixed_function(f)
        return getfxn(f)(makeargs(f, args)...; kwargs..., getkwargs(f)...)
    else
        return f(args...; kwargs...)
    end
end

(f::NFix)(args...; kwargs...) = execute(f, args, kwargs)

end # module

