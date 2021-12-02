
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
and

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

const And{F1,F2} = ChainedFix{typeof(and),F1,F2}

