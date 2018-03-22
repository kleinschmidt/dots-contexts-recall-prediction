# Data from Pernille's experiment on dot memory and prediction

Dots appear in a circle.  Recall task and prediction task.  Each circle is a
context, and context has specific distribution of radii and angles.  Varying
clustering (run length), and contexts re-occur throughout the experiment.

Idea is to use non-parametric online clustering model: learn the number of
contexts and their properties.  Doing it exactly right would be tricky but
could do a mixture of 2D Gaussians.  Also tricky to work in the run-length.
Well easy in principle but kind of hard to do in practice (that's a parameter of
the model so you'd need to build in a parameter learning thing too...)

why's this interesting?  nonparametric bayesian model of how people can learn
the structure of a task environment as they go.  SMC is good for this because
it's an _online_ algorithm, which has two distinct advantages here: 1)
psychologically plausible, and 2) corresponds to the incremental nature of the
task, making it easier to model the sequential dependencies (harder to do with
batch MCMC algorithms).



