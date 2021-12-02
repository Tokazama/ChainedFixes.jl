
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
is_fixed_function(::Type{<:Not}) = true


"""
    getargs(f) -> Tuple

Return a tuple of fixed positional arguments of the fixed function `f`.

## Examples

```jldoctest
julia> using ChainedFixes

julia> ChainedFixes.getargs(==(1))
(1,)

```
"""
getargs(x::Fix2) = (getfield(x, :x),)
getargs(x::Fix1) = (getfield(x, :x),)
getargs(x::Approx) = (getfield(x, :y),)
getargs(x::NFix) = getfield(x, :args)
getargs(x::Not) = (getfield(x, :f),)
getargs(x::ChainedFix) = (getfield(x, :f1), getfield(x, :f2))

"""
    getkwargs(f) -> NamedTuple

Return the fixed keyword arguments of the fixed function `f`.

## Examples

```jldoctest
julia> using ChainedFixes

julia> ChainedFixes.getkwargs(isapprox(1, atol=2))
(atol = 2,)

```
"""
getkwargs(x) = NamedTuple{(),Tuple{}}(())
getkwargs(x::Approx) = values(getfield(x, :kwargs))
getkwargs(x::NFix) = getfield(x, :kwargs)
getkwargs(x::Not) = getkwargs(getfield(x, :f))

"""
    getfxn(f) -> Function

Given a fixed function `f`, returns raw method without any fixed arguments.
"""
getfxn(x) = identity
getfxn(x::ChainedFix) = getfield(x, :link)
getfxn(x::Function) = x
getfxn(x::NFix) = getfield(x, :f)
getfxn(x::Fix1) = getfield(x, :f)
getfxn(x::Fix2) = getfield(x, :f)
getfxn(x::Approx) = isapprox
getfxn(x::Not) = !

