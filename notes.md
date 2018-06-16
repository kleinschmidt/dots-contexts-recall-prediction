# Data from Pernille's experiment on dot memory and prediction

Dots ("moles") appear in a circle ("garden").  Recall task and prediction task.
Latent contexts, and each context has specific distribution of radii and angles.
Varying clustering (run length), and contexts re-occur throughout the
experiment.

Idea is to use non-parametric online clustering model: learn the number of
contexts and their properties.  Also tricky to work in the run-length.  Well
easy in principle but kind of hard to do in practice (that's a parameter of the
model so you'd need to build in a parameter learning thing too...)

why's this interesting?  nonparametric bayesian model of how people can learn
the structure of a task environment as they go.  SMC is good for this because
it's an _online_ algorithm, which has two distinct advantages here: 1)
psychologically plausible, and 2) corresponds to the incremental nature of the
task, making it easier to model the sequential dependencies (harder to do with
batch MCMC algorithms).

# Modeling

## Number of contexts and how often they re-occur

It's not clear to me how often a particular context re-occurs exactly for a
subject.  If they don't re-occur, then this model doesn't really make much sense

## Sticky DP-HMM

Want to build in (and learn) a prior on the probability of a self-transition
(stickiness).  Hard to do this online...similar difficulty of inferring the
concentration parameter for the dirichlet process.  The way to handle this (I
think) is to vary these parameters over particles.  Then...update when adding
new data?  Or rejuvenating?  Or not at all?

Without stickiness, sampling a new value of α is pretty easy via MH, since it
only depends on the counts: p(α | c) ∝ p(c | α) p(α), and 

  p(c | α) ∝ ∏ₖ α(Nₖ-1)! ∝ αᵏ

where c ∈ {1..k} and Nₖ is the count assigned to category k.  This means that
p(α | c) / p(α' | c) = αᵏ / (α')ᵏ = (α/α')ᵏ

With stickiness it's more complicated because when you stay on the same
component, it's ambiguous whether you stayed there because of the stickiness or
because you chose a new one.  One way around is the Fox et al. latent variable
approach, where you have another variable that's an indicator for whether you
stuck or not.  In which case you just don't count that one towards the CRP...

Actually this has nothing to do with the MH step, and everything to do with the
prior itself.  Because this changes how you count cluster assignments: it's by
_run_ instead of by _token_.  Although maybe you can do some kind of fractional
count thing, which maybe would be equivalent to marginalizing over that latent
variable?  But it's straightforward to do it with the latent variable sort of
model so best not to worry too much...especially since that's more aligned with
the psychological plausibility.

### Sticky prior with indicator variable

So under this model the prior is 

  p(cₙ | sₙ, c₁...c_{n-1}, α) ∝ 1 if cₙ=c_{n-1}, 0 otherwise (sₙ=1, sticky)
                               Nₖ for 1..k, α for k+1 (sₙ=0, non-sticky)

and p(sₙ=1 | κ) = κ.  Nₖ is the (modified) cluster size for cluster k, where
"sticky" observations are ignored: Nₖ = ∑ₙ I(cₙ=k)×I(sₙ=0).

### Sticky prior marginalizing over indicator:

Could combine these two to marginalize: 
  p(cₙ=k | c₁..c_{n-1}, α, κ) ∝ Nₖ+(N+α)κ for k=c_{n-1}
                                α for K+1
                                Nₖ otherwise

where the constant of proportionality is (N+α)(1+κ).  The question here is how
to define/compute Nₖ.

### Updating κ and α

The α update is the same regardless (just depends on the number of clusters).
