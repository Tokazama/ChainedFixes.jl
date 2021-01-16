module ChainedFixes

@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    replace(read(path, String), r"^```julia"m => "```jldoctest README")
end ChainedFixes

using Base: Fix1, Fix2, tail
using Base.Iterators: Pairs

export
    @nfix,
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
    PipeChain,
    EndsWith,
    StartsWith,
    # methods
    and,
    ⩓,
    execute,
    getargs,
    getfxn,
    getkwargs,
    is_fixed_function,
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

"""
    pipe_chain(x, y, z...)

Chain together a 
"""
pipe_chain(x, y, z...) = pipe_chain(x, pipe_chain(y, z...))
pipe_chain(x, y) = ChainedFix(pipe_chain, x, y)

(cf::ChainedFix{typeof(pipe_chain)})(x) = x |> cf.f1 |> cf.f2

const PipeChain{F1,F2} = ChainedFix{typeof(pipe_chain),F1,F2}

"""
    and(x, y)
    x ⩓ y

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
function and end

# 3 - args
function and(x, y::Function, z::Function)
    if y(x)
        return z(x)
    else
        return false
    end
end
function and(x, y, z::Function)
    if y
        return z(x)
    else
        return false
    end
end
function and(x, y::Function, z)
    if y(x)
        return z
    else
        return false
    end
end
and(x, y, z) = throw(MethodError(and, (x, y, z))) # TODO better error message

# 2 -args
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
    x ⩔ y

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
function or end

# 3 - args
function or(x, y::Function, z::Function)
    if y(x)
        return true
    else
        return z(x)
    end
end
function or(x, y, z::Function)
    if y
        return true
    else
        return z(x)
    end
end
function or(x, y::Function, z)
    if y(x)
        return true
    else
        return z
    end
end
or(x, y, z) = throw(MethodError(and, (x, y, z))) # TODO better error message


# 2 -args
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

"""
    NFix{P}(f::Function, args::Tuple, kwargs::Pairs)

Allows fixing a tuple of `args` to the positions `P` (e.g., `(1,3)`) and the
key word arguments `kwargs`.

```jldoctest
julia> using ChainedFixes

julia> fxn1(x::Integer, y::AbstractFloat, z::AbstractString) = Val(1);

julia> fxn1(x::Integer, y::AbstractString, z::AbstractFloat) = Val(2);

julia> fxn1(x::AbstractFloat, y::Integer, z::AbstractString) = Val(3);

julia> fxn2(; x, y, z) = fxn1(x, y, z);

julia> fxn3(args...; kwargs...) = (fxn1(args...), fxn2(; kwargs...));

julia> NFix{(1,2)}(fxn1, 1, 2.0)("a")
Val{1}()

julia> NFix{(1,3)}(fxn1, 1, 2.0)("a")
Val{2}()

julia> NFix{(1,3)}(fxn1, 1.0, "")(2)
Val{3}()

julia> NFix(fxn2, x=1, y=2.0)(z = "a")
Val{1}()

julia> NFix(fxn2, x=1, z=2.0)(y="a")
Val{2}()

julia> NFix{(1,2)}(fxn3, 1, 2.0; x=1.0, z="")(""; y = 1)
(Val{1}(), Val{3}())
```

