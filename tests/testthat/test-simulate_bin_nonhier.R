test_that("simulate_bin_nonhier works correctly", {

  # Basic simulation
  dat <- simulate_bin_nonhier(n = 1000, levels_X2 = 4, levels_X1 = 5, seed = 123)

  # Check dimensions
  expect_true(is.data.frame(dat))
  expect_equal(nrow(dat), 1000)
  expect_equal(colnames(dat), c("id", "X2", "X1", "Y"))

  # Check types
  expect_true(is.factor(dat$X2))
  expect_true(is.ordered(dat$X1))
  expect_true(is.factor(dat$Y))

  # Check levels
  expect_equal(length(levels(dat$X2)), 4)
  expect_equal(length(levels(dat$X1)), 5)
  expect_equal(levels(dat$Y), c("0", "1"))

  # Reproducibility
  dat2 <- simulate_bin_nonhier(n = 1000, levels_X2 = 4, levels_X1 = 5, seed = 123)
  expect_equal(dat, dat2)
})
