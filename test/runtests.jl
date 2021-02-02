using Test
using ChainedFixes
using ChainedFixes.ChainedCore
using Documenter
using Base: Fix1

empty_named_tuple = NamedTuple{(),Tuple{}}(())

@test @inferred(getfxn(1)) == identity
@test @inferred(getfxn(+)) == +

@test !is_fixed_function(1)

@testset "Fix1" begin
    fix1_fxn = Fix1(<, 1)
    @test is_fixed_function(typeof(fix1_fxn))
    @test @inferred(getargs(fix1_fxn)) == (1,)
    @test @inferred(getfxn(fix1_fxn)) == <
    @test @inferred(getkwargs(fix1_fxn)) == empty_named_tuple
end

@testset "Not" begin
    notfxn = !(+)
    @test isa(notfxn, Not)
    @test !isa(+, Not)
    @test @inferred(is_fixed_function(typeof(notfxn)))
    @test @inferred(getfxn(notfxn)) == !
    @test @inferred(getargs(notfxn)) == (+,)
    @test @inferred(getkwargs(notfxn)) == empty_named_tuple
end

@testset "In" begin
    infxn = in(1)
    @test isa(infxn, In)
    @test !isa(+, In)

    @test @inferred(is_fixed_function(typeof(infxn)))
    @test @inferred(getfxn(infxn)) == in
    @test @inferred(getargs(infxn)) == (1,)
    @test @inferred(getkwargs(infxn)) == empty_named_tuple
end

@testset "NotIn" begin
    notinfxn = !in(1)
    @test isa(notinfxn, NotIn)
    @test !isa(!(==(1)), In)

    @test @inferred(is_fixed_function(typeof(notinfxn)))
    @test @inferred(getfxn(notinfxn)) == !
    @test @inferred(getargs(notinfxn)) == (in(1),)
    @test @inferred(getkwargs(notinfxn)) == empty_named_tuple
end

@testset "Approx" begin
    isapprox_fxn = isapprox(1; atol=2)
    @test isa(isapprox_fxn, Approx)
    @test !isa(!(==(1)), Approx)

    @test @inferred(is_fixed_function(typeof(isapprox_fxn)))
    @test @inferred(getfxn(isapprox_fxn)) == isapprox
    @test @inferred(getargs(isapprox_fxn)) == (1,)
    @test @inferred(getkwargs(isapprox_fxn)) == (atol=2,)
end

@testset "NotApprox" begin
    notisapprox_fxn = !isapprox(1; atol=2)
    @test isa(notisapprox_fxn, NotApprox)
    @test !isa(!(==(1)), NotApprox)

    @test @inferred(is_fixed_function(typeof(notisapprox_fxn)))
    @test @inferred(getfxn(notisapprox_fxn)) == !
    @test @inferred(getargs(notisapprox_fxn)) == (isapprox(1; atol=2),)
end

@testset "Less" begin
    ltfxn = <(1)
    @test isa(ltfxn, Less)
    @test !isa(isapprox(1), Less)

    @test @inferred(is_fixed_function(typeof(ltfxn)))
    @test @inferred(getfxn(ltfxn)) == <
    @test @inferred(getargs(ltfxn)) == (1,)
    @test @inferred(getkwargs(ltfxn)) == empty_named_tuple
end

@testset "Equal" begin
    eqfxn = ==(1)
    @test isa(eqfxn, Equal)
    @test !isa(isapprox(1), Equal)

    @test @inferred(is_fixed_function(typeof(eqfxn)))
    @test @inferred(getfxn(eqfxn)) == ==
    @test @inferred(getargs(eqfxn)) == (1,)
    @test @inferred(getkwargs(eqfxn)) == empty_named_tuple
end

@testset "EndsWith" begin
    endswith_fxn = endswith("i")
    @test endswith("i")("hi")
    @test endswith("i") isa EndsWith

    @test @inferred(is_fixed_function(typeof(endswith_fxn)))
    @test @inferred(getfxn(endswith_fxn)) == endswith
    @test @inferred(getargs(endswith_fxn)) == ("i",)
    @test @inferred(getkwargs(endswith_fxn)) == empty_named_tuple
