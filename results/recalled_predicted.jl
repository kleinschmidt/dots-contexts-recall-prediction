# extract DataFrames of recalled/predicted from results files

Revise.track("modeling.jl")
using .DotLearning
Revise.track("experiments.jl")
using .Experiments

using JLD2, DataFrames, Underscore, DataFramesMeta

# result:
#   .experiment:
#     .data:
#     - (recall1, recall2, ...)
#     - (pred1, pred2, ...)
#   .result
#   - (recalled1, predicted1)
#   - (recalled2, predicted2)
#   - ...

function add_params!(df::AbstractDataFrame, params)
    for (k,v) in params
        df[k] = v
    end
    df
end

# extract input data (which is by subject) and predictions
recalled(r) =
    add_params!(hcat(vcat(r.experiment.data[1]...),
                     vcat(first.(r.result)...)),
                r.experiment.params)

recalled(e, r) =
    add_params!(hcat(reduce(vcat, e.data[1]),
                     reduce(vcat, first.(r))),
                e.params)

predicted(r) =
    add_params!(hcat(vcat(r.experiment.data[2]...),
                     vcat(last.(r.result)...)[[:xys_mod]]),
                r.experiment.params)

predicted(e, r) =
    add_params!(hcat(reduce(vcat, e.data[2]),
                     reduce(vcat, last.(r))[[:xys_mod]]),
                r.experiment.params)

function save_recalled_predicted(f::AbstractString)
    expts, results = jldopen(f, "r") do file
        file["expts"], file["results"]
    end
    basename, ext = splitext(f)
    jldopen(basename * "-recalled-predicted" * ext, "w") do file
        recalled_all = reduce(vcat, map(recalled, expts, results))
        predicted_all = @_ mapreduce(predicted, vcat, results) |>
            @by(_, [:subjid1, :block, :respnr, :pred, :theta_resp, :rho_resp, :α, :ρ],
                xys_mod = Ref(reduce(vcat, :xys_mod))) |>
            @transform(_, subjid1 = Int.(:subjid1),
                       block = Int.(:block), 
                       respnr = Int.(:respnr),
                       x_resp = cos.(:theta_resp) .* :rho_resp./2π,
                       y_resp = sin.(:theta_resp) .* :rho_resp./2π,
                       xys_mod = map(getindex, :xys_mod))
        file["recalled_all"] = recalled_all
        file["predicted_all"] = predicted_all
    end
end
