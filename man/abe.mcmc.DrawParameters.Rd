% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pareto-nbd-abe.R
\name{abe.mcmc.DrawParameters}
\alias{abe.mcmc.DrawParameters}
\title{Pareto/NBD (Abe) Parameter Draws}
\usage{
abe.mcmc.DrawParameters(
  cal.cbs,
  covariates = c(),
  mcmc = 2500,
  burnin = 500,
  thin = 50,
  chains = 2,
  mc.cores = NULL,
  trace = 100
)
}
\arguments{
\item{cal.cbs}{Calibration period customer-by-sufficient-statistic (CBS)
data.frame. It must contain a row for each customer, and columns \code{x}
for frequency, \code{t.x} for recency and \code{T.cal} for the total time
observed. A correct format can be easily generated based on the complete
event log of a customer cohort with \code{\link{elog2cbs}}.}

\item{covariates}{A vector of columns of \code{cal.cbs} which contain customer-level covariates.}

\item{mcmc}{Number of MCMC steps.}

\item{burnin}{Number of initial MCMC steps which are discarded.}

\item{thin}{Only every \code{thin}-th MCMC step will be returned.}

\item{chains}{Number of MCMC chains to be run.}

\item{mc.cores}{Number of cores to use in parallel (Unix only). Defaults to \code{min(chains, detectCores())}.}

\item{trace}{Print logging statement every \code{trace}-th iteration. Not available for \code{mc.cores > 1}.}
}
\value{
List of length 2:
\item{\code{level_1}}{list of \code{\link{mcmc.list}}s, one for each customer, with draws for customer-level parameters \code{k}, \code{lambda}, \code{tau}, \code{z}, \code{mu}}
\item{\code{level_2}}{\code{\link{mcmc.list}}, with draws for cohort-level parameters}
}
\description{
Returns draws from the posterior distributions of the Pareto/NBD (Abe)
parameters, on cohort as well as on customer level.
}
\details{
See \code{demo('pareto-abe')} for how to apply this model.
}
\examples{
data("groceryElog")
cbs <- elog2cbs(groceryElog, T.cal = "2006-12-31")
cbs$cov1 <- as.integer(cbs$cust) \%\% 2 # create dummy covariate
param.draws <- abe.mcmc.DrawParameters(cbs, c("cov1"),
  mcmc = 200, burnin = 100, thin = 20, chains = 1) # short MCMC to run demo fast

# cohort-level parameter draws
as.matrix(param.draws$level_2)
# customer-level parameter draws for customer with ID '4'
as.matrix(param.draws$level_1[["4"]])

# estimate future transactions
xstar.draws <- mcmc.DrawFutureTransactions(cbs, param.draws, cbs$T.star)
xstar.est <- apply(xstar.draws, 2, mean)
head(xstar.est)
}
\references{
Abe, Makoto. 'Counting your customers one by one: A hierarchical Bayes extension to the Pareto/NBD model.' Marketing Science 28.3 (2009): 541-553.
}
\seealso{
\code{\link{abe.GenerateData} } \code{\link{mcmc.PAlive} } \code{\link{mcmc.DrawFutureTransactions} }
}
