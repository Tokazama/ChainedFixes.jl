# ChainedFixes

[![Build Status](https://travis-ci.com/Tokazama/ChainedFixes.jl.svg?branch=master)](https://travis-ci.com/Tokazama/ChainedFixes.jl) [![codecov](https://codecov.io/gh/Tokazama/ChainedFixes.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Tokazama/ChainedFixes.jl)
[![stable-docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/ChainedFixes.jl/stable)
[![dev-docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/ChainedFixes.jl/dev)

`ChainedFixes.jl` provides useful tools for interacting with functions where arguments are fixed to them.
This includes support for those found in Julia's `Base` module (`Base.Fix1`, `Base.Fix2`) and exported from `ChainedFixes` (`ChainedFix` and `NFix`).

Some simple functionality available form this package is chaining any fixed function.
```julia
julia> using ChainedFixes

julia> gt_or_lt = or(>(10), <(5));

julia> gt_or_lt(2)
true

julia> gt_or_lt(6)
false


julia> gt_and_lt = and(>(1), <(5));

julia> gt_and_lt(2)
true

julia> gt_and_lt(0)
false
```

There's more convenient syntax for these available in the Julia REPL.
```julia
julia> gt_or_lt = >(10) ⩔ <(5); # \Or<TAB>

julia> gt_or_lt(2)
true

julia> gt_or_lt(6)
false


julia> gt_and_lt = >(1) ⩓ <(5); # \And<TAB>

julia> gt_and_lt(2)
true

julia> gt_and_lt(0)
false
```

Any function can have methods fixed to it with the `NFix` function.
```julia
julia> fxn1(x::Integer, y::AbstractFloat, z::AbstractString) = Val(1);

julia> fxn1(x::Integer, y::AbstractString, z::AbstractFloat) = Val(2);

julia> fxn1(x::AbstractFloat, y::Integer, z::AbstractString) = Val(3);

julia> fxn2(; x, y, z) = fxn1(x, y, z);

julia> fxn3(args...; kwargs...) = (fxn1(args...), fxn2(; kwargs...));

julia> f = @nfix fxn1(1, 2.0, _)
fxn1(1, 2.0, args...; kwargs...)

julia> f("a")
Val{1}()


julia> f = @nfix fxn1(1, _, 2.0)
fxn1(1, _, 2.0, args...; kwargs...)

julia> f("a")
Val{2}()

julia> f = @nfix fxn1(1.0, _, "")
fxn1(1.0, _, "", args...; kwargs...)

julia> f(2)
Val{3}()

julia> f = @nfix fxn2(x=1, y=2.0)
fxn2(args...; x = 1, y = 2.0, kwargs...)

julia> f(z = "a")
Val{1}()

julia> f = @nfix fxn2(x=1, z=2.0)
fxn2(args...; x = 1, z = 2.0, kwargs...)

julia> f(y = "a")
Val{2}()

julia> f = @nfix fxn3(1, 2.0; x = 1.0, z= "")
fxn3(1, 2.0, args...; x = 1.0, z = , kwargs...)

julia> f(""; y = 1)
(Val{1}(), Val{3}())

```

We can create a chain a functions that act like an uncalled pipe (e.g., `|>`).
A chain of fixed functions can be chained together via `pipe_chain`.
```julia
julia> f = pipe_chain(@nfix(_ * "is "), @nfix(_ * "a "), @nfix(_ * "sentence."));

julia> f("This ")
"This is a sentence."

```

## Constants

The following constants are exported.

| Syntax                                    | Type Constant           |
|------------------------------------------:|:------------------------|
| `pipe_chain(f1, f2)`                      | `PipeChain{F1,F2}`      |
| `and(f1::F1, f1::F2)`/`⩓(f1::F1, f1::F2)` | `And{F1,F2}`            |
| `or(f1::F1, f1::F2)`/`⩔(f1::F1, f1::F2)`  | `Or{F1,F2}`             |
| `isapprox(x::T; kwargs::Kwargs)`          | `Approx{T,Kwargs}`      |
| `!isapprox(x::T; kwargs::Kwargs)`         | `NotApprox{T,Kwargs}`   |
| `in(x::T)`                                | `In{T}`                 |
| `!in(x::T)`                               | `NotIn{T}`              |
| `<(x::T)`                                 | `Less{T}`               |
| `<=(x::T)`                                | `LessThanOrEqual{T}`    |
| `>(x::T)`                                 | `Greater{T}`            |
| `>=(x::T)`                                | `GreaterThanOrEqual{T}` |
| `==(x::T)`                                | `Equal{T}`              |
| `isequal(x::T)`                           | `Equal{T}`              |
| `!=(x::T)`                                | `NotEqual{T}`           |
| `startswith(x::T)`                        | `StartsWith{T}`         |
| `endswith(x::T)`                          | `EndsWith{T}`           |


