



# Test 1

test_that("simmnar works as expected", {
  # Example
  data <- data.frame(
    ID = 1:10,
    X1 = c(1, 1, 0, 0, 1, 0, 0, 1, 1, 0),
    X2 = factor(c("low", "medium", "high", "medium", "low", "low", "high", "medium", "low", "high"),
                     levels = c("low", "medium", "high"), ordered = TRUE)
  )

  # Test
  set.seed(123)
  result <- simmnar(
    data = data,
    Y = "X1",
    id = "ID",
    ord_var = "X2",
    A = c("low", "medium"),
    probA = 0.5,
    B = c("medium", "high"),
    probB = 0.3
  )

  expect_true(all(c("X2", "X2.mis") %in% colnames(result)))
  expect_true(anyNA(result$X2.mis))

  # Vérifier que les données originales sont préservées
  expect_equal(result$X2, data$X2)
})

