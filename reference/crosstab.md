# Contingency and proportional table as a character

This is a wrapper to \[base::table()\] and \[base::prop.table()\] but
returns the contingency and proportional table as a single character
string.

## Usage

``` r
crosstab(x, digits = 2, useNA = "ifany", sep = "; ")
```

## Arguments

- x:

  a factor.

- digits:

  number of digits for proportions.

- useNA:

  whether to include NA values in the table. See details in
  \[base::table()\].

- sep:

  separator between categories.

## Value

a character.

## Examples

``` r
data(mtcars)
crosstab(mtcars$am)
#> [1] "0: 19 (59.38%); 1: 13 (40.62%)"
```
