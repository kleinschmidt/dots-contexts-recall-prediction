# copy of run 3, using fearnhead filter 

using Distributed, Dates
batch = :run5

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
        JuliennedArrays,
        StatsBase,
        LinearAlgebra

    include("../modeling.jl")
    include("../experiments.jl")
    using .Experiments

    function recall_predict(params::Dict, rp_data)
        println(join(["$k=>$v" for (k,v) in params if k != :prior], ", "))
        
        map(rp_data...) do recall, pred
            ps =  Particles.FearnheadParticles(params[:n],
                                               params[:prior],
                                               Particles.StickyCRP(params[:α], params[:ρ]))

            # set up recall model
            rf = DotLearning.RecallFilter(ps, Matrix(params[:Sσ]I, 2, 2))

            # set up prediction points and distances (wraps recall model)
            pf = DotLearning.PredictionFilter(rf, pred[:respnr], pred[:pred], 100)

            filter!(pf, recall)

            recalled = DataFrame(rf)
            predicted = DataFrame(pf)

            recalled, predicted
        end
    end
end

using JLD2

# @load "../prior_empirical.jld2"
# load parameters to get around LinAlg → LinearAlgebra rename
@load "../prior_empirical_params.jld2"
prior_optimized = NormalInverseWishart(μ, κ, Λ, ν)

@load "../data/dots2014.jld2"


pred[:respnr] = round.(Int, pred[:respnr]);
pred[:pred] = round.(Int, pred[:pred]);

subjs = unique(recall[:subjid1])

viewby(df, col, val) = view(df, df[col] .== val, :)

recall_bysub = viewby.(Ref(recall), :subjid1, subjs);
pred_bysub = viewby.(Ref(pred), :subjid1, subjs);

expts = experiments((recall_bysub, pred_bysub),
                    prior = [prior_optimized],
                    α = [0.01, 0.1, 1.0, 10.0],
                    ρ = [0.1, 0.5, 0.9],
                    n = [100],
                    Sσ = [0.01, 0.1, 1.0].^2,
                    batch = [batch],
                    iter = [1:10;])


results = pmap(expts) do ex run(recall_predict, ex) end
@save "../results/$batch-$(DateTime(now())).jld2" expts results recall_predict, typeof(recall_predict)
