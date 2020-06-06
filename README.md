# ChainedFixes

[![Build Status](https://travis-ci.com/Tokazama/ChainedFixes.jl.svg?branch=master)](https://travis-ci.com/Tokazama/ChainedFixes.jl) [![codecov](https://codecov.io/gh/Tokazama/ChainedFixes.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Tokazama/ChainedFixes.jl)



Chain operators `Base.Fix2` operations with two possible methods.

`and` is synonymous with bitwise `&` operator but may be used to chain multiple `Fix1` or
`Fix2` operations. The `⩓` (`\\And<TAB>`) operator may be used in its place (e.g., `x ⩓ y`).

```julia
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

`or` is synonymous with bitwise `|` operator but may be used to chain multiple `Fix1` or
`Fix2` operations. The `⩔` (`\\Or<TAB>`) operator may be used in its place (e.g., `x ⩔ y`).

```julia
julia> using ChainedFixes

julia> or(true, <(5))(1)
true

julia> or(<(5), false)(1)
true

julia> or(<(5) ⩔ >(1), >(2))(3)  # ⩔ == \\Or
true
```

## NFix



Fix arguments to 

```julia
julia> using ChainedFixes

julia> add3(x, y, z) = x - y + z;

julia> f1 = NFix{(1,)}(add3, 2, 3);

julia> f2 = NFix{(2,)}(add3, 2, 3);

julia> f3 = NFix{(3,)}(add3, 2, 3);

julia> f1(1)
2

julia> f2(1)
4

julia> f3(1)
0

julia> f1 = NFix{(1,2)}(add3, 3);

julia> f2 = NFix{(2,3)}(add3, 3);

julia> f3 = NFix{(1,3)}(add3, 3);

julia> f1(1, 2)
2

julia> f2(1, 2)
4

julia> f3(1, 2)
0
```


## Conveniant Type Constants

|       Syntax | Type Constant           |
| -----------: | ----------------------- |
|    `and`/`⩓` | `And{F1,F2}`            |
|     `or`/`⩔` | `Or{F1,F2}`             |
|   `isapprox` | `Approx{T,Kwargs}`      |
|         `in` | `In{T}`                 |
|        `!in` | `NotIn{T}`              |
|          `<` | `Less{T}`               |
|         `<=` | `LessThanOrEqual{T}`    |
|          `>` | `Greater{T}`            |
|         `>=` | `GreaterThanOrEqual{T}` |
|         `==` | `Equal{T}`              |
|    `isequal` | `Equal{T}`              |
|         `!=` | `NotEqual{T}`           |
| `startswith` | `StartsWith{T}`         |
|   `endswith` | `EndsWith{T}`           |

