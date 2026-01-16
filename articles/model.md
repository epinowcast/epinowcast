# Model definition and implementation

## Introduction

The `epinowcast` package aims to be a modular toolbox for real-time
infectious disease surveillance both in outbreak and routine contexts.
As such we provide a modular modelling framework that is optimised for a
range of common surveillance tasks whilst maintaining flexibility and
supporting user extension.

We provide a flexible semi-parametric model for the underlying
generative process similar to that implemented in other real-time
infectious disease modelling
packages^(\[[1](#ref-EpiNow2),[2](#ref-epidemia)\]). This optionally
includes a renewal process^(\[[3](#ref-Fraser2007),[4](#ref-Cori2013)\])
and latent reporting
process^(\[[1](#ref-EpiNow2),[5](#ref-Abbott2020),[6](#ref-Bhatt2020)\]).
Combined with the appropriate generation time distribution this approach
has been shown to correspond to a Susceptible-Exposed-Infected-Recovered
(SEIR) model^(\[[7](#ref-champredon)\]) with the addition of reporting
delays. However, our default model contains minimal mechanism in order
to more flexibly fit highly informative data.

Our nowcasting approach is an extension of that proposed by Günther et
al.^(\[[8](#ref-gunther2021)\]) which was itself an extension of the
model proposed by Höhle and Heiden^(\[[9](#ref-hohle)\]) and implemented
in the `surveillance` R package^(\[[10](#ref-surveillance)\]). Compared
to the model proposed in Günther et al.^(\[[8](#ref-gunther2021)\]),
`epinowcast` adds support for jointly nowcasting multiple related
datasets, a flexible formula interface allowing for the specification of
a large range of models, and an optional parametric assumption for the
underlying reporting delay.

We also support flexible joint modelling of missing data by assuming
that the reporting delay is consistent between reported and unreported
observations following the methodology of Lison et
al.^(\[[11](#ref-Lison2022)\]).

Our modelling framework is implemented in the `stan` probabilistic
programming language via
`cmdstanr`^(\[[12](#ref-stan),[13](#ref-cmdstanr)\]) with a focus on
computational efficiency and robustness.

For a quick reference to all available features, see the [model features
summary vignette](https://package.epinowcast.org/articles/features.md).

In the following sections we outline our modelling methodology, current
feature set stratified by module, and highlight implementation details.
For each module we present both our default implementation as well as
the more generic framework we support. Note that extensions to this
methodology are warmly welcomed with our [community
site](https://community.epinowcast.org/) being a good first point of
contact.

## Decomposition into expected final notifications and report delay components

We are concerned with outcomes that occur at a time of *reference*
(e.g., date of symptom onset or test for a disease) that are reported
only with a delay, at the time of *report* (e.g., the date onsets are
entered into a central database and so become available for analysis).
We assume that these times are measured in discrete time steps, usually
of a day (in which case the times are dates).

We follow the approach of Höhle and Heiden^(\[[9](#ref-hohle)\]) and
consider the distribution of notifications (\\n\_{g,t,d}\\) by date of
reference (\\t\\) and reporting delay (\\d\\) conditional on the final
observed count \\N\_{g,t}\\ for each dataset (\\g\\) such that,

\\\begin{equation} N\_{g,t} = \sum\_{d=0}^{D} n\_{g,t,d}
\end{equation}\\

where \\D\\ represents the maximum delay between date of reference and
time of report which in theory could be infinite but in practice we set
to a finite value in order to make the model identifiable and
computationally feasible. For each \\t\\ and \\g\\ these notifications
are assumed to be drawn from a multinomial distribution with
\\N\_{g,t}\\ trials and a probability vector (\\p\_{g,t,d}\\) of length
\\D\\. The aim of nowcasting is to predict the final observed counts
\\N\_{g,t}\\ given information available up to time \\t\\. We do this by
estimating the components of this probability vector jointly with the
expected number of final notifications (\\\lambda\_{g,t} =
\mathbb{E}\[N\_{g,t}\]\\) in dataset \\g\\ at time \\t\\.

An alternative approach would be to consider each \\n\_{g,t,d}\\
independently at which point the model can be defined as a regression
that can be fit using standard software with the appropriate observation
model and adjustment for reporting delay (i.e., it becomes a Poisson or
Negative Binomial regression). An implementation of this approach is
available in Bastos et al.^(\[[14](#ref-bastos)\]). A downside of this
simplified approach is that reporting is not conditionally dependent
which may make specifying models for complex reporting distributions
difficult.

## Expected final notifications

### Default model

Here we follow the approach of Günther et
al.^(\[[8](#ref-gunther2021)\]) and specify the model for expected final
notifications as a first order random walk. This simple model is highly
flexible and so a good fit for nowcasting problems where the data is
highly informative.

\\\begin{align} \log (\lambda\_{g,t}) &\sim \text{Normal}\left(\log
(\lambda\_{g,t-1}) , \sigma^{\lambda}\_{g} \right) \\ \log
(\lambda\_{g,0}) &\sim \text{Normal}\left(\log (N\_{g,0} + 1), 1 \right)
\\ \sigma^{\lambda}\_{g} &\sim \text{Half-Normal}\left(0, 1\right)
\end{align}\\

where \\N\_{g0}\\, the first time point for expected observations in
dataset \\d\\, is assumed to have been completely observed.

### Generalised model

In settings where data is sparse or where users want to understand the
underlying generative process our flexible default model is likely not a
good choice. In these settings our generic model offers a range of
options that are context specific. Our generic model is currently based
on a renewal process^(\[[3](#ref-Fraser2007),[4](#ref-Cori2013)\]) with
additional latent reporting
delays^(\[[1](#ref-EpiNow2),[5](#ref-Abbott2020),[6](#ref-Bhatt2020)\]).
As previously noted^(\[[7](#ref-champredon)\]), this corresponds to the
commonly used Susceptible-Exposed-Infected-Recovered (SEIR) model when
appropriate generation time is specified^(\[[7](#ref-champredon)\])

### Instantaneous reproduction number/growth rate

We model the instantaneous reproduction number (\\R_t\\) on the log
scale (though support for other link functions is planned). When the
generation time is fixed to be a day this can be interpreted as the
instantaneous growth rate (\\r_t\\) defined as the difference in the log
of the expected number of final notifications between time \\t\\ and
\\t-1\\.

\\\begin{equation} \text{log} (R\_{g,t}) = r_0 + \beta\_{f,r} X\_{r} +
\beta\_{r,r} Z\_{r} \end{equation}\\

where \\r_0\\ is the optional intercept, \\X\_{r}\\ is the design matrix
for fixed effects (\\\beta\_{f,r}\\), and \\Z\_{r}\\ is the design
matrix for random effects (\\\beta\_{r,r}\\. Within this specification
the default model can be specified as a random effect on the day with no
intercept. Alternative specifications that may be of interest include a
weekly random walk (specified as `~ 1 + rw(week)`), a piecewise linear
model (specified as `~ 1 + day:week`), and a group specific random
effect (specified as `~ 1 + (1 | .group)`).

This model is specified via the `r` argument of
[`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md)
(see
[`?enw_expectation`](https://package.epinowcast.org/reference/enw_expectation.md)).
For example, `enw_expectation(r = ~ 1 + rw(week))` implements a weekly
random walk for the log reproduction number as described above.

### Latent infections/notifications

We model the expected number of infections/latent notifications
(\\\lambda^l\\) using a renewal
process^(\[[3](#ref-Fraser2007),[4](#ref-Cori2013)\]). This model is a
generalisation of the default model and can be used to model the
expected number of latent notifications in a setting where the
generation time is not fixed to be a day. It implies that current
infections/notifications are dependent on past infections/notifications
based on a kernel (usually interpreted as the generation time or serial
interval). An instantaneous daily growth rate model can be recovered by
setting the generation time to be fixed at 1 day. The model is defined
as follows,

\\\begin{align} \lambda^l\_{g,t} &\sim
\text{LogNormal}\left(\mu^{l}\_{g,t}, \sigma^{l}\_{g,t} \right),\\ t
\leq P \\ \lambda^l\_{g,t} &= R\_{g,t} \sum\_{p = 1}^{P} G\_{g}\left(p,
t - p \right) \lambda^l\_{g, t-p},\\ t \gt P \end{align}\\

Where \\G\_{g}\left(p, t - p \right)\\ is the probability of an
infection \\p\\ days after infection \\t - p\\ days ago for group \\g\\,
and \\P\\ is the maximum generation time. To initialise the model we
assume that the first \\P\\ latent notifications are log-normally
distributed with mean \\\mu^{l}\_{g,t}\\ and standard deviation
\\\sigma^{l}\_{g,t}\\. This is equivalent to assuming that the first
\\P\\ latent notifications are independent and identically distributed.
The mean of the log-normal distribution for each group is the log of the
latest reported case count for the first reference date for that group
scaled by the sum of the latent reporting delay. The standard deviation
is assumed to be 1. Both of these assumptions can be altered by the
user.

### Latent reporting delay and ascertainment

In some settings there may be additional reporting delays on top of
those that are directly observed in the data, and therefore
“nowcastable”, a common example is the delay from exposure to symptom
onset. For these settings we support modelling “latent” reporting delays
as a convolution of the underlying expected counts with the potential
for these delays to vary over time and by group. This implementation is
similar to that implemented in `EpiNow2` and `epidemia` as well as other
similar
models^(\[[1](#ref-EpiNow2),[5](#ref-Abbott2020),[6](#ref-Bhatt2020),[11](#ref-Lison2022)\]).
In addition to this we support modelling ascertainment through the use
of improper probability mass functions (i.e., by not enforcing a sum to
1 constraint) and inferring ascertainment where possible (for example
day of the week reporting patterns).

\\\begin{align} \lambda\_{g,t} &= \upsilon\_{g,t} \sum\_{\tau = 0}^{L -
1} F\_{g}\left(\tau + 1, t - \tau \right) \lambda^l\_{g, t - \tau} \\
\nu\_{g,t} &= \nu_0 + \beta\_{f,\nu} X\_{\nu} + \beta\_{r,\nu} Z\_{\nu}
\end{align}\\

Where \\\nu\_{g,t}\\ is the inferred ascertainment and is modelled
flexibly using an optional intercept (\\\nu_0\\), a design matrix
(\\X\_{\nu}\\) for fixed effects (\\\beta\_{f,\nu}\\), and a design
matrix (\\Z\_{\nu}\\) for random effects (\\\beta\_{r,\nu}\\.

Ascertainment is specified via the `observation` argument and latent
reporting delays via the `latent_reporting_delay` argument of
[`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md)
(see
[`?enw_expectation`](https://package.epinowcast.org/reference/enw_expectation.md)).
For example, `enw_expectation(observation = ~ 1 + day_of_week)` models
day-of-week variation in ascertainment as described above.

## Delay distribution

Given case counts both by date of reference and by date of report, we
can estimate the reporting delay distribution directly and jointly with
the underlying process model, rather than relying on external estimates
from other sources (though we may want to account for external
information in our priors). In the following section, we describe our
default parametric delay distribution model and its extension into a
generic, highly flexible delay model based on discrete time-to-event
modelling.

### Default model

In our default model, we consider the reporting delay to follow a
\\\text{LogNormal} \left(\mu^d, \sigma^d \right)\\ distribution, with
parameters

\\\begin{align} \mu^d &\sim \text{Normal} \left(0, 1 \right) \\ \sigma^d
&\sim \text{Half-Normal} \left(0, 1 \right). \end{align}\\

This distribution is discretised into daily probabilities \\p\_{g,t,d}\\
(for a case in group \\g\\ with reference date \\t\\ to be reported with
delay \\d\\) and adjusted for the maximum delay, see
[`vignette("distributions")`](https://package.epinowcast.org/articles/distributions.md)
for details.

### Generalised model

We generalise this model in order to support a range of delay
distributions as well as effects of the reporting process on the delay.
Following the approach of Günther et al.^(\[[8](#ref-gunther2021)\]) and
others, we parameterise the delay probability (\\p\_{g,t,d}\\) via a
discrete-time hazard model, i.e.,

\\\begin{equation} p\_{g,t,0} = h\_{g,t,0},\\ p\_{g,t,d} = \left(1
-\sum^{d-1}\_{d^{\prime}=0} p\_{g,t,d^{\prime}} \right) \times
h\_{g,t,d}, \end{equation}\\

where

\\ h\_{g,t,d} =\text{P} \left(\text{delay}=d\|\text{delay} \geq d,
W\_{g,t,d}\right), \\ is the so-called reporting hazard. For a case in
group \\g\\ with reference date \\t\\, the hazard \\h\_{g,t,d}\\ states
the probability of being reported with delay \\d\\, given that the case
is not reported earlier. The hazard depends on a design matrix
\\W\_{g,t,d}\\, which encodes a baseline delay distribution and
covariates that affect the reporting delay. We extend the model of
Günther et al. by decomposing the hazard into three components,

- **Parametric baseline hazard \\\gamma\_{g,t,d}\\**: hazard derived
  from a parametric delay distribution, with parameters depending on
  covariates on the date of reference
- **Non-parametric reference date effect \\\delta\_{g,t,d}\\**: effect
  on the hazard that depends on covariates on the date of reference
- **Non-parametric report date effect \\\epsilon\_{g,t,d}\\**: effect on
  the hazard that depends on covariates on the date of report

Each component adds to the overall hazard through a regression with a
logit link \\\begin{equation} \text{logit} (h\_{g,t,d}) =
\gamma\_{g,t,d} + \delta\_{g,t,d} + \epsilon\_{g,t,d}, \end{equation}\\

where the maximum delay hazard is \\h\_{g,t,D}=1\\, in order to enforce
the assumption that all observations are reported within the specified
maximum delay. In the following, we describe the parameterisation of the
different components.

##### Parametric baseline hazard

The parametric baseline hazard \\\gamma\_{g,t,d}\\ for a case in group
\\g\\ with reference date \\t\\ is modelled according to a certain
discretised parametric probability distribution with parameters
\\\mu\_{g,t}\\ and \\\upsilon\_{g,t}\\. Currently, `epinowcast` supports
four different parametric distributions: (i) log-normal (default), (ii)
exponential, (iii) gamma, and (iv) log-logistic. The distributions are
discretised and adjusted for an assumed maximum delay, see
[`vignette("distributions")`](https://package.epinowcast.org/articles/distributions.md)
for details. The delay probabilities \\p^{\prime}\_{g,t,d}\\ obtained
from the discretised delay distribution are converted into hazards on
the logit scale using

\\\begin{equation} \gamma\_{g,t,d} = \text{logit}
\left(\frac{p^{\prime}\_{g,t,d}}{\left(1 -\sum^{d-1}\_{d^{\prime}=0}
p^{\prime}\_{g,t,d^{\prime}} \right)} \right). \end{equation}\\

In the default case of the log-normal distribution, the parameters
\\\mu\_{g,t}\\ and \\\upsilon\_{g,t}\\ represent the log mean and log
standard deviation. Each parameter is defined using a (log-)linear
model. The model consists of an intercept and a number of arbitrary,
shared covariates, indexed by reference date. The covariates are
multiplied by fixed (\\\beta\_{f,i}\\) and random (\\\beta\_{r,i}\\)
coefficients (note that these can include auto-regressive terms), i.e.,

\\\begin{align} \mu\_{g,t} &= \mu_0 + \beta\_{f,\mu} X\_{\gamma} +
\beta\_{r,\mu} Z\_{\gamma} \\ \text{log} (\upsilon\_{g,t}) &=
\upsilon_0 + \beta\_{f,\upsilon} X\_{\gamma} + \beta\_{r,\upsilon}
Z\_{\gamma} \end{align}\\

These parameters are specified via the `parametric` argument of
[`enw_reference()`](https://package.epinowcast.org/reference/enw_reference.md)
(see
[`?enw_reference`](https://package.epinowcast.org/reference/enw_reference.md)),
which controls both \\\mu\_{g,t}\\ and \\\upsilon\_{g,t}\\
simultaneously. For example,
`enw_reference(parametric = ~ 1 + (1 | age_group))` creates age
group-specific random effects for both parameters above, allowing
different age groups to have different delay distributions whilst
sharing information through hierarchical pooling.

##### Non-parametric reference date effect \\\delta\_{g,t,d}\\ and report date effect \\\epsilon\_{g,t,d}\\

In addition to parametric reporting effects there may also be
non-parametric effects referenced by both reference and report dates.
These are represented by the non-distributional logit hazard components
for the date of reference and report, defined using an intercept
(\\\delta_0\\) and arbitrary, shared covariates with fixed
(\\\beta\_{f,i}\\) and random (\\\beta\_{r,i}\\) coefficients (note
these can include auto-regressive terms).

\\\begin{align} \delta\_{g,t,d} &= \delta_0 + \beta\_{f,\delta}
X\_{\delta} + \beta\_{r,\delta} Z\_{\delta} \\ \epsilon\_{g,t,d} &=
\beta\_{f,\epsilon} X\_{\epsilon} + \beta\_{r,\epsilon} Z\_{\epsilon}
\end{align}\\

The reference date effect \\\delta\_{g,t,d}\\ is specified via the
`non_parametric` argument of
[`enw_reference()`](https://package.epinowcast.org/reference/enw_reference.md)
(see
[`?enw_reference`](https://package.epinowcast.org/reference/enw_reference.md)),
whilst the report date effect \\\epsilon\_{g,t,d}\\ is specified via the
`non_parametric` argument of
[`enw_report()`](https://package.epinowcast.org/reference/enw_report.md)
(see
[`?enw_report`](https://package.epinowcast.org/reference/enw_report.md)).
For example, `enw_reference(non_parametric = ~ 1 + day_of_week)` adds
day-of-week effects to the reference date hazard, whilst
`enw_report(non_parametric = ~ 1 + day_of_week)` adds day-of-week
effects to the report date hazard.

All fixed (\\\beta\_{f,i}\\) and random (\\\beta\_{r,i}\\) coefficients
have standard normal priors by default with standard half-normal priors
for pooled standard deviations.

## Observation model and nowcast

Expected notifications by date of reference (\\t\\) and reporting delay
can now be found by multiplying expected final notifications for each
\\t\\ with the probability of reporting for each day of delay
(\\p\_{g,t,d}\\). We assume a negative binomial observation model, by
default, with a joint overdispersion parameter (with a standard half
normal prior on 1 over square root of the
overdispersion^(\[[15](#ref-stan_prior_wiki)\])) and produce a nowcast
of final observed notifications at each reference date by summing
posterior estimates for unobserved notification and observed
notifications for that reference date.

\\\begin{align} n\_{g,t,d} \mid \lambda\_{g,t},p\_{g,t,d} &\sim
\text{NB} \left((1 - \alpha\_{g,t})\lambda\_{g,t} \times p\_{g,t,d},
\phi \right),\\ t=1,...,T. \\ \frac{1}{\sqrt{\phi}} &\sim
\text{Half-Normal}(0, 1) \\ N\_{g,t} &= \sum\_{d=0}^{D} n\_{g,t,d}
\end{align}\\

Where \\\alpha\_{g,t}\\ is the proportion of cases by reference date
that will not report their reference date. By default this is not
modelled and is set to zero , see the accounting for reported cases with
a missing reference date section for further defaults. Other observation
models such as the Poisson distribution are also supported. See the
documentation
[`enw_obs()`](https://package.epinowcast.org/reference/enw_obs.md) for
details.

In order to make best use of observed data when nowcasting we use
observations where available and where they have not been reported for a
given report and reference date we use the posterior prediction from the
observation model above. This means that as nowcast dates become
increasingly truncated they depend more on modelled estimates whereas
when they are more complete the majority of the final count is known.
Depending on your use case the posterior predictions alone may also be
of interest.

## Accounting for reported cases with a missing reference date

In real-world settings observations may be reported without a linked
reference date. A common example of this is cases by date of symptom
onset where report date is often known but onset date may not be. To
account for this we support modelling this missing process by assuming
that cases with a missing reference date have the same reporting delay
distribution as cases with a known reference date and that processes
that drive the probability of having a missing reference date
(\\\alpha\_{g,t}\\) are linked to the unknown date of reference rather
than the date of report based on Lison et
al.^(\[[11](#ref-Lison2022)\]). We model this probability flexibly on a
logit scale as follows,

\\\begin{equation} \text{logit} (\alpha\_{g,t}) = \alpha_0 +
\beta\_{f,\alpha} X\_{\alpha} + \beta\_{r,\alpha} Z\_{\alpha}
\end{equation}\\

Where \\\alpha_0\\ represents the intercept, \\\beta\_{f,\alpha}\\ fixed
effects, and \\\beta\_{r,\alpha}\\ random effects. To link with
observations by date of report with a missing reference date
(\\M\_{g,t}\\) we convolve expected notifications with the probability
of having a missing reference date and the probability of reporting on a
given day as follows,

\\\begin{equation} M\_{g,t} \mid \lambda\_{g,t},p\_{g,t,d},
\alpha\_{g,t} \sim \text{NB} \left( \sum^D\_{d=0} \alpha\_{g,t-d}
\lambda\_{g,t-d} p\_{g,t-d,d}, \phi \right),\\ t=1,...,T.
\end{equation}\\

As for cases with known reference dates other observation models are
supported. For further implementation details see
[`enw_missing()`](https://package.epinowcast.org/reference/enw_missing.md).

## Implementation

The model is implemented in the probabilistic programming language
`stan` and we use `cmdstanr` to interact with the
model^(\[[12](#ref-stan),[13](#ref-cmdstanr)\]). Optional within chain
parallelisation is available across times of reference to reduce
runtimes. Sparse design matrices have been used for all covariates to
limit the number of probability mass functions that need to be
calculated. `epinowcast` incorporates additional functionality written
in R^(\[[16](#ref-R)\]) to enable plotting nowcasts and posterior
predictions, summarising nowcasts, and scoring them using
`scoringutils`^(\[[17](#ref-scoringutils)\]). A flexible formula
interface is provided to enable easier implementation of complex user
specified models without interacting with the underlying code base. All
functionality is modular allowing users to extend and alter the
underlying model whilst continuing to use the package framework.

## Summary of module-parameter mappings

The following table summarises how module function arguments map to
parameters in the model definition:

| Module Function                                                                    | Argument         | Parameters Modified                                                 |
|------------------------------------------------------------------------------------|------------------|---------------------------------------------------------------------|
| [`enw_reference()`](https://package.epinowcast.org/reference/enw_reference.md)     | `parametric`     | \\\mu\_{g,t}\\, \\\upsilon\_{g,t}\\ (delay distribution parameters) |
| [`enw_reference()`](https://package.epinowcast.org/reference/enw_reference.md)     | `non_parametric` | \\\delta\_{g,t,d}\\ (reference date hazard component)               |
| [`enw_report()`](https://package.epinowcast.org/reference/enw_report.md)           | `non_parametric` | \\\epsilon\_{g,t,d}\\ (report date hazard component)                |
| [`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md) | `r`              | \\R\_{g,t}\\ (reproduction number/growth rate)                      |
| [`enw_expectation()`](https://package.epinowcast.org/reference/enw_expectation.md) | `observation`    | \\\nu\_{g,t}\\ (ascertainment)                                      |

For additional implementation details and examples, see the
documentation for each module function
([`?enw_reference`](https://package.epinowcast.org/reference/enw_reference.md),
[`?enw_report`](https://package.epinowcast.org/reference/enw_report.md),
[`?enw_expectation`](https://package.epinowcast.org/reference/enw_expectation.md))
and the age-stratified nowcasting vignette
([`vignette("germany-age-stratified-nowcasting")`](https://package.epinowcast.org/articles/germany-age-stratified-nowcasting.md)).

## References

1\. Abbott, S., Hellewell, J., Sherratt, K., Gostic, K., Hickson, J.,
Badr, H. S., DeWitt, M., Thompson, R., EpiForecasts, & Funk, S. (2020).
*EpiNow2: Estimate real-time case counts and time-varying
epidemiological parameters*. <https://doi.org/10.5281/zenodo.3957489>

2\. Scott, J. A., Gandy, A., Mishra, S., Unwin, J., Flaxman, S., &
Bhatt, S. (2020). *Epidemia: Modeling of epidemics using hierarchical
bayesian models*. <https://imperialcollegelondon.github.io/epidemia/>

3\. Fraser, C. (2007). Estimating individual and household reproduction
numbers in an emerging epidemic. *PLoS One*, *2*(8), e758.
<https://doi.org/10.1371/journal.pone.0000758>

4\. Cori, A., Ferguson, N. M., Fraser, C., & Cauchemez, S. (2013). A new
framework and software to estimate time-varying reproduction numbers
during epidemics. *Am. J. Epidemiol.*, *178*(9), 1505–1512.
<https://doi.org/10.1093/aje/kwt133>

5\. Abbott, S., Hellewell, J., Thompson, R. N., Sherratt, K., Gibbs, H.
P., Bosse, N. I., Munday, J. D., Meakin, S., Doughty, E. L., Chun, J.
Y., Chan, Y.-W. D., Finger, F., Campbell, P., Endo, A., Pearson, C. A.
B., Gimma, A., Russell, T., Flasche, S., Kucharski, A. J., … CMMID COVID
modelling group. (2020). Estimating the time-varying reproduction number
of SARS-CoV-2 using national and subnational case counts. *Wellcome Open
Res.*, *5*, 112. <https://doi.org/10.12688/wellcomeopenres.16006.2>

6\. Bhatt, S., Ferguson, N., Flaxman, S., Gandy, A., Mishra, S., &
Scott, J. A. (2020). *Semi-Mechanistic bayesian modeling of COVID-19
with renewal processes*. <https://arxiv.org/abs/2012.00394>

7\. Champredon, D., Dushoff, J., & Earn, D. J. D. (2018). Equivalence of
the Erlang-Distributed SEIR epidemic model and the renewal equation.
*SIAM J. Appl. Math.*, *78*(6), 3258–3278.
<https://doi.org/10.1137/18M1186411>

8\. Günther, F., Bender, A., Katz, K., Küchenhoff, H., & Höhle, M.
(2021). Nowcasting the COVID-19 pandemic in Bavaria. *Biometrical
Journal*, *63*(3), 490–502. <https://doi.org/10.1002/bimj.202000112>

9\. Höhle, M., & Heiden, M. an der. (2014). Bayesian nowcasting during
the STEC O104:H4 outbreak in Germany, 2011. *Biometrics*, *70*(4),
993–1002. <https://doi.org/10.1111/biom.12194>

10\. Meyer, S., Held, L., & Höhle, M. (2017). Spatio-temporal analysis
of epidemic phenomena using the R package surveillance. *Journal of
Statistical Software*, *77*(11), 1–55.
<https://doi.org/10.18637/jss.v077.i11>

11\. Lison, A. (n.d.). *Nowcast-transmission*. Github.

12\. Team, S. D. (2021). *Stan modeling language users guide and
reference manual, 2.28.1*.

13\. Gabry, J., & Češnovar, R. (2021). *Cmdstanr: R interface to
’CmdStan’*.

14\. Bastos, L. S., Economou, T., Gomes, M. F. C., Villela, D. A. M.,
Coelho, F. C., Cruz, O. G., Stoner, O., Bailey, T., & Codeço, C. T.
(2019). A modelling approach for correcting reporting delays in disease
surveillance data. *Statistics in Medicine*, *38*(22), 4363–4377.
<https://doi.org/10.1002/sim.8303>

15\. Team, S. D. (2020). *Prior choice recommendations*.

16\. R Core Team. (2019). *R: A language and environment for statistical
computing*. R Foundation for Statistical Computing.
<https://www.R-project.org/>

17\. Bosse, N. (2020). *Scoringutils: A collection of proper scoring
rules and metrics to assess predictions*.
<https://github.com/epiforecasts/scoringutils>
