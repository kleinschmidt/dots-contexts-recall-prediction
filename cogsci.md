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
cluster labels $p(z_1, \ldots, z_n)$ q which is like a standard Dirichlet
process with an additional (constant) probability of choosing the same cluster
as the previous

### Recall

The noisy memory trace is modeled as a normal distribution centered at the
studied location $x$ with an isometric covariance matrix $\Sigma_x$, whose
diagonal elements are all equal to $\sigma^2_x$, which is a free parameter of
the model.  This noisy memory trace is combined with a _context prior_, which is
approximated by the population of particles.  Specifically, each particle $k$
represents one possible assignment of the observations $x_{1:i}$ to clusters
$z^{(k)}_{1:i}$.  We can thus model each particle's context as the expected mean
and covariance matrix for all the points that particle $k$ has assigned to the
same cluster as the studied point $z^{(k)}_i$:

$$\mu^{(k)}_c, \Sigma^{(k)}_c = E(\mu, \Sigma)_{p(\mu, \Sigma | x_{1:i},
  z^{(k)}_{1:i})}$$

Then the best guess of the studied location under particle $k$'s model of the
context is the combination of a normal likelihood (from the noisy trace of the
studied item) and a normal prior (from the context), which works out to be the
inverse variance-weighted average of the two means:

$$
\hat x^{(k)} = ({\Sigma^{(k)}_c}^{-1} + \Sigma_x^{-1})^{-1}
    ({\Sigma^{(k)}_c}^{-1} \mu^{(k)}_c + \Sigma_x^{-1} x)
$$

### Prediction

To model subjects predictions about future locations, we simpl
