using Test
using ChainedFixes
using Documenter
using Base.Iterators: Pairs
using Base: Fix1

empty_pairs = Pairs((), NamedTuple{(),Tuple{}}(()))

@test @inferred(ChainedFixes.positions(1)) == ()
@test @inferred(ChainedFixes.positions(<(1))) == (2,)

@test @inferred(getfxn(1)) == identity
@test @inferred(getfxn(+)) == +

@test !is_fixed_function(1)

@testset "Fix1" begin
    fix1_fxn = Fix1(<, 1)
    @test is_fixed_function(typeof(fix1_fxn))
    @test @inferred(getargs(fix1_fxn)) == (1,)
    @test @inferred(getfxn(fix1_fxn)) == <
    @test @inferred(getkwargs(fix1_fxn)) == empty_pairs
    @test @inferred(ChainedFixes.positions(fix1_fxn)) == (1,)
end

@testset "Not" begin
    notfxn = !(+)
    @test isa(notfxn, Not)
    @test !isa(+, Not)
    @test @inferred(is_fixed_function(typeof(notfxn)))
    @test @inferred(getfxn(notfxn)) == !
    @test @inferred(getargs(notfxn)) == (+,)
    @test @inferred(getkwargs(notfxn)) == empty_pairs
    @test @inferred(ChainedFixes.positions(notfxn)) == ()
end

@testset "In" begin
    infxn = in(1)
    @test isa(infxn, In)
    @test !isa(+, In)

    @test @inferred(is_fixed_function(typeof(infxn)))
    @test @inferred(getfxn(infxn)) == in
    @test @inferred(getargs(infxn)) == (1,)
    @test @inferred(getkwargs(infxn)) == empty_pairs
end

@testset "NotIn" begin
    notinfxn = !in(1)
    @test isa(notinfxn, NotIn)
    @test !isa(!(==(1)), In)

    @test @inferred(is_fixed_function(typeof(notinfxn)))
    @test @inferred(getfxn(notinfxn)) == !in
    @test @inferred(getargs(notinfxn)) == (1,)
    @test @inferred(getkwargs(notinfxn)) == empty_pairs
end

@testset "Approx" begin
    isapprox_fxn = isapprox(1; atol=2)
    @test isa(isapprox_fxn, Approx)
    @test !isa(!(==(1)), Approx)

    @test @inferred(is_fixed_function(typeof(isapprox_fxn)))
    @test @inferred(getfxn(isapprox_fxn)) == isapprox
    @test @inferred(getargs(isapprox_fxn)) == (1,)
    @test @inferred(getkwargs(isapprox_fxn)) == Pairs((atol=2,),(:atol,))
end

@testset "NotApprox" begin
    notisapprox_fxn = !isapprox(1; atol=2)
    @test isa(notisapprox_fxn, NotApprox)
    @test !isa(!(==(1)), NotApprox)

    @test @inferred(is_fixed_function(typeof(notisapprox_fxn)))
    @test @inferred(getfxn(notisapprox_fxn)) == !isapprox
    @test @inferred(getargs(notisapprox_fxn)) == (1,)
    @test @inferred(getkwargs(notisapprox_fxn)) == Pairs((atol=2,),(:atol,))
end

@testset "Less" begin
    ltfxn = <(1)
    @test isa(ltfxn, Less)
    @test !isa(isapprox(1), Less)

    @test @inferred(is_fixed_function(typeof(ltfxn)))
    @test @inferred(getfxn(ltfxn)) == <
    @test @inferred(getargs(ltfxn)) == (1,)
    @test @inferred(getkwargs(ltfxn)) == empty_pairs
end

@testset "Equal" begin
    eqfxn = ==(1)
    @test isa(eqfxn, Equal)
    @test !isa(isapprox(1), Equal)

    @test @inferred(is_fixed_function(typeof(eqfxn)))
    @test @inferred(getfxn(eqfxn)) == ==
    @test @inferred(getargs(eqfxn)) == (1,)
    @test @inferred(getkwargs(eqfxn)) == empty_pairs
end

@testset "EndsWith" begin
    endswith_fxn = endswith("i")
    @test endswith("i")("hi")
    @test endswith("i") isa EndsWith

    @test @inferred(is_fixed_function(typeof(endswith_fxn)))
    @test @inferred(getfxn(endswith_fxn)) == endswith
    @test @inferred(getargs(endswith_fxn)) == ("i",)
    @test @inferred(getkwargs(endswith_fxn)) == empty_pairs
end

@testset "StartsWith" begin
    startswith_fxn = startswith("h")
    @test startswith("h")("hi")
    @test startswith("h") isa StartsWith

    @test @inferred(is_fixed_function(typeof(startswith_fxn)))
    @test @inferred(getfxn(startswith_fxn)) == startswith
    @test @inferred(getargs(startswith_fxn)) == ("h",)
    @test @inferred(getkwargs(startswith_fxn)) == empty_pairs
end

