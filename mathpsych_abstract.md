In a noisy but structured world, memory can be improved by enhancing limited
stimulus-specific memory with statistical information about the context.  In
order to do this, people have to be able to learn the statistical structure of
their current environment.  One feature of natural environments is that such
statistical structure is often systematically related to some (possibly latent)
contextual variables.

We present a sequential monte carlo (SMC, or particle filter) model of how
people track the statistical properties of the environment across multiple
contexts.  This model approximates non-parametric Bayesian clustering of
percepts over time, capturing how people impute structure in their perceptual
experience in order to more efficiently encode that experience in memory.  Each
trial is treated as a draw from a context-specific distribution, where the
number of contexts is unknown (and potentially infinite).  The model maintains a
finite set of hypotheses about how the percepts encountered thus far are
assigned to contexts, updating these in parallel as each new percept comes in.

We apply this model to a recall task where subjects had to recall the position
of dots.  Unbeknownst to subjects, each dot appeared in one of a few pre-defined
regions on the screen.  Our model captures subjects' ability to learn
the inventory of contexts, the statistics of dot positions within each context,
and the statistics of transitions between contexts—as reflected in both recall
and prediction.
