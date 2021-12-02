
x = 1:2:9;
y = 9:-2:1;
z = collect(x);

@test @inferred(to_index(x, ==(5))) == findfirst(==(5), x)
@test @inferred(to_index(y, ==(5))) == findfirst(==(5), y)
@test @inferred(to_index(z, ==(5))) == findfirst(==(5), z)

@test @inferred(to_index(x, <=(4))) == findall(<=(4), x)
@test @inferred(to_index(y, <=(4))) == findall(<=(4), y)
@test @inferred(to_index(z, <=(4))) == findall(<=(4), z)

@test @inferred(to_index(x, >=(4))) == findall(>=(4), x)
@test @inferred(to_index(y, >=(4))) == findall(>=(4), y)
@test @inferred(to_index(z, >=(4))) == findall(>=(4), z)

# These should be out of bounds
@test !checkindex(Bool, eachindex(x), @inferred(to_index(x, ==(10))))
@test !checkindex(Bool, eachindex(x), @inferred(to_index(y, ==(10))))
@test !checkindex(Bool, eachindex(x), @inferred(to_index(x, >(9))))
@test !checkindex(Bool, eachindex(x), @inferred(to_index(y, >(9))))
@test !checkindex(Bool, eachindex(x), @inferred(to_index(x, <(1))))
@test !checkindex(Bool, eachindex(x), @inferred(to_index(y, <(1))))

x = [1.5, 2.0, 2.5, 3.0]
@test @inferred(to_index(x, closest(1.6))) == 1
@test @inferred(to_index(x, closest(1.9))) == 2
@test @inferred(to_index(x, closest(2.0))) == 2