"""
struct NFix{Positions,F<:Function,Args<:Tuple,Kwargs<:Pairs} <: Function
    f::F
    args::Args
    kwargs::Kwargs

    function NFix{P,F,Args,Kwargs}(
        f::F,
        args::Args,
        kwargs::Kwargs
    ) where {P,F,Args<:Tuple,Kwargs<:Pairs}

        if !isa(P, Tuple{Vararg{Int}})
            error("Positions must be a tuple of Int")
        elseif length(P) != length(args)
            error("Number of fixed positions and fixed arguments must be equal," *
                  " received $(length(P)) positions and $(length(args)) positional arguments.")
        elseif !issorted(P)
            error("Positions must be sorted, got $P.")
        else
            return new{P,F,Args,Kwargs}(f, args, kwargs)
        end
    end

    function NFix{P}(f::F, args::Args, kwargs::Kwargs) where {P,F,Args<:Tuple,Kwargs<:Pairs}
        return NFix{P,F,Args,Kwargs}(f, args, kwargs)
    end

    NFix{P}(f, args...; kwargs...) where {P} = NFix{P}(f, args, kwargs)

    function NFix(f, args::NTuple{N,Any}, kwargs::Pairs) where {N}
        return NFix{ntuple(i -> i, Val(N))}(f, args, kwargs)
    end

    NFix(f, args...; kwargs...) = NFix(f, args, kwargs)
end

makeargs(p::Tuple{}, argsnew::Tuple{}, args::Tuple{}, cnt::Int) = ()
makeargs(p::Tuple{}, argsnew::Tuple, args::Tuple{}, cnt::Int) = argsnew
makeargs(p::Tuple, argsnew::Tuple{}, args::Tuple, cnt::Int) = args
@inline function makeargs(p::Tuple, argsnew::Tuple, args::Tuple, cnt::Int)
    if first(p) === cnt
        return (first(args), makeargs(tail(p), argsnew, tail(args), cnt + 1)...)
    else
        return (first(argsnew), makeargs(tail(p), tail(argsnew), args, cnt + 1)...)
    end
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
is_fixed_function(::Type{<:Not}) = true


"""
    getargs(f) -> Tuple

Return a tuple of fixed positional arguments of the fixed function `f`.

## Examples

```jldoctest
julia> using ChainedFixes

julia> getargs(==(1))
(1,)

```
"""
getargs(x) = (x,)
getargs(x::Fix2) = (getfield(x, :x),)
getargs(x::Fix1) = (getfield(x, :x),)
getargs(x::Approx) = (getfield(x, :y),)
getargs(x::NFix) = getfield(x, :args)
getargs(x::Not) = getargs(getfield(x, :f))
getargs(x::ChainedFix) = (getfield(x, :f1), getfield(x, :f2))

"""
    getkwargs(f) -> Pairs

Return the fixed keyword arguments of the fixed function `f`.

## Examples

```jldoctest
julia> using ChainedFixes

julia> getkwargs(isapprox(1, atol=2))
pairs(::NamedTuple) with 1 entry:
  :atol => 2

```
"""
getkwargs(x) = Pairs((), NamedTuple{(),Tuple{}}(()))
getkwargs(x::Approx) = getfield(x, :kwargs)
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
getfxn(x::NotIn) = !in
getfxn(x::NotApprox) = !isapprox

"""
    positions(f) -> Tuple{Vararg{Int}}

Returns positions of new argument calls to `f`. For example, `Fix2` would return (2,)
"""
positions(x) = ()
positions(x::Fix1) = (1,)
positions(x::Fix2) = (2,)
positions(x::NFix{P}) where {P} = P
positions(x::Not) = positions(getkwargs(getfield(x, :f)))
positions(x::ChainedFix) = (1, 2)

"""
    execute(f, args...; kwargs...) -> f(args...; kwargs...)

