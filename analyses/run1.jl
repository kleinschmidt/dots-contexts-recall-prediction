
using
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

using JLD2

@load "../prior_empirical.jld2"
@load "../data/dots2014.jld2"

@everywhere function runner(params::Dict)
    DataFrames.by(params[:data], :subjid1) do d
        DotLearning.model_recall(d,
                                 Particles.ChenLiuParticles(params[:n],
                                                  params[:prior],
                                                  Particles.StickyCRP(params[:α], params[:ρ])),
                                 Matrix(params[:Sσ]*I, 2,2),
                                 add=false)
    end
end

expts = experiments(data = [recall],
                    prior = [prior_optimized],
                    α = [0.1, 1.0, 10.0],
                    ρ = [0.1, 0.5, 0.9],
                    n = [10, 100],
                    Sσ = [0.01, 0.1, 1.0].^2)

res1 = run(runner, expts[1])

res2 = fetch(@spawn run(runner, expts[2]))
res2_again = run(runner, expts[2])