@testset "and" begin
    @test and(true, <(5))(1)
    @test !and(<(5), false)(1)
    @test and(and(<(5), >(1)), >(2))(3)
    @test and(<(5) ⩓ >(1), >(2))(3)  # ⩓ == \\And

    @test @inferred(and(<=(1), <=(10))) == <=(1)
    @test @inferred(and(<=(10), <=(1))) == <=(1)
    @test @inferred(and(<(1), <(10))) == <(1)
    @test @inferred(and(<(10), <(1))) == <(1)
    @test @inferred(and(>(1), >(10))) == >(10)
    @test @inferred(and(>(10), >(1))) == >(10)
    @test @inferred(and(>=(1), >=(10))) == >=(10)
    @test @inferred(and(>=(10), >=(1))) == >=(10)

    and_fxn = and(true, <(5))
    @test @inferred(is_fixed_function(typeof(and_fxn)))
    @test @inferred(getfxn(and_fxn)) == and
    @test @inferred(getargs(and_fxn)) == (true, <(5))
    @test @inferred(ChainedFixes.positions(and_fxn)) == (1, 2)
end

@testset "or" begin
    @test or(true, <(5))(1)
    @test or(<(5), false)(1)
    @test or(<(5) ⩔ >(1), >(2))(3)  # ⩔ == \\Or
    @test @inferred(or(<(1), <(10))) == <(10)
    @test @inferred(or(<(10), <(1))) == <(10)
    @test @inferred(or(<=(1), <=(10))) == <=(10)
    @test @inferred(or(<=(10), <=(1))) == <=(10)
    @test @inferred(or(>(1), >(10))) == >(1)
    @test @inferred(or(>(10), >(1))) == >(1)
    @test @inferred(or(>=(1), >=(10))) == >=(1)
    @test @inferred(or(>=(10), >=(1))) == >=(1)

    or_fxn = or(true, <(5))
    @test getfxn(or_fxn) == or
    @test getargs(or_fxn) == (true, <(5))
end

fxn1(x::Integer, y::AbstractFloat, z::AbstractString) = Val(1)
fxn1(x::Integer, y::AbstractString, z::AbstractFloat) = Val(2)
fxn1(x::AbstractFloat, y::Integer, z::AbstractString) = Val(3)
fxn1(x::AbstractFloat, y::AbstractString, z::Integer) = Val(4)
fxn1(x::AbstractString, y::Integer, z::AbstractFloat) = Val(5)
fxn1(x::AbstractString, y::AbstractFloat, z::Integer) = Val(6)
fxn2(; x, y, z) = fxn1(x, y, z)
fxn3(args...; kwargs...) = (fxn1(args...), fxn2(; kwargs...))

fix1 = NFix{(1,2)}(fxn1, 1, 2.0)
@test @inferred(fix1("a")) === Val(1)

fix2 = NFix{(1,3)}(fxn1, 1, 2.0)
@test @inferred(fix2("a")) === Val(2)

fix3 = NFix{(1,3)}(fxn1, 1.0, "")
@test @inferred(fix3(2)) === Val(3)

fix4 = NFix{(1,2)}(fxn1, 1.0, "")
@test @inferred(fix4(2)) === Val(4)

fix5 = NFix{(2,3)}(fxn1, 1, 1.0)
@test @inferred(fix5("")) === Val(5)

fix6 = NFix{(1,2,3)}(fxn1, "", 1.0, 1)
@test @inferred(fix6()) === Val(6)

### kwargs
fix7 = NFix(fxn2, x=1, y=2.0)
@test @inferred(fix7(z = "a")) === Val(1)

fix8 = NFix(fxn2, x=1, z=2.0)
@test @inferred(fix8(y="a")) === Val(2)

fix9 = NFix(fxn2, x=1.0, z="")
@test @inferred(fix9(y=2)) === Val(3)

fix10 = NFix(fxn2, x=1.0, y="")
@test @inferred(fix10(z=2)) === Val(4)

fix11 = NFix(fxn2, y=1, z=1.0)
@test @inferred(fix11(x="")) === Val(5)

fix12 = NFix(fxn2, x="", y=1.0, z=1)
@test @inferred(fix12()) === Val(6)

fix13 = NFix{(1,2)}(fxn3, 1, 2.0; x=1.0, z="")
@test @inferred(fix13(""; y = 1)) === (Val{1}(), Val{3}())

# positions must be NTuple{N,Int}
@test_throws ErrorException NFix{(1.0,2,3)}(fxn1, "", 1.0, 1)
# positions aren't sorted
@test_throws ErrorException NFix{(1,3,2)}(fxn1, "", 1.0, 1)
# position and args aren't same length
@test_throws ErrorException NFix{(1,3,2)}(fxn1, "", 1.0)

@test is_fixed_function(fix1)

@test @inferred(ChainedFixes.execute(+, 1, 2)) == 3

@testset "docs" begin
    doctest(ChainedFixes)
end

