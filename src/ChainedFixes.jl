
module ChainedFixes

using Base: Fix2

export
    ChainedFix,
    # ands
    and,
    ⩓,
    And, 
    # ors
    or,
    ⩔,
    Or,
    Approx,
    In,
    Less,
    Greater,
    Equal,
    NotEqual,
    LessThanOrEqual,
    GreaterThanOrEqual,
    Not,
    NotIn,
    NotApprox

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

end # module
