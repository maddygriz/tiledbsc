test_that("annotation matrix can be stored and retrieved", {

  uri <- file.path(withr::local_tempdir(), "annot-mat")
  mat <- matrix(runif(1000), nrow = 100, ncol = 10)

  annotmat <- AnnotationMatrix$new(uri)
  expect_true(inherits(annotmat, "AnnotationMatrix"))
  expect_error(
    annotmat$from_matrix(mat, index_col = "obs_id"),
    "must have defined dim names"
  )

  rlabs <- paste0("R", seq_len(nrow(mat)))
  clabs <- paste0("C", seq_len(ncol(mat)))
  dimnames(mat) <- list(rlabs, clabs)

  annotmat$from_matrix(mat, index_col = "obs_id")
  expect_true(dir.exists(annotmat$uri))
  expect_s4_class(annotmat$tiledb_array(), "tiledb_array")

  mat2 <- annotmat$to_matrix()
  expect_equal(sort(rownames(mat2)), sort(rownames(mat)))
  expect_equal(sort(colnames(mat2)), sort(colnames(mat)))

  expect_identical(mat[rlabs, clabs], mat2[rlabs, clabs])
})
