# Utility function that will expand the formula if the independent variable(s) are not full specified.

This function will add all the independent variables to the formula if
the formula was specified as \`y ~ .\`.

## Usage

``` r
expand_formula(formula, data)
```

## Arguments

- formula:

  the formula to expand.

- data:

  the data.frame the formula will be applied to.

## Value

a formula with all independent variables specified explicitly.
