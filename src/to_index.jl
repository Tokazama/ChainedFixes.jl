
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
@inline ArrayInterface.to_index(x, i::Union{<:Approx{T},<:Equal{T}}) where {T} = _findeq(x, i)
_findeq(x::AbstractRange, i) = Int(div(getfield(getargs(i), 1) - first(x), step(x))) + 1
function _findeq(x, i)::Int where {T}
    index = findfirst(i, x)
    if index === nothing
        return lastindex(x) + 1
    else
        return Int(index)
    end
end

## Greater/GreaterThanOrEqual
ArrayInterface.to_index(x, i::Greater{T}) where {T} = _findall_gt_ge(x, i)
ArrayInterface.to_index(x, i::GreaterThanOrEqual{T}) where {T} = _findall_gt_ge(x, i)
_findall_gt_ge(x, v) = findall(v, x)
@inline function _findall_gt_ge(x::AbstractRange, v)
    if step(x) > 0
        start = findfirst(v, x)
        stop = lastindex(x)
        if start === nothing
            return stop:(stop - 1)
        else
            return start:stop
        end
    else
        start = firstindex(x)
        stop = findlast(v, x)
        if stop === nothing
            return (start + 1):start
        else
            return start:stop
        end
    end
end

# Less/LessThanOrEqual
ArrayInterface.to_index(x, i::Less{T}) where {T} = _findall_lt_le(x, i)
ArrayInterface.to_index(x, i::LessThanOrEqual{T}) where {T} = _findall_lt_le(x, i)
_findall_lt_le(x, v) = findall(v, x)
@inline function _findall_lt_le(x::AbstractRange, v)
    if step(x) > 0
        start = firstindex(x)
        stop = findlast(v, x)
        if start === nothing
            return (start + 1):start
        else
            return start:stop
        end
    else
        start = findfirst(v, x)
        stop = lastindex(x)
        if stop === nothing
            return stop:(stop - 1)
        else
            return start:stop
        end
    end
end

ArrayInterface.to_index(x, i::Fix2{F,T}) where {F,T} = findall(i, x)

