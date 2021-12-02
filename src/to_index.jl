
# much of this is technically type piracy because ChainedFixes doesn't own `ArrayInterface.to_index`
# or most of this `Base.Fix2` types. Therefore, if there comes a time when this is accepted
# as canonical much of this code should be moved to ArrayInterface

@inline function ArrayInterface.to_index(x, i::Closest{T})::Int where {T}
    idx = i(x)
    if idx === nothing
        return lastindex(x)
    else
        return Int(idx)
    end
end

## findfirst
function ArrayInterface.to_index(x, i::Union{Equal{T},Approx{T}})::Int where {T}
    index = findfirst(i, x)
    if index === nothing
        return firstindex(x) - 1
    else
        return Int(index)
    end
end

## Greater/GreaterThanOrEqual
function ArrayInterface.to_index(x, i::Union{Greater{T},GreaterThanOrEqual{T}}) where {T}
    _findall_gt_ge(x, i)
end
_findall_gt_ge(x, v) = findall(v, x)
@inline function _findall_gt_ge(x::AbstractRange, v)
    if step(x) > 0
        start = findfirst(v, x)
        if start === nothing
            return range(firstindex(x) - 1, length=1)
        else
            return start:lastindex(x)
        end
    else
        stop = findlast(v, x)
        if stop === nothing
            return range(firstindex(x) - 1, length=1)
        else
            return firstindex(x):stop
        end
    end
end

# Less/LessThanOrEqual
function ArrayInterface.to_index(x, i::Union{Less{T},LessThanOrEqual{T}}) where {T}
    _findall_lt_le(x, i)
end
_findall_lt_le(x, v) = findall(v, x)
@inline function _findall_lt_le(x::AbstractRange, v)
    if step(x) > 0
        stop = findlast(v, x)
        if stop === nothing
            return range(firstindex(x) - 1, length=1)
        else
            return firstindex(x):stop
        end
    else
        start = findfirst(v, x)
        if start === nothing
            return range(firstindex(x) - 1, length=1)
        else
            return start:lastindex(x)
        end
    end
end

ArrayInterface.to_index(x, i::Fix2{F,T}) where {F,T} = findall(i, x)

