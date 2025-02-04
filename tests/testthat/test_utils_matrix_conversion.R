
test_that("conversion of dgTMatrix to COO data frame", {
  mat <- as(GetAssayData(pbmc_small, "counts"), "dgTMatrix")
  df <- dgtmatrix_to_dataframe(mat)
  testthat::expect_true(is.data.frame(df))

  ilabs <- unique(df$i)
  expect_true(all(ilabs %in% rownames(mat)))

  jlabs <- unique(df$j)
  expect_true(all(jlabs %in% colnames(mat)))

  mat2 <- dataframe_to_dgtmatrix(df)[[1]]
  expect_identical(
    mat[ilabs, jlabs],
    mat2[ilabs, jlabs]
  )
})


test_that("conversion of a list dgTMatrix's to COO data frame", {
  mats <- list(
    SeuratObject::GetAssayData(pbmc_small, "counts"),
    SeuratObject::GetAssayData(pbmc_small, "data")
  )
  mats <- lapply(mats, FUN = as, Class = "dgTMatrix")

  df <- dgtmatrix_to_dataframe(mats)
  testthat::expect_true(is.data.frame(df))
  testthat::expect_equal(ncol(df), 4)

  ilabs <- unique(df$i)
  jlabs <- unique(df$j)

  mats2 <- dataframe_to_dgtmatrix(df, index_cols = c("i", "j"))
  expect_identical(
    mats[[1]][ilabs, jlabs],
    mats2[[1]][ilabs, jlabs]
  )
  expect_identical(
    mats[[2]][ilabs, jlabs],
    mats2[[2]][ilabs, jlabs]
  )
})
