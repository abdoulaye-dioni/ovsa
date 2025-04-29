
devtools::load_all()

# Generate a simulated dataset
simda <- simulate_bin_nonhier(n = 1000, levels_X2 = 4,
                                          levels_X1 = 5,seed = 123)

# Save the dataset into the /data/ folder
usethis::use_data(simda, overwrite = TRUE)
