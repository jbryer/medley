# Create stratified data sets for modeling training and validation.

Create stratified data sets for modeling training and validation.

## Usage

``` r
stratified_split(data, outcome_col, train_prop = 0.8)
```

## Arguments

- data:

  data frame to split.

- outcome_col:

  the variable used for stratification.

- train_prop:

  proportion of observations used for the training data set.

## Value

a list with to data frames, \`train\` and \`validation\`.
