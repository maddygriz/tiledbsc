#' Convert dgTMatrix to a COO-formatted Data Frame
#'
#' Combine a list of dGTMatrix objects in a single `data.frame`. If `x` is a
#' list of dgTMatrix's, then dimnames from the first matrix `x[[1]]` are used to
#' create the index columns in the resulting `data.frame`. Thus, dimnames in all
#' subsequent dgTMatrix matrices `x[[2:n]]` must be equal to or a subset of
#' `x[[1]]`'s dimnames.
#'
#' @param x A `dgTMatrix` or list of multiple dgTMatrix's.
#' @returns A `data.frame` with columns for the i/j indices, and a value column
#' for each of the matrices included in `x`
#'
#' @noRd
dgtmatrix_to_dataframe <- function(x, index_cols = c("i", "j"), value_cols = NULL) {
  if (inherits(x, "dgTMatrix")) {
    x <- list(x)
  }

  if (is.null(value_cols)) {
    if (is.null(names(x))) {
      value_cols <- paste0("value", seq_along(x))
    } else {
      value_cols <- names(x)
    }
  }

  stopifnot(length(index_cols) == 2, length(value_cols) == length(x))

  is_dgt <- vapply_lgl(x, inherits, what = "dgTMatrix")
  if (!all(is_dgt)) {
    stop("When 'x' is a list all elements must contain a dgTMatrix")
  }

  # dimension names from the first matrix are used to create the index columns
  row_labels <- rownames(x[[1]])
  col_labels <- colnames(x[[1]])

  index_data <- data.frame(
    i = row_labels[x[[1]]@i + 1],
    j = col_labels[x[[1]]@j + 1]
  )
  colnames(index_data) <- index_cols

  # To accommodate the specific case of a matrix containing scaled data from
  # seurat that contains only a subset of the features, we coerce to a
  # data.frame table and perform a left merge to automatically fill in missing
  # values as NA
  nmats <- length(x)
  for (i in seq_len(nmats)) {
    value_col <- value_cols[i]
    if (are_layerable(x[[1]], x[[i]])) {
      index_data[[value_col]] <- x[[i]][row_labels, col_labels]@x
    } else {
      value_tbl <- as.data.frame.table(as.matrix(x[[i]]))
      colnames(value_tbl) <- c(index_cols, value_col)
      index_data <- merge(index_data, value_tbl, by = index_cols, all.x = TRUE)
    }
  }
  return(index_data)
}

#' Convert from COO-formatted Data Frame to dgTMatrix
#' @param x A COO-formatted `data.frame` with columns for the i/j indices, and
#' and one or more value columns.
#' @returns A list of `dgTMatrix` objects, with one element per value column in
#' `x`.
#' @noRd
dataframe_to_dgtmatrix <- function(x, index_cols = c("i", "j")) {
  stopifnot(
    is.data.frame(x),
    length(index_cols) == 2,
    all(index_cols %in% colnames(x))
  )

  value_cols <- setdiff(colnames(x), index_cols)
  dim_labels <- as.list(x[index_cols])
  dim_names <- lapply(dim_labels, unique)
  dim_lengths <- vapply(dim_names, length, FUN.VALUE = integer(1L))

  mapply(
    FUN = Matrix::sparseMatrix,
    x = x[value_cols],
    MoreArgs = list(
      i = match(dim_labels[[1]], dim_names[[1]]),
      j = match(dim_labels[[2]], dim_names[[2]]),
      dims = dim_lengths,
      dimnames = unname(dim_names),
      repr = "T"
    )
  )
}

# Matrices with identical dimension names and non-empty coordinates can be
# stored as different layers (i.e., attributes of the same array)
#' @importFrom Matrix nnzero
are_layerable <- function(x, y) {
  stopifnot(is_matrix(x) && is_matrix(y))
  dimnames_match <- identical(dimnames(x), dimnames(y))
  nonemptycells_match <- Matrix::nnzero(x) == Matrix::nnzero(y)
  dimnames_match && nonemptycells_match
}


#' Pad a sparse Matrix with additional columns
#' @param x A dgTMatrix
#' @param colnames A vector of column names to add to the matrix.
#' @param returns A padded matrix containing all columns in `colnames`.
#' @importFrom Matrix sparseMatrix
#' @noRd
pad_matrix <- function(x, colnames) {
  stopifnot(
    inherits(x, "Matrix"),
    is.character(colnames) && !is_empty(colnames)
  )
  new_colnames <- setdiff(colnames, colnames(x))
  if (is_empty(new_colnames)) return(x)
  pad <- Matrix::sparseMatrix(
    i = integer(0L),
    j = integer(0L),
    dims = c(nrow(x), length(new_colnames)),
    dimnames = list(rownames(x), new_colnames)
  )
  cbind(x, pad)
}
