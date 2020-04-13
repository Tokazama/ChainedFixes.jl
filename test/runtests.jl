using Test, ChainedFixes

@test and(true, <(5))(1)
@test !and(<(5), false)(1)
@test and(and(<(5), >(1)), >(2))(3)
@test and(<(5) ⩓ >(1), >(2))(3)  # ⩓ == \\And

@test or(true, <(5))(1)
@test or(<(5), false)(1)
@test or(<(5) ⩔ >(1), >(2))(3)  # ⩔ == \\Or

