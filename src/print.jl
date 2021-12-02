
"""
    print_fixed(io, x)

Used to print each argument and function that is a part of a `ChainedFix` or `NFix` type
"""
print_fixed(io::IO, f::Function) = print(io, "$(nameof(f))")
print_fixed(io::IO, x) = print(io, repr(x))
function print_fixed(io::IO, @nospecialize(x::Approx))
    print(io, "≈(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end
function print_fixed(io::IO, @nospecialize(x::StartsWith))
    print(io, "startswith(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, @nospecialize(x::EndsWith))
    print(io, "endswith(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, @nospecialize(x::Not))
    print(io, "!")
    print_fixed(io, getargs(x)[1])
end
function print_fixed(io::IO, @nospecialize(x::In))
    print(io, "in(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, @nospecialize(x::Less))
    print(io, "<(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, @nospecialize(x::Equal))
    print(io, "==(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, @nospecialize(x::NotEqual))
    print(io, "!=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, @nospecialize(x::Greater))
    print(io, ">(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, @nospecialize(x::GreaterThanOrEqual))
    print(io, ">=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end

function print_fixed(io::IO, @nospecialize(x::LessThanOrEqual))
    print(io, "<=(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end
function print_fixed(io::IO, @nospecialize(f::ChainedFix))
    print_fixed(io, f.link)
    print(io, "(")
    print_fixed(io, f.f1)
    print(io, ", ")
    print_fixed(io, f.f2)
    print(io, ")")
end
function print_fixed(io::IO, @nospecialize(f::PipeChain))
    print_fixed(io, f.f1)
    print(io, " |> ")
    print_fixed(io, f.f2)
end
function print_fixed(io::IO, @nospecialize(x::Closest))
    print(io, "closest(")
    print_fixed(io, first(getargs(x)))
    print(io, ")")
end
print_fixed(io::IO, x::ArgPosition{N}) where {N} = print(io, "_$N")
print_fixed(io::IO, x::ArgsTrailing) = print(io, "_...")

function print_fixed(io::IO, @nospecialize(f::NFix)) where {P}
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

function Base.show(io::IO, ::MIME"text/plain", f::PipeChain)
    print(io, "|> ")
    print_fixed(io, f)
end
Base.show(io::IO, ::MIME"text/plain", f::NFix) = print_fixed(io, f)

