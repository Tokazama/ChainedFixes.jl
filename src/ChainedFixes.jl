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
    or,
    pipe_chain,
    ⩔

const EmptyPairs = Pairs{Union{}, Union{}, Tuple{}, NamedTuple{(), Tuple{}}}

if length(methods(isapprox, Tuple{Any})) == 0
    Base.isapprox(y; kwargs...) = x -> isapprox(x, y; kwargs...)
end
const Approx{Kwargs,T} = typeof(isapprox(Any)).name.wrapper{Kwargs,T}
print_fixed(io::IO, x::Approx) = print(io, "≈($(first(getargs(x))))")

if length(methods(startswith, Tuple{Any})) == 0
    Base.startswith(s) = Base.Fix2(startswith, s)
end
const StartsWith{T} = Fix2{typeof(startswith),T}
function print_fixed(io::IO, x::StartsWith)
    print(io, "startswith(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

if length(methods(endswith, Tuple{Any})) == 0
    Base.endswith(s) = Base.Fix2(endswith, s)
end

const EndsWith{T} = Fix2{typeof(endswith),T}
function print_fixed(io::IO, x::EndsWith)
    print(io, "endswith(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

const Not{T} = (typeof(!(sum)).name.wrapper){T}
function print_fixed(io::IO, x::Not)
    print(io, "!")
    print_fixed(io, getargs(x)[1])
end

const In{T} = Fix2{typeof(in),T}
function print_fixed(io::IO, x::In)
    print(io, "in(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

const NotIn{T} = (typeof(!in(Any)).name.wrapper){Fix2{typeof(in),T}}

const NotApprox{T,Kwargs} = (typeof(!in(Any)).name.wrapper){Approx{T,Kwargs}}

const Less{T} = Union{Fix2{typeof(<),T},Fix2{typeof(isless),T}}
function print_fixed(io::IO, x::Less)
    print(io, "<(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

const Equal{T} = Union{Fix2{typeof(==),T},Fix2{typeof(isequal),T}}
function print_fixed(io::IO, x::Equal)
    print(io, "==(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

const NotEqual{T} = Fix2{typeof(!=),T}
function print_fixed(io::IO, x::NotEqual)
    print(io, "!=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

const Greater{T} = Fix2{typeof(>),T}
function print_fixed(io::IO, x::Greater)
    print(io, ">(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

const GreaterThanOrEqual{T} = Fix2{typeof(>=),T}
function print_fixed(io::IO, x::GreaterThanOrEqual)
    print(io, ">=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

const LessThanOrEqual{T} = Fix2{typeof(<=),T}
function print_fixed(io::IO, x::LessThanOrEqual)
    print(io, "<=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end


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

function print_fixed(io::IO, f::ChainedFix)
    print_fixed(io, f.link)
    print(io, "(")
    print_fixed(io, f.f1)
    print(io, ", ")
    print_fixed(io, f.f2)
    print(io, ")")
end

"""
    pipe_chain(x, y, z...)

Chain together a 
"""
pipe_chain(x, y, z...) = pipe_chain(x, pipe_chain(y, z...))
pipe_chain(x, y) = ChainedFix(pipe_chain, x, y)

(cf::ChainedFix{typeof(pipe_chain)})(x) = x |> cf.f1 |> cf.f2

const PipeChain{F1,F2} = ChainedFix{typeof(pipe_chain),F1,F2}
function print_fixed(io::IO, f::PipeChain)
    print_fixed(io, f.f1)
    print(io, " |> ")
    print_fixed(io, f.f2)
end

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

struct ArgPosition{N}
    ArgPosition{N}() where {N} = new{N::Int}()
    ArgPosition(n::Int) = new{n}()
end

print_fixed(io::IO, x::ArgPosition{N}) where {N} = print(io, "_$N")

struct ArgsTrailing end
print_fixed(io::IO, x::ArgsTrailing) = print(io, "_...")


#=
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
=#
struct NFix{F,Args<:Tuple,Kwargs<:Pairs} <: Function
    f::F
    args::Args
    kwargs::Kwargs
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
is_fixed_function(x) = is_fixed_function(typeof(x))
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
getargs(x) = (x,)
getargs(x::Fix2) = (getfield(x, :x),)
getargs(x::Fix1) = (getfield(x, :x),)
getargs(x::Approx) = (getfield(x, :y),)
getargs(x::NFix) = getfield(x, :args)
getargs(x::Not) = (getfield(x, :f),)
getargs(x::ChainedFix) = (getfield(x, :f1), getfield(x, :f2))

"""
    getkwargs(f) -> Pairs

Return the fixed keyword arguments of the fixed function `f`.

## Examples

```jldoctest
julia> using ChainedFixes

julia> ChainedFixes.getkwargs(isapprox(1, atol=2))
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

# (max_underscore, has_trailing_underscore)
Base.@pure function underscore_info(::Type{A})::Tuple{Int,Bool} where {A}
    has_trailing_underscore = false
    max_underscore = 0
    for p in A.parameters
        if p <: ArgPosition
            n = p.parameters[1]
            if n > max_underscore
                max_underscore = n
            end
        elseif p <: ArgsTrailing
            has_trailing_underscore = true
        else
            nothing
        end
    end
    return (max_underscore, has_trailing_underscore)
end

@generated function _swap_underscores(
    fixed::F,
    args::A
)  where {Nf,Na,F<:Tuple{Vararg{Any,Nf}},A<:Tuple{Vararg{Any,Na}}}

    max_underscore, has_trailing_underscore = underscore_info(F)
    if max_underscore === Na
        has_trailing_underscore = false  # don't need to account for this now
    elseif !has_trailing_underscore || max_underscore > Na
        str = "Expected $max_underscore positional arguments but received $Na"
        return :($str)
    end

    out = Expr(:tuple)
    cnt = 1
    for p in F.parameters
        if p <: ArgPosition
            push!(out.args, :(getfield(args, $(p.parameters[1]))))
        elseif !(p <: ArgsTrailing)
            push!(out.args, :(getfield(fixed, $cnt)))
        end
        cnt += 1
    end
    if has_trailing_underscore
        for i in (max_underscore + 1):Na
            push!(out.args, :(getfield(args, $i)))
        end
    end
    return out
end

@inline function (f::NFix)(args...; kwargs...)
    return f.f(_swap_underscores(f.args, args)...; f.kwargs..., kwargs...)
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

function print_fixed(io::IO, f::NFix) where {P}
    print_fixed(io, getfxn(f))
    print(io, "(")
    cnt = 1
    args = getargs(f)
    nargs = length(args)
    for arg_i in args
        print_fixed(io, arg_i)
        if cnt !== nargs
            cnt += 1
            print(io, ", ")
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

"""
    @nfix fxn(args...; kwargs...)

Integers following an underscore (`_1`, `_2`) describe the corresponding position of arguments passed to the fixed method.
A trailing underscore (`_...`) indicates that all arguments passed that don't correspond to a fixed underscore position can be used as varargs.
"""
macro nfix(f)
    function_name = f.args[1]
    narg = length(f.args)
    argpos = 2
    if f.args[2] isa Expr && f.args[2].head === :kw
        # we only have kwargs
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
            # we also have kwargs
            pair_names = Expr(:tuple)
            pair_args = Expr(:tuple)
            for kw in f.args[2].args
                push!(pair_names.args, QuoteNode(kw.args[1]))
                push!(pair_args.args, kw.args[2])
            end
            kwargs = :(Iterators.Pairs(NamedTuple{$pair_names}($pair_args), $pair_names))
            argpos = 3
        else  # no kwargs
            kwargs = :(Iterators.Pairs(NamedTuple{()}(()),()))
        end
        args = Expr(:tuple)
        pos = Expr(:tuple)
        n = 1
        underscore_positions = Int[]
        if narg > argpos
            for i in argpos:narg
                arg_i = f.args[i]
                if arg_i == :(_...)
                    if i == narg
                        push!(args.args, :(ChainedFixes.ArgsTrailing()))
                    else
                        error("trailing arguments must be the last positional arguments")
                    end
                elseif arg_i isa Symbol && first(string(arg_i)) == '_'
                    xsplit = split(string(arg_i), "_")
                    if length(xsplit) === 2
                        if xsplit[2] == ""
                            position_i = n
                        else
                            position_i = parse(Int, xsplit[2])
                        end
                        push!(underscore_positions, position_i)
                        push!(args.args, :(ChainedFixes.ArgPosition{$position_i}()))
                        n += 1
                    else
                        # there were multiple underscores in `x` so it isn't underscore followed by Int
                        push!(args.args, f.args[i])
                    end
                else
                    push!(args.args, f.args[i])
                end
            end
        end
        cnt = 1
        for p_i in sort(unique(underscore_positions))
            cnt === p_i || error("expected underscore suffixed with $cnt")
            cnt += 1
        end
    end
    esc(:(ChainedFixes.NFix($function_name, $args, $kwargs)))
end


end # module

