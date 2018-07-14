
@everywhere using
    DataFrames,
    DataFramesMeta,
    Underscore,
    Particles,
    Distributions,
    ConjugatePriors,
    JuliennedArrays,
    StatsBase

@everywhere include("../modeling.jl")
@everywhere include("../experiments.jl")

@everywhere function runner(params::Dict, data)
    res = DataFrames.by(data, :subjid1) do d
        DotLearning.model_recall(
            d,
            Particles.ChenLiuParticles(params[:n],
                                       params[:prior],
                                       Particles.StickyCRP(params[:α], params[:ρ])),
            Matrix(params[:Sσ]*I, 2,2),
            add=false
        )
    end
    println("$params => mse=$(mse(data, res)), cosine=$(cosinedist(data, res))")
    return res
end

using JLD2

@load "../prior_empirical.jld2"
@load "../data/dots2014.jld2"

expts = experiments(recall,
                    prior = [prior_optimized],
                    α = [0.01, 0.1, 1.0, 10.0],
                    ρ = [0.1, 0.5, 0.9],
                    n = [100],
                    Sσ = [0.01, 0.1, 1.0].^2,
                    batch = [:run2],
                    iter = [1:10;])


results = pmap(expts) do ex run(runner, ex) end
@save "../results/run2.jld2" results expts
