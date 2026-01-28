# Calculate the accuracy rate.

This function provides the overall accuracy rate for the two vectors.
This is the sum of the true positive and true negative values.

sum(True positive) / sum(Condition positive)

sum(True negative) / sum(Condition negative)

## Usage

``` r
accuracy(observed, predicted)

sensitivity(observed, predicted)

specificity(observed, predicted)
```

## Arguments

- observed:

  vector of observed values.

- predicted:

  vector of predicted values.

## Value

the accuracy as a numeric value.
