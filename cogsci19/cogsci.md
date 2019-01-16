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

### Context model

We modeled learners inferences about the underlying context on each trial as a
sequential Bayesian non-parametric clustering problem.  The goal of the learner
in this model is to infer the cluster assignment $z_i$ of observation $x_i$,
given the previous observations $x_{1:i-1}$ and their labels $z_{1:i-1}$:

$$p(z_i=j | x_{1:i}, z_{1:i-1}) \propto p(x_i | z_i=j, z_{1:i-1}, x_{1:i-1})
p(z_i=j | z_{1:i-1}) $$

The sequential prior $p(z_i=j | z_{1:i-1})$ is a "Hibachi Grill Process"
[@Qian2014], which is like the standard Chinese Restaurant Process (CRP) with an
added (constant) probability assigned to the previous state.  This corresponds
to the following generative model: with probability $0 < \rho < 1$ the last
state is picked, $j=z_{i-1}$, and with probability $1-\rho$ a component is
chosen from a Chinese Restaurant Process with concentration $\alpha$, which
assigns probability to each state proportional to the number of observations
assigned to it already[^counts], and creates a new state with probability
proportional to $\alpha > 0$.

[^counts]: One important difference from a standard CRP is that only non-sticky
    transitions count for the purposes of sampling new states from the CRP.

The likelihood
$p(x_i | z_i=j, z_{1:i-1}, x_{1:i-1}) = p(x_i | x_{\{k; z_k=j\}})$ is computed
by marginalizing over the mean and covariance of a multivariate normal
distribution given the data points previously assigned to that cluster and a
conjugate Normal-Inverse Wishart prior [@Gelman2003].  This has the advantage
that it only requires tracking the sufficient statistics of the previous
observations from the cluster (sample mean and covariance), and not the
individual observations.

### Inference: Sequential Monte Carlo

Instead of a standard batch inference technique, we use an online, Sequential
Monte Carlo/particle filter technique.  This method approximates the posterior
beliefs after $i-1$ observations $p(z_{1:i-1} | x_{1:i-1})$ as a weighted
population of $K$ particles, each of which is one possible value of the $i-1$
labels, denoted $z_{1:i-1}^{(k)}$.  This population of particles represents an
_importance sample_ from the posterior.  When a new observation $x_i$ comes in,
the population moves to target the updated posterior $p(z_{1:i} | x_{1:i})$.
There are many algorithms to do this, and the effectiveness of a particular
algorithm will depend on the problem.  We use the algorithm of @Chen1999 [as
described in @Fearnhead2004]: for each particle $k$, a state assignment is
sampled for $x_i$ according to $p(z_i | x_{1:i}, z^{(k)}_{1:i-1})$, and the
weight $w^{(k)}_i$ is updated by the ratio of
$$
\frac{\sum_j p((z_{1:i-1}^{(k)},j) | x_{1:i})}
     {p(z_{1:i-1}^{(k)} | x_{1:i-1})}
$$
to ensure that each particle's weight reflects it's ability to _predict_ the
point $x_i$, rather than just _explain_ it.  When too much of the total weight
for the population (constrained to sum to 1) is captured by a small number of
particles (measured by the ratio of the variance of the weights to their mean
being greater than $0.5$), a new population is resampled (with replacement) and
the weights are set to be uniform.

This is for two reasons.  First, because we wish to query the
model's beliefs about the current context at every point throughout the
experiment, an online approximation is much more computationally efficient.  A
batch algorithm like Gibbs sampling or Hamiltonian Monte Carlo requries one full
sweep through the data for each sample, which must be done independently for
each data point, so drawing $K$ samples for each of $N$ data points is
$O(KN^2)$.  A particle filter propogates uncertainty with a fixed population of
$K$ particles, updating each particle in parallel as each data point comes in,
meaning the complexity is only $O(KN)$.  This means it's possible to effectively
model longer experiments.

Second, an online learning algorithm better approximates _psychological_
constraints on learning, and in particular does not assume that learners can go
back and revisit each observation and their decisions about it.  This class of
models thus provides a possible bridge between computational and algorithmic
level approaches to modeling learning and memory [@Sanborn2010;
@Kleinschmidt2018].

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

$$
\mu^{(k)}_c, \Sigma^{(k)}_c = E(\mu, \Sigma)_{p(\mu, \Sigma | x_{1:i},
  z^{(k)}_{1:i})}
$$

Then the best guess of the studied location under particle $k$'s model of the
context is the combination of a normal likelihood (from the noisy trace of the
studied item) and a normal prior (from the context), which works out to be the
inverse variance-weighted average of the two means:

$$
\hat x^{(k)} = ({\Sigma^{(k)}_c}^{-1} + \Sigma_x^{-1})^{-1}
    ({\Sigma^{(k)}_c}^{-1} \mu^{(k)}_c + \Sigma_x^{-1} x)
$$

### Prediction

To model subjects predictions about future locations, we sample 100 locations
from the posterior predictive distribution of the population of particles.  To
sample one predicted location at a $n$ trials in the future, we sample a
particle from the population according to their weights, draw a sample of $n$
future states from that particle's Hibachi Grill Process, 

# Results