Executes function `f` with provided positional arugments (`args...`) and
keyword arguments (`kwargs...`).
"""
@inline execute(f, args...; kwargs...) = execute(f, args, kwargs)
@inline function execute(f, args::Tuple, kwargs::Pairs)
    if is_fixed_function(f)
        return getfxn(f)(
            makeargs(positions(f), args, getargs(f), 1)...;
            getkwargs(f)..., kwargs...
        )
    else
        return f(args...; kwargs...)
    end
end

(f::NFix)(args...; kwargs...) = execute(f, args, kwargs)

macro nfix(f)
    function_name = f.args[1]
    narg = length(f.args)
    argpos = 2
    if f.args[2] isa Expr && f.args[2].head === :kw
        pair_names = Expr(:tuple)
        pair_args = Expr(:tuple)
        for kw in f.args[argpos:end]
            push!(pair_names.args, QuoteNode(kw.args[1]))
            push!(pair_args.args, kw.args[2])
        end
        kwargs = :(Iterators.Pairs(NamedTuple{$pair_names}($pair_args), $pair_names))
        args = Expr(:tuple)
        pos = Expr(:tuple)
    else
        if f.args[2] isa Expr && f.args[2].head === :parameters
            pair_names = Expr(:tuple)
            pair_args = Expr(:tuple)
            for kw in f.args[2].args
                push!(pair_names.args, QuoteNode(kw.args[1]))
                push!(pair_args.args, kw.args[2])
            end
            kwargs = :(Iterators.Pairs(NamedTuple{$pair_names}($pair_args), $pair_names))
            argpos = 3
        else
            kwargs = :(Iterators.Pairs(NamedTuple{()}(()),()))
        end
        args = Expr(:tuple)
        pos = Expr(:tuple)
        if narg > argpos
            itr = 1
            for i in argpos:narg
                if f.args[i] === :_
                    itr += 1
                else
                    push!(pos.args, itr)
                    push!(args.args, f.args[i])
                    itr += 1
                end
            end
        end
    end
    esc(
    quote
        NFix{$pos}($function_name, $args, $kwargs)
    end
    )
end

Base.show(io::IO, ::MIME"text/plain", f::ChainedFix) = print_fixed(io, f)
Base.show(io::IO, f::ChainedFix) = print_fixed(io, f)

function Base.show(io::IO, ::MIME"text/plain", f::PipeChain)
    print(io, "|> ")
    print_fixed(io, f)
end
function Base.show(io::IO, f::PipeChain)
    print(io, "|> ")
    print_fixed(io, f)
end


print_fixed(io::IO, f::Function) = print(io, "$(nameof(f))")
print_fixed(io::IO, x) = print(io, repr(x))
function print_fixed(io::IO, f::Fix2)
    print(io, "Fix2(")
    print_fixed(io, f.f)
    print(io, ", ")
    print_fixed(io, f.x)
    print(io, ")")
end

function print_fixed(io::IO, f::PipeChain)
    print_fixed(io, f.f1)
    print(io, " |> ")
    print_fixed(io, f.f2)
end

function print_fixed(io::IO, f::ChainedFix)
    print_fixed(io, f.link)
    print(io, "(")
    print_fixed(io, f.f1)
    print(io, ", ")
    print_fixed(io, f.f2)
    print(io, ")")
end

function print_fixed(io::IO, f::NFix{P}) where {P}
    print_fixed(io, getfxn(f))

    print(io, "(")
    if length(P) !== 0
        args = getargs(f)
        n = last(P)
        current_position = 1
        i = 1
        while current_position <= last(P)
            if current_position === P[i]
                print_fixed(io, args[i])
                i += 1
            else
                print(io, "_")
            end
            if current_position !== last(P)
                print(io, ", ")
            end
            current_position += 1
        end
    end
    if !isempty(f.kwargs)
        print(io, "; ")
        kwargs = getkwargs(f)
        nkwargs = length(kwargs)
        i = 1
        for (k, v) in kwargs
            print(io, "$k = ")
            print_fixed(io, v)
            if i !== nkwargs
                print(io, ", ")
            end
            i += 1
        end
    end
    print(io, ")")
end

Base.show(io::IO, ::MIME"text/plain", f::NFix) = print_fixed(io, f)
Base.show(io::IO, f::NFix) = print_fixed(io, f)

print_fixed(io::IO, x::Less) = print(io, "<($(x.x))")
print_fixed(io::IO, x::Greater) = print(io, ">($(x.x))")
print_fixed(io::IO, x::Equal) = print(io, "==($(x.x))")
print_fixed(io::IO, x::NotEqual) = print(io, "!=($(x.x))")
print_fixed(io::IO, x::LessThanOrEqual) = print(io, "<=($(x.x))")
print_fixed(io::IO, x::GreaterThanOrEqual) = print(io, ">=($(x.x))")
print_fixed(io::IO, x::Not) = print(io, "!($(x.x))")
print_fixed(io::IO, x::In) = print(io, "in($(x.x))")
print_fixed(io::IO, x::NotIn) = print(io, "!in($(getargs(x)[1]))")
print_fixed(io::IO, x::EndsWith) = print(io, "endswith($(repr(x.x)))")
print_fixed(io::IO, x::StartsWith) = print(io, "startswith($(repr(x.x)))")
print_fixed(io::IO, x::Approx) = print(io, "≈($(getargs(x)[1]))")
print_fixed(io::IO, x::NotApprox) = print(io, "!≈($(getargs(x)[1]))")

end # module

