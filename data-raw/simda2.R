devtools::load_all()

# Generate a simulated hierarchical dataset

length_X1 <- 3  # Number of ordered levels for X1
length_X2 <- 4  # Number of unordered levels for X2 (A, B, C, D)

formula_X1 <- "~ X2"
formula_Y <- "~ X1 + X2"

# Correct para_X1: it must have (length_X2 - 1) rows and length_X1 columns
# So here: (4 - 1) = 3 rows, 3 columns
para_X1 <- matrix(
  c(
    2, 1.5, 2.5,   # coefficients pour X2_B
    1, 2.5, 1.5,   # coefficients pour X2_C
    2.5, 1, 2      # coefficients pour X2_D
  ),
  nrow = 3,
  byrow = TRUE
)

# Correct beta: it must match the number of columns of model.matrix(~ X1 + X2)
# Components:
# (Intercept) + (length_X1 - 1) + (length_X2 - 1)
# = 1 + (3 - 1) + (4 - 1) = 1 + 2 + 3 = 6
# So 6 coefficients needed
beta <- c(-1, 1, -2, 2, 1, 2)

# Other parameters
n_clus <- 10    # Number of clusters
n_obs <- 500    # Observations per cluster
sd_U <- 0.45    # Standard deviation of the random effects
seed <- 123     # Seed for reproducibility

# Generate the dataset
simda2 <- simulate_bin_hier(
  length_X1 = length_X1,
  length_X2 = length_X2,
  formula_X1 = formula_X1,
  formula_Y = formula_Y,
  para_X1 = para_X1,
  beta = beta,
  n_clus = n_clus,
  n_obs = n_obs,
  sd_U = sd_U,
  seed = seed
)

# Save the dataset into the /data/ folder
usethis::use_data(simda2, overwrite = TRUE)
