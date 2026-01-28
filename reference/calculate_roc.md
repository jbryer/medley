# Calculate the statistics for receiver operating characteristic curve

This function was adapted from Raffel (https://github.com/joyofdata):
https://github.com/joyofdata/joyofdata-articles/blob/master/roc-auc/calculate_roc.R

## Usage

``` r
calculate_roc(predictions, observed, cost_of_fp = 1, cost_of_fn = 1, n = 100)

# S3 method for class 'roc'
summary(object, digits = 3, ...)

# S3 method for class 'roc'
plot(x, curve = "accuracy", legend.position = c(1, 0.2), ...)
```

## Arguments

- predictions:

  predicted values.

- observed:

  actual observed outcomes.

- cost_of_fp:

  cost of a false positive.

- cost_of_fn:

  cost of a false negative.

- n:

  the number of steps to estimate.

- object:

  result of \[calculate_roc()\].

- digits:

  number of digits to print.

- ...:

  currently unused.

- x:

  result of \[calculate_roc()\].

- curve:

  values can be cost, accuracy, or NULL.

- legend.position:

  position of the legend for teh accuracy curve plot.

## Value

a ggplot2 expression.
