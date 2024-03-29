% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculate_treatment_effects.R
\name{treatment.effects}
\alias{treatment.effects}
\alias{treatment.effects.default}
\alias{treat.effects}
\alias{treatment.effects.subgroup_fitted}
\title{Calculation of covariate-conditional treatment effects}
\usage{
treatment.effects(x, ...)

\method{treatment.effects}{default}(x, ...)

treat.effects(
  benefit.scores,
  loss = c("sq_loss_lasso", "logistic_loss_lasso", "poisson_loss_lasso",
    "cox_loss_lasso", "owl_logistic_loss_lasso", "owl_logistic_flip_loss_lasso",
    "owl_hinge_loss", "owl_hinge_flip_loss", "sq_loss_lasso_gam",
    "poisson_loss_lasso_gam", "logistic_loss_lasso_gam", "sq_loss_gam",
    "poisson_loss_gam", "logistic_loss_gam", "owl_logistic_loss_gam",
    "owl_logistic_flip_loss_gam", "owl_logistic_loss_lasso_gam",
    "owl_logistic_flip_loss_lasso_gam", "sq_loss_xgboost", "custom"),
  method = c("weighting", "a_learning"),
  pi.x = NULL,
  ...
)

\method{treatment.effects}{subgroup_fitted}(x, ...)
}
\arguments{
\item{x}{a fitted object from \code{fit.subgroup()}}

\item{...}{not used}

\item{benefit.scores}{vector of estimated benefit scores}

\item{loss}{loss choice USED TO CALCULATE \code{benefit.scores} of both the M function from Chen, et al (2017) and
potentially the penalty used for variable selection. See \code{\link[personalized]{fit.subgroup}} for more details.}

\item{method}{method choice USED TO CALCULATE \code{benefit.scores}. Either the \code{"weighting"} method or
\code{"a_learning"} method. See \code{\link[personalized]{fit.subgroup}} for more details}

\item{pi.x}{The propensity score for each observation}
}
\value{
A List with elements \code{delta} (if the treatment effects are a difference/contrast,
i.e. \eqn{E[Y|T=1, X] - E[Y|T=-1, X]}) and \code{gamma} (if the treatment effects are a ratio,
i.e. \eqn{E[Y|T=1, X] / E[Y|T=-1, X]})
}
\description{
Calculates covariate conditional treatment effects using estimated benefit scores
}
\examples{
library(personalized)

set.seed(123)
n.obs  <- 500
n.vars <- 25
x <- matrix(rnorm(n.obs * n.vars, sd = 3), n.obs, n.vars)


# simulate non-randomized treatment
xbetat   <- 0.5 + 0.5 * x[,21] - 0.5 * x[,11]
trt.prob <- exp(xbetat) / (1 + exp(xbetat))
trt01    <- rbinom(n.obs, 1, prob = trt.prob)

trt      <- 2 * trt01 - 1

# simulate response
delta <- 2 * (0.5 + x[,2] - x[,3] - x[,11] + x[,1] * x[,12])
xbeta <- x[,1] + x[,11] - 2 * x[,12]^2 + x[,13]
xbeta <- xbeta + delta * trt

# continuous outcomes
y <- drop(xbeta) + rnorm(n.obs, sd = 2)

# time-to-event outcomes
surv.time <- exp(-20 - xbeta + rnorm(n.obs, sd = 1))
cens.time <- exp(rnorm(n.obs, sd = 3))
y.time.to.event  <- pmin(surv.time, cens.time)
status           <- 1 * (surv.time <= cens.time)

# create function for fitting propensity score model
prop.func <- function(x, trt)
{
    # fit propensity score model
    propens.model <- cv.glmnet(y = trt,
                               x = x, family = "binomial")
    pi.x <- predict(propens.model, s = "lambda.min",
                    newx = x, type = "response")[,1]
    pi.x
}

subgrp.model <- fit.subgroup(x = x, y = y,
                             trt = trt01,
                             propensity.func = prop.func,
                             loss   = "sq_loss_lasso",
                             nfolds = 3)    # option for cv.glmnet

trt_eff <- treatment.effects(subgrp.model)
str(trt_eff)

trt_eff


library(survival)
subgrp.model.cox <- fit.subgroup(x = x, y = Surv(y.time.to.event, status),
                           trt = trt01,
                           propensity.func = prop.func,
                           loss   = "cox_loss_lasso",
                           nfolds = 3)              # option for cv.glmnet

trt_eff_c <- treatment.effects(subgrp.model.cox)
str(trt_eff_c)

trt_eff_c

}
\seealso{
\code{\link[personalized]{fit.subgroup}} for function which fits subgroup identification models.

\code{\link[personalized]{print.individual_treatment_effects}} for printing of objects returned by
\code{treat.effects} or \code{treatment.effects}
}
