
module ChainedCore

using Base: Fix1, Fix2, tail

export
    # Types
    ArgPosition,
    ArgsTrailing,
    ChainedFix,
    NFix,
    # Constants
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
and(x, y, z) = throw(MethodError(and, (x, y, z)))

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
or(x, y, z) = throw(MethodError(or, (x, y, z)))


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

struct ArgsTrailing end

struct NFix{F,Args<:Tuple,Kwargs<:NamedTuple} <: Function
    f::F
    args::Args
    kwargs::Kwargs
end

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

@inline (f::NFix)(args...; kwargs...) = _execute(f.f, f.args, f.kwargs, args, kwargs.data)

@generated function _execute(
    f,
    fixed_args::FA,
    fixed_kwargs::NamedTuple{FKN},
    args::A,
    kwargs::NamedTuple{KN}
)  where {Nf,Na,FA<:Tuple{Vararg{Any,Nf}},A<:Tuple{Vararg{Any,Na}},FKN,KN}

    out = Expr(:call, :f)
    if !isempty(FKN)
        kwargsexpr = Expr(:parameters)
        for name in FKN
            push!(kwargsexpr.args, Expr(:kw, name, :(getfield(fixed_kwargs, $(QuoteNode(name))))))
        end
        if !isempty(KN)
            for name in KN
                push!(kwargsexpr.args, Expr(:kw, name, :(getfield(kwargs, $(QuoteNode(name))))))
            end
        end
        push!(out.args, kwargsexpr)
    else
        if !isempty(KN)
            kwargsexpr = Expr(:parameters)
            for name in KN
                push!(kwargsexpr.args, Expr(:kw, name, :(getfield(kwargs, $(QuoteNode(name))))))
            end
            push!(out.args, kwargsexpr)
        end
    end

    max_underscore, has_trailing_underscore = underscore_info(FA)
    if max_underscore === Na
        has_trailing_underscore = false  # don't need to account for this now
    elseif !has_trailing_underscore || max_underscore > Na
        str = "Expected $max_underscore positional arguments but received $Na"
        return :($str)
    end

    argexpr = Any[]
    cnt = 1
    for p in FA.parameters
        if p <: ArgPosition
            push!(argexpr, :(getfield(args, $(p.parameters[1]))))
        elseif !(p <: ArgsTrailing)
            push!(argexpr, :(getfield(fixed_args, $cnt)))
        end
        cnt += 1
    end
    if has_trailing_underscore
        for i in (max_underscore + 1):Na
            push!(argexpr, :(getfield(args, $i)))
        end
    end
    append!(out.args, argexpr)
    return out
end

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
        kwargs = :(NamedTuple{$pair_names}($pair_args))
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
            kwargs = :(NamedTuple{$pair_names}($pair_args))
            argpos = 3
        else  # no kwargs
            kwargs = :(NamedTuple{(),Tuple{}}(()))
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


"""
    print_fixed(io, x)

Used to print each argument and function that is a part of a `ChainedFix` or `NFix` type
"""
print_fixed(io::IO, f::Function) = print(io, "$(nameof(f))")
print_fixed(io::IO, x) = print(io, repr(x))
function print_fixed(io::IO, x::Approx)
    print(io, "≈(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end
function print_fixed(io::IO, x::StartsWith)
    print(io, "startswith(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, x::EndsWith)
    print(io, "endswith(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, x::Not)
    print(io, "!")
    print_fixed(io, getargs(x)[1])
end
function print_fixed(io::IO, x::In)
    print(io, "in(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, x::Less)
    print(io, "<(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, x::Equal)
    print(io, "==(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, x::NotEqual)
    print(io, "!=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, x::Greater)
    print(io, ">(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, x::GreaterThanOrEqual)
    print(io, ">=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, x::LessThanOrEqual)
    print(io, "<=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end
function print_fixed(io::IO, f::ChainedFix)
    print_fixed(io, f.link)
    print(io, "(")
    print_fixed(io, f.f1)
    print(io, ", ")
    print_fixed(io, f.f2)
    print(io, ")")
end
function print_fixed(io::IO, f::PipeChain)
    print_fixed(io, f.f1)
    print(io, " |> ")
    print_fixed(io, f.f2)
end
print_fixed(io::IO, x::ArgPosition{N}) where {N} = print(io, "_$N")
print_fixed(io::IO, x::ArgsTrailing) = print(io, "_...")

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
        for (k, v) in pairs(kwargs)
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

Base.show(io::IO, ::MIME"text/plain", f::NFix) = print_fixed(io, f)
Base.show(io::IO, f::NFix) = print_fixed(io, f)

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
getargs(x) = (x,)
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
getkwargs(x::Approx) = getfield(x, :kwargs).data
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

end

