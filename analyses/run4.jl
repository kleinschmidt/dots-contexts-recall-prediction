
@everywhere using
    DataFrames,
    DataFramesMeta,
    Underscore,
    Particles,
    Distributions,
    ConjugatePriors,
    JuliennedArrays,
    StatsBase

@everywhere using ConjugatePriors: NormalInverseWishart

@everywhere include("../modeling.jl")
@everywhere include("../experiments.jl")

@everywhere function recall_predict(params::Dict, rp_data,
                                    result_f=pf->(DataFrame(pf.particles), DataFrame(pf)))
    println(join(["$k=>$v" for (k,v) in params if k != :prior], ", "))
    
    map(rp_data...) do recall, pred
        ps =  Particles.ChenLiuParticles(params[:n],
                                         params[:prior],
                                         Particles.StickyCRP(params[:α], params[:ρ]))

        # set up recall model
        rf = DotLearning.RecallFilter(ps, eye(2)*params[:Sσ])

        # set up prediction points and distances (wraps recall model)
        pf = DotLearning.PredictionFilter(rf, pred[:respnr], pred[:pred], 100)

        filter!(pf, recall)

        result_f(pf)
    end

end

using JLD2

@load "../data/dots2014.jld2"

pred[:respnr] = round.(Int, pred[:respnr])
pred[:pred] = round.(Int, pred[:pred])

subjs = unique(recall[:subjid1])

viewby(df, col, val) = view(df, df[col] .== val)
recall_bysub = viewby.(recall, :subjid1, subjs)
pred_bysub = viewby.(pred, :subjid1, subjs)

expts = experiments((recall_bysub, pred_bysub),
                    prior = [NormalInverseWishart(zeros(2), 0.1, eye(2)*0.1*3, 3.)],
                    α = [0.01, 0.1, 1.0, 10.0],
                    ρ = [0.1, 0.5, 0.9],
                    n = [100],
                    Sσ = [0.01, 0.1, 1.0].^2,
                    batch = [:run4],
                    iter = [1:10;])


results = pmap(expts) do ex run(recall_predict, ex) end
@save "../results/run4-$(DateTime(now())).jld2" expts results recall_predict, typeof(recall_predict)
