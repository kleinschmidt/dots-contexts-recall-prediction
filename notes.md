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

### Comparison with HDP-HMM

The Fox et al. model assumes a different transition distribution for every
state, but that seems like overkill.  Ignoring the previous state seems like it
would make the sampling easier since you only need to worry about one transition
at a time (instead of also considering t->t+1).  It also makes it a little hard
to translate their derivations, since the κ comes in at the second level.

I just don't think it matters all that much as a practical matter.  Can just as
easily treat the prior predictive for the next state as a mixture model (stick
or change).

### Sticky prior with indicator variable

So under this model the prior is 

\[
  p(cₙ | sₙ, c₁...c_{n-1}, α) ∝ 1 if cₙ=c_{n-1}, 0 otherwise (sₙ=1, sticky)
                               Nₖ for 1..k, α for k+1 (sₙ=0, non-sticky)
\]

and p(sₙ=1 | κ) = κ.  Nₖ is the (modified) cluster size for cluster k, where
"sticky" observations are ignored: Nₖ = ∑ₙ I(cₙ=k)×I(sₙ=0).

(what I'm calling κ here is really more like ρ from Fox et al.: the probability
of sticking.)

### Sticky prior marginalizing over indicator:

Could combine these two to marginalize?

\[
  p(cₙ=k | c₁..c_{n-1}, α, κ) ∝ Nₖ+(N+α)κ for k=c_{n-1}
                                α for K+1
                                Nₖ otherwise
\]

where the constant of proportionality is (N+α)(1+κ).  The question here is how
to define/compute Nₖ.  I think the way that Fox et al. solve this is by sampling
auxiliary variables for the counts and overrides, conditional on the
assignments.

### Updating κ and α

The α update is the same regardless (just depends on the number of clusters).

To update κ we need to ....

# Planning talk

The overarching point of this project is that

1. people pick up on the _temporal/sequential structure_ of these sequences of
   positions.  They're _looking for structure_.
2. at a high level, can model that search for structure in a bayesian framework:
   have some prior over likely structures and combine that with the data you
   get.
3. but actually _doing_ the inference is really hard...in fact it's intractible.
   But we can _approximate_ it in a psychologically constrained way: online,
   finite set of hypotheses.
   
This model captures the _qualitative patterns_ in peoples behavior: 

* Shrinkage towards expected values in recall.
* stronger shrinkage towards the _overall_ average when less certain about the
  specific context.
* ( more specific predictions when further into a block )

## What is the model

## Does it work

### as an approximation to the true clusters

yes. [assignment similarity plots]

### as a model of human behavior

also yes.  [bias plot]




## outline

* High-level intro: what's the context?  judgements are made _in context_, and
  models of learning/memory need to take that into account
* Specific setting: spatial memory task.  where did mole appear?  unbeknownst to
  people, add sequential structure: disribution of locations changes
  periodically.
    * Evidence for structure sensitivity: recall is _biased_, and it's _biased
      more_ for longer contexts (because need to learn context).
    * Also, prediction.
* Challenge for modeling: computational level, infer latent context variables,
  both number of contexts and properties/assignment of points to contexts
  (bayesian non-parametrics).  but enormous computational complexity (number of
  possible partitions grows > 2^N).  to _implement_ this model at all, need to
  do approximation.
    * `plot of locations partitioned different ways with likelihoods`
* for a cognitive model (at an algorithmic/psychological level), want something
  that's online (not batch), and resource limited (not maintaining full
  posterior uncertainty).
    * SMC: maintain K weighted hypotheses about partitioning (and other
      variables) in parallel (particles)
    * update particles _state_ and _weight_ as new data comes in.
    * periodically replace low-probability particles with copies of
      high-probability particles (rejuvination)
    * (( details: particular algorithm: Chen and Liu (2000) ))
* success or failure is going to depend in large part on the _prior_ on states.
    * standard: CRP (rich get richer).
    * "sticky" CRP to capture sequential dependencies. (with an auxiliary
      variable to keep track of "sticks")
* this does a pretty good job of learning the clusters that are actually present
  in the experiment
    * `plot: assignment similarity of one subject`
* modeling recall: Bayesian cue combination of uncertain memory trace and
  context distribution.
* modeling prediction: sample state forward some number of steps, and sample a
  point from the resulting distribution.
