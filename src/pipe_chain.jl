
"""
    pipe_chain(x, y, z...)

Chain together a 
"""
pipe_chain(x, y, z...) = pipe_chain(x, pipe_chain(y, z...))
pipe_chain(x, y) = ChainedFix(pipe_chain, x, y)

(cf::ChainedFix{typeof(pipe_chain)})(x) = x |> cf.f1 |> cf.f2

const PipeChain{F1,F2} = ChainedFix{typeof(pipe_chain),F1,F2}

