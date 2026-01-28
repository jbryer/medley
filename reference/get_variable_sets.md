# Gets list of model formulas based upon the missing data pattern in the data set.

Gets list of model formulas based upon the missing data pattern in the
data set.

## Usage

``` r
get_variable_sets(data, formula, min_set_size = 0.1)

# S3 method for class 'variableset'
print(x, ...)
```

## Arguments

- data:

  the data.frame.

- formula:

  the formula that includes all the possible variables to consider for
  the predictive models.

- min_set_size:

  the minimum set size as a percentage to include as a model.

- x:

  the results from \`get_variable_sets()\`.

- ...:

  currently unused.

## Value

a list of formulas, in order to be used, for the predictive models.
