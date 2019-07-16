using Distributions,
    Plots,
    StatsPlots



td = TDist(2)


plot(x -> logpdf(td, x), -5:0.1:5)
plot!(x -> logpdf(Normal(-2, 1), x))




plot(x -> logpdf(td, x), -5:0.1:5)

p = plot(td, -5:.1:5)
for σ in [0.01, 0.1, 1]
    plot!(p, x -> pdf(Normal(2., σ), x)*pdf(td, x), -5:0.1:5, label="\\sigma=$σ")
end
p


p = plot(td, -5:.1:5)
for σ in [0.1, 0.5, 1, 2]
    plot!(p, x -> pdf(Normal(2., 1), x)*pdf(LocationScale(0., σ, td), x), -5:0.1:5, label="\\sigma=$σ")
end
p


p = plot(td, -5:.1:5)
for σ in [0.1, 0.5, 1, 2]
    plot!(p, x -> pdf(Normal(2., σ), x)*pdf(LocationScale(0., σ, td), x), -5:0.1:5, label="\\sigma=$σ")
end
p



x = -2:.1:9
p = plot(td, x)
for σ in [0.1, 0.5, 1, 2]
    y = pdf.(Normal(4, σ), x) .* pdf.(LocationScale(0., σ, td), x)
    ∫y = sum((y[1:end-1] .+ y[2:end])./2 .* diff(x))
    plot!(p, x, y./∫y, label="\\sigma=$σ")
end
p



using FastGaussQuadrature, ApproxFun

function trapezoid(x, f)
    y = f.(x)
    ∫y = sum((y[1:end-1] .+ y[2:end])./2 .* diff(x))
end

x = -10:.01:10

# change of variables to make gauss hermite nodes/weights work for normal dist
import FastGaussQuadrature: gausshermite
function gausshermite (n, d::Normal)
    x, w = gausshermite(n)
    √2 .* x .* d.σ .+ d.μ, w ./ √π
end
    

for σ in [0.1, 0.5, 1, 2]

    tdd = LocationScale(0., σ, td)
    no = Normal(4, σ)
    f = x -> pdf(no, x) * pdf(tdd, x)
    ∫f_trap = trapezoid(-20:.01:20, f)

    f̂ = Fun(f, -10..10)
    ∫f̂ = cumsum(f̂) + f̂(-10)
    ∫f̂_cheb = ∫f̂(10)

    println("σ = $σ, ∫f_trap = $(∫f_trap)\n  Δ∫f̂_cheb: $(∫f_trap - ∫f̂_cheb)")    

    for n in [3, 10, 30, 100, 300, 1000]
        nodes, w = gausshermite(n, no)
        ∫f̂_gauss_hermite = dot(w, pdf.(tdd, nodes))
        println("  n = $n, Δ∫f̂_gauss_hermite = $(∫f̂_gauss_hermite - ∫f_trap)")
    end
    
end

# Approximation looks quite good actually, even with a small number of points!
# As I suspected, it's dominated by the likelihood when the space between the
# modes is high.

# Multivariate guass-hermite using spectral decomposition/rotation:
function gausshermite(n, d::MvNormal)
    dims,  = size(d)
    x, w = gausshermite(n)
    
    vals, vecs = eigen(d.Σ.mat)
    rot = vecs * diagm(0=>sqrt.(vals))

    xx = d.μ .+ √2 .* rot * reduce(hcat, [collect(x) for x in Iterators.product(repeat([x], dims)...)])
    ww = vec([prod(w) for w in Iterators.product(repeat([w], dims)...)]) ./ π^(dims/2)

    xx, ww
end

# then you use this like
# xx, ww = gausshermite(n, d)
# pdf(pp, y_recalled) * pdf(d, y_recalled) / dot(ww, pdf(pp, xx))
