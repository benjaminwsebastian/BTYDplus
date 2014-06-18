
set.seed(1)

# generate artificial BG/NBD data 
n      <- 1000 # no. of customers
T.cal  <- 32   # length of calibration period
T.star <- 32   # length of hold-out period
params <- list(t=4.5, gamma=1.5, # regularity parameter k_i ~ Gamma(t, gamma)
               r=5, alpha=10,    # purchase frequency lambda_i ~ Gamma(r, alpha)
               s=0.8, beta=12)   # dropout probability mu_i ~ Gamma(s, beta)

data <- pcnbd.GenerateData(n, T.cal, T.star, params, return.elog=TRUE)
cbs <- data$cbs
elog <- data$elog

# estimate Pareto/NBD MCMC
pnbd.draws <- pnbd.mcmc.DrawParameters(cbs, mcmc=1500, burnin=500, chains=2, thin=50)
plot(pnbd.draws$level_2)

# estimate Pareto/CNBD MCMC
pcnbd.draws <- pcnbd.mcmc.DrawParameters(cbs, mcmc=1500, burnin=500, chains=2, thin=50)
plot(pcnbd.draws$level_2, density=FALSE)
rbind("actual"=params, "estimated"=round(summary(pcnbd.draws$level_2)$quantiles[, "50%"], 2))
#           t   gamma r    alpha s   beta
# actual    4.5  1.5   5    10    0.8  12  
# estimated 3.63 1.19  4.78 9.52  0.71 9.32

coda::gelman.diag(pcnbd.draws$level_2)
# -> MCMC chains have not converged yet

pcnbd.mcmc.plotRegularityRateHeterogeneity(pcnbd.draws)

round(effectiveSize(pcnbd.draws$level_2))
# -> effective sample size are small for such a short chain

# draw future transaction
pnbd.xstar <- pcnbd.mcmc.DrawFutureTransactions(cbs, pnbd.draws, T.star=cbs$T.star)
pcnbd.xstar <- pcnbd.mcmc.DrawFutureTransactions(cbs, pcnbd.draws, T.star=cbs$T.star)

# calculate mean over future transaction draws for each customer
cbs$pnbd.mcmc <- apply(pnbd.xstar, 2, mean)
cbs$pcnbd.mcmc <- apply(pcnbd.xstar, 2, mean)

MAPE <- function(a, f) { return(sum(abs(a-f)/sum(a))) }
RMSE <- function(a, f) { return(sqrt(mean((a-f)^2))) }
MSLE <- function(a, f) { return(mean(((log(a+1) - log(f+1)))^2)) }
BIAS <- function(a, f) { return(mean(a)-mean(f)) }
bench <- function(cbs, models) {
  acc <- t(sapply(models, function(model) c(MAPE(cbs$x.star, cbs[, model]),
                                            RMSE(cbs$x.star, cbs[, model]),
                                            MSLE(cbs$x.star, cbs[, model]),
                                            BIAS(cbs$x.star, cbs[, model]))))
  colnames(acc) <- c("MAPE", "RMSE", "MSLE", "BIAS")
  round(acc, 3)
}

bench(cbs, c("pnbd.mcmc", "pcnbd.mcmc"))
#            MAPE  RMSE  MSLE   BIAS
# pnbd.mcmc  0.531 4.485 0.483 -0.268
# pcnbd.mcmc 0.486 4.420 0.370 -0.007

# calculate P(active)
cbs$pactive.pnbd.mcmc <- apply(pnbd.xstar, 2, function(x) mean(x>0))
cbs$pactive.pcnbd.mcmc <- apply(pcnbd.xstar, 2, function(x) mean(x>0))

# Brier score
c("pnbd.mcmc"=mean((cbs$pactive.pnbd.mcmc-(cbs$x.star>0))^2),
  "pcnbd.mcmc"=mean((cbs$pactive.pcnbd.mcmc-(cbs$x.star>0))^2))
#  pnbd.mcmc pcnbd.mcmc 
# 0.04381472 0.03712778 
