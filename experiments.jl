################################################################################
# module for managing experiments/runs
################################################################################

# need to keep track of
# * parameters
# * data (or hash)
# * random seed
# * what kind of experiment
#
# to be able to
# * run a particular experiment
# * re-run an experiment
# * keep track of "batches" (label)
#
# really nice if
# * checkpointing
# * post-process results
#
# first stage is to just get teh `RecallFilter` for each parameter setting.  Do
# need to worry about making the parameters re-usable across experiment _types_?
# I don't think so...
#
# could use a named tuple to store parameters? or just a dict...
#
# steaps are
#
# 1. specify possible values for each parameters
# 2. convert into unique combinations of parameter values
# 3. for some number of repetitions, set random seed and run (in parallel)
#
# the "running" part here is calling `filter!(RecallFilter(...), data)`.
# everything else can be handled as a post-processing step
#
# really the experiment is a function that maps parameters to a result...
#
# and something that allows you to grab the result.  it's just a sort of
# memoization.

mutable struct Experiment
    params::Dict{Symbol, Any}
    seed::UInt
end

Experiment(params) = Experiment(params, rand(UInt))

Base.show(io::IO, ex::Experiment) =
    print(io, "Experiment(" * join(["$k=$v" for (k,v) in ex.params], ", ") * ")")

mutable struct Result{F,R}
    experiment::Experiment
    runner::F
    result::R
end

Base.show(io::IO, r::Result) =
    print(io, "Result of $(r.experiment): $(r.result)")

function Base.run(f::F, ex::Experiment) where F<:Function
    srand(ex.seed)
    let result
        try
            result = f(ex.params)
        catch e
        result = e
        end
        Result(ex, f, result)
    end
end


"""
    arrayofdicts(d::Dict, k::Symbol)
    arrayofdicts(d::Dict)

Turn a dict of vectors (generally iterables) into an array of dicts.  Every
iterable value becomes a dimension in the resulting array
"""
arrayofdicts(d::Dict{K,V}, k::K) where {K,V} = (setindex!(copy(d), n, k) for n in d[k])
function arrayofdicts(d::Dict)
    (Dict(kv...) for kv in Base.Iterators.product([ (k=>s for s in v) for (k,v) in d ]...))
end

# arrayofdicts(ex::Experiment, k::Symbol) = Experiment.(collect(arrayofdicts(ex.params, k)), ex.seed)

"""
    dictofarrays(ds::Array{Dict{K,V},N}) where {K,V,N}

The opposite of arrayofdicts: take an array of dicts and turn it into a dict of
arrays.

"""
function dictofarrays(ds::Array{Dict{K,V},N}) where {K,V,N}
    d = Dict{K,Any}()
    for k in keys(first(ds))
        d[k] = getindex.(ds, k)
    end
    return d
end


"""
    experiments(params::Dict)
    experiments(; kw...)

Construct an array of experiments from parameter values supplied as a Dict or
keyword arguments.  Each parameter value that's iterable will expand to a
"dimension" of the experiments array.

# Example

    experiments(μ = [-1, 0, 1],
                σ2 = [.1, 1.0, 10.0],
                x = ([1, 2, 3, 4], ))

Produces 9 `Experiment`s, one of each combination of μ and σ2.  Each of these
has the same value of `x`, since it was passed as a vector wrapped in a tuple.

"""
experiments(params::Dict) = [Experiment(d) for d in arrayofdicts(params)]
experiments(; kw...) = experiments(Dict(kw))
