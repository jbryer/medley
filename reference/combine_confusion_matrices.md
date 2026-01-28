# Combine multiple confusion matrices into a single table.

This will combine multiple confusion matrices into a single table ideal
for comparing the performance across multiple models.

## Usage

``` r
combine_confusion_matrices(..., digits = 2)
```

## Arguments

- ...:

  results from \[confusion_matrix()\]. If the parameters are named those
  will be used as the row names for each matrix.

- digits:

  number of digits.
