
set.seed(123)
simda <- data.frame(
  id = seq_len(1000),
  X2 = factor(sample(1:4, 1000, replace = TRUE, prob = rep(0.25, 4))))

simda$X1 <- ordered(
  apply(
    t(
      apply(
        model.matrix(~ X2, data = simda)[, -1] %*%
          as.matrix(matrix(c(rep(2, 3), rep(1, 9), rep(2.5, 3)), ncol = 5)),
        1, function(x) exp(x - max(x)) / sum(exp(x - max(x)))
      )
    ),
    1, function(p) sample(1:length(p), 1, prob = p)
  ),
  1:5
)

simda$Y <- as.factor(
  rbinom(
    1000,
    1,
    plogis(
      model.matrix(~ X1 + X2, data = simda) %*% c(-1.5, 1, -2, 1.5, 2, 2, 1, 2)
    )
  )
)


usethis::use_data(simda, overwrite = TRUE)
