using RecipesBase
using Plots
using Colors, Images

show_assignment_similarity(ps, colorf=Gray) = colorf.(assignment_similarity(ps))

# like quiver but with start and end instead of origin and vector
@userplot Arrows
@recipe function f(p::Arrows)
    x, xend, y, yend = p.args
    seriestype := :quiver
    
    quiver := (xend.-x, yend.-y)
    aspect_ratio --> :equal
    x,y
end

# two panel plot of observed and predicted deviations
@userplot ArrowsModResp
@recipe function f(p::ArrowsModResp)
    x, y, x_mod, y_mod, x_resp, y_resp = p.args
    layout := @layout [pred{0.45w} obs]

    size --> (900, 400)
    aspect_ratio --> :equal
    link --> :y
    
    @series begin
        seriestype := :quiver
        subplot := 1
        legend := false
        quiver := (x_mod .- x, y_mod .- y)
        title := "Predicted"
        x,y
    end
    
    @series begin
        seriestype := :quiver
        subplot := 2
        quiver := (x_resp .- x, y_resp .- y)
        title := "Observed"
        x,y
    end
end

@userplot Arena
@recipe function f(p::Arena)

    seriestype --> :scatter
    aspect_ratio --> :equal
    axis --> false
    grid --> false
    legend --> false
    
    x, y = length(p.args)==2 ? p.args : ([], [])
    @series begin
        seriestype --> :scatter
        x,y
    end

    @series begin
        group := nothing
        color := Gray(0.2)
        seriestype := :path
        cos.(linspace(0,2π,200)), sin.(linspace(0,2π,200))
    end
    
end

Plots.group_as_matrix(::Arena) = true
