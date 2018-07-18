################################################################################
# Dave Kleinschmidt, 2018
################################################################################

module DotLearning

using
    DataFrames,
    DataFramesMeta,
    Underscore,
    Particles,
    Distributions,
    ConjugatePriors,
    JuliennedArrays,
    StatsBase

using ConjugatePriors:
    NormalInverseWishart,
    posterior

import Base.filter!

export
    RecallFilter,
    KnownFilter,
    recall_est,
    model_recall

################################################################################
# Modeling recall

using Distributions: MvNormalStats

ConjugatePriors.posterior(c::Component) = ConjugatePriors.posterior(c.prior, c.suffstats)

# uses the expected covariance matrix
function recall_est(x::AbstractVector{Float64}, Sx::Matrix{Float64}, c::Component{NormalInverseWishart{Float64}}) 
    Sinv_x = inv(Sx)
    post = posterior(c)
    Sinv_mem = full(inv(post.Lamchol)) .* (post.kappa / (1+post.kappa) * (post.nu - post.dim + 1))
    Sinv_total = Sinv_x + Sinv_mem
    return Sinv_total \ (Sinv_mem * post.mu + Sinv_x * x)
end

 
# This ONLY MAKES SENSE when x is the last datapoint fit (e.g., as a callback from filter!)
#
# strategy is to create a filter type to enforce this restriction:

recall_est(x::AbstractVector, Sx::Matrix, p::Particles.AbstractParticle) =
    recall_est(x, Sx, p.components[p.assignment])

function recall_est(x::AbstractVector, Sx::Matrix, ps::ParticleFilter)
    xy_recalled = mapreduce(p -> recall_est(x, Sx, p) .* weight(p), +, particles(ps))
    xy_recalled ./= sum(weight.(particles(ps)))
    return xy_recalled
end

mutable struct RecallFilter{P} <: Particles.ParticleFilter
    particles::P
    Sx::Matrix{Float64}
    recalled::Vector{Vector{Float64}}
end

RecallFilter(particles::ParticleFilter, Sx::Matrix{Float64}) =
    RecallFilter(particles, Sx, Vector{Vector{Float64}}())

Particles.particles(rf::RecallFilter) = particles(rf.particles)

extract_data(d::AbstractDataFrame, rf::RecallFilter) = extract_data(d, rf.particles)

# I'm not sure if the anonymous function here is a performance gotcha.  Didn't
# seem like it in my playing around but you never know.
function filter!(rf::RecallFilter, xys::AbstractVector; progress=true)
    callback = (p, x) -> push!(rf.recalled, recall_est(x, rf.Sx, p))
    filter!(rf.particles, xys, progress, cb=callback)
    rf
end

################################################################################
# Running on actual data frame:

# data needs to have columns :x and :y
extract_data(d::AbstractDataFrame, ps::ParticleFilter) =
    map(vec, julienne(hcat(d[:x], d[:y]), (*,:)))

function model_recall(d::AbstractDataFrame, ps::ParticleFilter, Sx::Matrix; add=true)
    xy_vecs = extract_data(d, ps)
    ps = filter!(RecallFilter(ps, Sx), xy_vecs, progress=false)
    recalled = DataFrame(x_mod = first.(ps.recalled),
                         y_mod = last.(ps.recalled),
                         rho_mod = norm.(ps.recalled))
    return add ? hcat(d, recalled) : recalled
end

################################################################################
# A "filter" where the category is known

mutable struct KnownFilter{P} <: ParticleFilter
    p::P
end

KnownFilter(prior::Distribution) = KnownFilter(InfiniteParticle(prior, ChineseRestaurantProcess(1.0)))

Particles.particles(ps::KnownFilter) = [ps.p]

function StatsBase.fit!(ps::KnownFilter, yi::Tuple{T, Int}) where T
    ps.p = fit(ps.p, yi...)
    ps
end

recall_est(xyi::Tuple{AbstractVector, Int}, Sx, ps) = recall_est(xyi[1], Sx, ps)

extract_data(d::AbstractDataFrame, ps::KnownFilter) = 
    @with d map((x,y,i) -> ([x,y], round(Int, i)), :x, :y, :block)


################################################################################
# Modeling prediction
#
# We can compose the recall and prediction tasks because we have RecallFilter
# which behaves like a particle filter as far as anyone else is concerned
mutable struct PredictionFilter{P}
    particles::P
    pred_points::AbstractVector{Int}
    pred_delays::AbstractVector{Int}
    n_samples::Int
    predictions::Vector{Vector{Vector{Float64}}}
end

PredictionFilter(particles::P, pred_points::AbstractVector{Int}, pred_delays::AbstractVector{Int}, n_samples::Int) where P<:ParticleFilter =
    PredictionFilter(particles, pred_points, pred_delays, n_samples, Vector{Vector{Vector{Float64}}}())

function rand_posterior_future(pf::ParticleFilter, t::Int)
    ps = particles(pf)
    p = sample(ps, Weights(weight.(ps)))
    sp = p.stateprior
    state = min(last(last(Particles.simulate(sp, t))), maximum(Particles.candidates(sp)))
    rand(posterior_predictive(components(p)[state]))
end

rand_posterior_future(pf::ParticleFilter, t::Int, n::Int) =
    [rand_posterior_future(pf, t) for _ in 1:n]

function filter!(pf::PredictionFilter, data::AbstractDataFrame)
    ranges = accumulate( (ran, idx) -> ran.stop+1:idx, 0:0, pf.pred_points)
    data_views = view.((datavecs, ), ranges)
    for (dat, t) in zip(data_views, pf.pred_delays)
        filter!(pf.particles, dat)
        pred_samples = rand_posterior_future(pf.particles, t, pf.n_samples)
        push!(pf.predictions, pred_samples)
    end
    return pf
end


end
