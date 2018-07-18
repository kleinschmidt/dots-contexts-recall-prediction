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
