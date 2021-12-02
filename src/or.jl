
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
or

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

const Or{F1,F2} = ChainedFix{typeof(or),F1,F2}

