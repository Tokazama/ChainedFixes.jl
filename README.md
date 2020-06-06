# ChainedFixes

[![Build Status](https://travis-ci.com/Tokazama/ChainedFixes.jl.svg?branch=master)](https://travis-ci.com/Tokazama/ChainedFixes.jl) [![codecov](https://codecov.io/gh/Tokazama/ChainedFixes.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Tokazama/ChainedFixes.jl)
[![stable-docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://Tokazama.github.io/ChainedFixes.jl/stable)
[![dev-docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://Tokazama.github.io/ChainedFixes.jl/dev)

`ChainedFixes.jl` provides useful tools for interacting with functions where arguments are fixed to them.
This includes support for those found in Julia's `Base` module (`Base.Fix1`, `Base.Fix2`) and exported from `ChainedFixes` (`ChainedFix` and `NFix`).


## Constants

The following constants are exported.

| Syntax                                    | Type Constant           |
|------------------------------------------:|:------------------------|
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


