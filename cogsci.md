# Notes

When remembering a particular item people draw on context as an additional
source of information (Emin's paper, Ting, Huttenlocher).  Can model this as a
kind of Bayesian cue combination: combine uncertain memory trace (likelihood)
contextual information (prior) to infer the distribution of properties of the
recalled item (posterior).

Begs the question what _is_ context?  It's not handed down by god.  Can think of
this as another level of inference: infer jointly which context a particular
item belongs to, and the likely properties that item had.

We treat multi-context memory as a non-parametric clustering problem: during
encoding, people must infer the _context_ (cluster) that that item belongs to,
which could any of the contexts they have encountered thus far, or a new
context.

## Data

@Robbins2014 - immediate spatial recall task (get methods from Pernille)

## Modeling

Bayesian non-parametric clustering

Use sequential monte carlo.  Why?  Cognitively plausible (online) AND
methodological reasons: 

Need to query model throughout exposure; offline approximations like Gibbs
sampling require multiple sweeps through the data to capture all uncertainty, to
potentially revise previous decisions in light of later data.  In order to query
the model's uncertain beliefs at various points throughout the 

### Encoding (clustering) model

For the clustering component of the model, we used a "Hibachi grill" process
mixture model.  The Hibachi grill process defines a prior distribution on
cluster labels $p(z_1, \ldots, z_n)$ q which is like a standard Dirichlet process with an added (constant)
probability of choosing the same
