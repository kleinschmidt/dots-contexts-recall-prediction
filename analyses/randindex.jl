# compute the Adjusted Rand Index for clusters

using Distributed, Dates
batch = :randindex

# setup:
@everywhere begin
    using Pkg
    Pkg.activate("..")

    using DataFrames,
        DataFramesMeta,
        Underscore,
        Particles,
        Distributions,
        ConjugatePriors,
        StatsBase,
        LinearAlgebra

    include("../modeling.jl")
    include("../experiments.jl")
    using .Experiments
    using .DotLearning
    
    function ari(params::Dict, data)
        println("α=$(params[:α]), ρ=$(params[:ρ]), iter=$(params[:iter])")
        ps_factory = () -> FearnheadParticles(params[:n],
                                              params[:prior],
                                              StickyCRP(params[:α], params[:ρ]))
        by(data,
           :subjid1,
           ari = (:x, :y, :block) => d -> randindex(filter!(ps_factory(),
                                                            extract_data(d),
                                                            false),
                                                    d.block,
                                                    :adjusted))
    end

end




using JLD2

# @load "../prior_empirical.jld2"
# load parameters to get around LinAlg → LinearAlgebra rename
@load "../prior_empirical_params.jld2"
prior_optimized = NormalInverseWishart(μ, κ, Λ, ν)

@load "../data/dots2014.jld2"



expts = experiments(recall,
                    prior = [prior_optimized],
                    α = [0.01, 0.1, 1.0, 10.0],
                    ρ = [0.1, 0.5, 0.9],
                    n = [100],
                    batch = [batch],
                    iter = [1:20;])


using .Experiments: add_params!

results = pmap(expts) do ex run(ari, ex) end

results_df = mapreduce(res -> add_params!(res.result, res.experiment.params), vcat, results);

@save "../results/$batch-$(DateTime(now())).jld2" expts results results_df
