# Calculate a confusion matrix

Calculate a confusion matrix

## Usage

``` r
confusion_matrix(
  observed,
  predicted,
  label_false = "FALSE",
  label_true = "TRUE"
)

# S3 method for class 'confusionmatrix'
as.data.frame(x, row.names = NULL, optional = FALSE, digits = 2, ...)

# S3 method for class 'confusionmatrix'
print(x, digits = 2, ...)
```

## Arguments

- observed:

  vector of observed values. The vector should either be a numeric
  vector of 0s and 1s or logical.

- predicted:

  vector of predicted values. The vector should either be a numeric
  vector of 0s and 1s or logical.

- label_false:

  label for FALSE values

- label_true:

  label for TRUE values.

- x:

  the result of \[confusion_matrix()\].

- row.names:

  not used.

- optional:

  not used.

- digits:

  number of decimal places to print.

- ...:

  currently not used.

## Value

a data.frame of the confusion matrix.

## Examples

``` r
observed <- c(rep(FALSE, 10), rep(TRUE, 2))
predicted <- rep(TRUE, 12)
confusion_matrix(observed, predicted, label_true = 'Success', label_false = 'Failure')
#>            predicted            
#>   observed   Failure     Success
#>    Failure 0 (0.00%) 10 (83.33%)
#>    Success 0 (0.00%)  2 (16.67%)
#> Accuracy: 16.67%
#> Sensitivity: %
#> Specificity: %
```
