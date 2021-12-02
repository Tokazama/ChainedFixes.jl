
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

@inline (f::NFix)(args...; kwargs...) = _execute(f.f, f.args, f.kwargs, args, values(kwargs))

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