end

@testset "StartsWith" begin
    startswith_fxn = startswith("h")
    @test startswith("h")("hi")
    @test startswith("h") isa StartsWith

    @test @inferred(is_fixed_function(typeof(startswith_fxn)))
    @test @inferred(getfxn(startswith_fxn)) == startswith
    @test @inferred(getargs(startswith_fxn)) == ("h",)
    @test @inferred(getkwargs(startswith_fxn)) == empty_named_tuple
end

@testset "and" begin
    @test and(true, <(5))(1)
    @test !and(<(5), false)(1)
    @test and(and(<(5), >(1)), >(2))(3)
    @test and(<(5) ⩓ >(1), >(2))(3)  # ⩓ == \\And

    @test @inferred(and(true, true))
    @test !@inferred(and(false, false, ==(true)))
    @test !@inferred(and(false, ==(true), false))
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

    @test_throws MethodError and(true, true, true)
end

@testset "or" begin
    @test or(true, <(5))(1)
    @test or(<(5), false)(1)
    @test or(<(5) ⩔ >(1), >(2))(3)  # ⩔ == \\Or
    @test @inferred(or(true, false, ==(true)))
    @test @inferred(or(true, false))
    @test @inferred(or(false, ==(true), true))
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
    @test_throws MethodError or(true, true, true)
end

@test ChainedFixes.ArgPosition(1) === ChainedFixes.ArgPosition{1}()

fxn1(x::Integer, y::AbstractFloat, z::AbstractString) = Val(1)
fxn1(x::Integer, y::AbstractString, z::AbstractFloat) = Val(2)
fxn1(x::AbstractFloat, y::Integer, z::AbstractString) = Val(3)
fxn1(x::AbstractFloat, y::AbstractString, z::Integer) = Val(4)
fxn1(x::AbstractString, y::Integer, z::AbstractFloat) = Val(5)
fxn1(x::AbstractString, y::AbstractFloat, z::Integer) = Val(6)
fxn2(; x, y, z) = fxn1(x, y, z)
fxn3(args...; kwargs...) = (fxn1(args...), fxn2(; kwargs...))

f = @nfix fxn1(1, 2.0, _)
@test @inferred(f("a")) == Val{1}()
@test @inferred(is_fixed_function(typeof(f)))

f = @nfix fxn1(1, _, 2.0)
@test @inferred(f("a")) == Val{2}()

f = @nfix fxn1(1.0, _, "")
@test @inferred(f(2)) == Val{3}()

f = @nfix fxn2(x=1, y=2.0)
@test @inferred(f(z = "a")) == Val{1}()

f = @nfix fxn2(x=1, z=2.0)
@test @inferred(f(y = "a")) == Val{2}()

f = @nfix fxn3(1, 2.0, _; x = 1.0, z= "")
@test @inferred(f(""; y = 1)) == (Val{1}(), Val{3}())


f = pipe_chain(@nfix(_ * "is "), @nfix(_ * "a "), @nfix(_ * "sentence."))
@test f("This ") == "This is a sentence."

f2 = pipe_chain(f, endswith("sentence."))
@test f2("This ")

f2 = pipe_chain(f, startswith("This"))
@test f2("This ")

f = pipe_chain(and(<=(3), !=(2)), ==(true), in(trues(2)), !in(falses(2)))
@test f(1)

f = pipe_chain(isapprox(0.1), !isapprox(0.2))
@test f(0.1 - 1e-10)

splat_pipe(op, args::Tuple) = op(args...)
splat_pipe(op) = @nfix splat_pipe(op, _...)
f = pipe_chain(extrema, splat_pipe(+))
@test @inferred(f([1 2; 3 4])) == 5

@testset "docs" begin
    doctest(ChainedFixes)
end

