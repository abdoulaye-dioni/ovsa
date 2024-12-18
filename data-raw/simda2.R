simulation_hierachical <- function(length_x1, length_x2, formula_x1, formula_y, para_x1,  betas,n_clus,n_obs,sd_U) {
  x2 <- factor(sample(1:length_x2, n_clus*n_obs, replace = TRUE, prob = rep(0.25,4)))
  eta_x1 <- model.matrix(as.formula(formula_x1), data.frame( x2 = x2))[,-1] %*% as.matrix(para_x1)
  prob_x1 <-  t(apply(eta_x1, 1, function(x) exp(x - max(x)) / sum(exp(x - max(x)))))
  x1 <- ordered(apply(prob_x1, 1, function(p) sample(1:length(p), 1, prob = p)))
  clus <- rep(1:n_clus, each=n_obs)
  U <- rnorm(n_clus, mean=0, sd = sd_U)
  ZU <- U[clus]
  eta_y <- model.matrix(as.formula(formula_y), data = data.frame(x1 = x1, x2 = x2)) %*%betas + ZU
  prob_y <- plogis(eta_y)
  y <- as.factor(rbinom(n_clus*n_obs, 1, prob_y))

  return(data.frame(id = seq_len(n_clus*n_obs), y = y, x1 = x1,  x2 = x2, clus = clus))
}


set.seed(100)
nsim = 500
n_clus = 10
n_obs = 200
length_x1 <- 3
length_x2 = 4
sd_U = 0.45
A = 1
B = 3


formula_x1 <- "~ x2"
para_x1 <- matrix(c(rep(2,3), rep(1,3),rep(2.5,3) ),ncol = 3)


formula_y <- "~ x1 + x2"
betas <- c(-1, 1, -2, 2,  1, 2)


datas <-  lapply(1:nsim, function(simulation) {
  data <- simulation_hierachical(length_x1, length_x2, formula_x1, formula_y, para_x1,  betas,n_clus,n_obs,sd_U)
  return(data)
})

simda2 <- datas[[1]]

usethis::use_data(simda2, overwrite = TRUE)
