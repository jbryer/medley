# Calculate the statistics for receiver operating characteristic curve

This function

## Usage

``` r
calculate_roc(predictions, observed, cost_of_fp = 1, cost_of_fn = 1, n = 100)

# S3 method for class 'roc'
summary(object, digits = 3, ...)

# S3 method for class 'roc'
plot(
  x,
  curve = "accuracy",
  legend.theme = ggplot2::theme(legend.position = "none"),
  digits = 2,
  ...
)
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

  the number of digits to print.

- ...:

  currently not used.

- x:

  result of \[calculate_roc()\].

- curve:

  values can be \`cost\`, \`accuracy\`, or \`NULL\`.

- legend.theme:

  \[ggplot2::theme()\] elements used to define the positioning of the
  legend.

## Value

a ggplot2 expression.

## References

This function was adapted from Raffel (https://github.com/joyofdata):
https://github.com/joyofdata/joyofdata-articles/blob/master/roc-auc/calculate_roc.R

## Examples

``` r
data('pisa', package = 'medley')
ggplot2::theme_set(ggplot2::theme_minimal())
lr_out <- glm(Public ~ ., data = pisa, family = binomial(link = 'logit'))
roc <- medley::calculate_roc(
    predictions = fitted(lr_out),
    observed = pisa$Public
)
summary(roc)
#> AUC = 0.814
#> Cost of false-positive = 1
#> Cost of false-negative = 1
#> Threshold with minimum cost = 0.444 (accuracy = 93.4%)
#> Threshold with maximum accuracy = 0.444 (accuracy = 93.4%)
#> Sensitivity and specificity intersection = 0.927 (accuracy = 73.1%)
plot(roc)
```
