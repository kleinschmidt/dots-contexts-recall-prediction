
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

using JLD2

@load "../prior_empirical.jld2"
@load "../data/dots2014.jld2"

expts = experiments(data = [recall],
                    prior = [prior_optimized],
                    α = [0.1, 1.0, 10.0],
                    ρ = [0.1, 0.5, 0.9],
                    n = [10, 100],
                    Sσ = [0.01, 0.1, 1.0].^2,
                    batch = [:run1])

res1 = run(runner, expts[1])

res1_again = fetch(@spawn run(runner, expts[1]))

res12 = pmap(expts[1:2]) do ex
    run(runner, ex)
end

run1_results = pmap(expts) do ex run(runner, ex) end
@save "../results/run1.jld2" run1_results expts
