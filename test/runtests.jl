using Test, ChainedFixes

@testset "Not" begin
    @test isa(!(+), Not)
    @test !isa(+, Not)
end

@testset "In" begin
    @test isa(in(1), In)
    @test !isa(+, In)
end

@testset "NotIn" begin
    @test isa(!in(1), NotIn)
    @test !isa(!(==(1)), In)
end

@testset "Approx" begin
    @test isa(isapprox(1), Approx)
    @test !isa(!(==(1)), Approx)
end

@testset "NotApprox" begin
    @test isa(!isapprox(1), NotApprox)
    @test !isa(isapprox(1), NotApprox)
end

@testset "Less" begin
    @test isa(<(1), Less)
    @test !isa(isapprox(1), Less)
end

@testset "Equal" begin
    @test isa(==(1), Equal)
    @test !isa(isapprox(1), Equal)
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
end

@testset "or" begin
    @test or(true, <(5))(1)
    @test or(<(5), false)(1)
    @test or(<(5) ⩔ >(1), >(2))(3)  # ⩔ == \\Or
    @test @inferred(or(<(1), <(10))) == <(10)
    @test @inferred(or(<(10), <(1))) == <(10)
    @test @inferred(or(<=(1), <=(10))) == <=(10)
    @test @inferred(or(<=(10), <=(1))) == <=(10)
end
