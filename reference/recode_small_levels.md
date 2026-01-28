# Recode levels of a factor that are below a given threshold.

This function will first calculate a contingency table. For any
categories that are below the specified \`threshold\`, the raw values in
\`x\` will be recoded. The default is \`NA\`, but can be specified by
the \`recode_to\` parameter. The resulting vector will be converted to a
factor using the \`factor()\` function.

## Usage

``` r
recode_small_levels(x, recode_to = NA, threshold = length(x) * 0.01, ...)
```

## Arguments

- x:

  a vector.

- recode_to:

  the value to recode small factor levels to.

- threshold:

  the threshold of a factor level count for it to be recoded.

- ...:

  other parameters passed to \`factor()\`.

## Value

a recoded factor. The result will be a factor regardless of the type of
\`x\`.

## Examples

``` r
data(mtacars)
#> Warning: data set ‘mtacars’ not found
table(mtcars$carb)
#> 
#>  1  2  3  4  6  8 
#>  7 10  3 10  1  1 
cbind(mtcars$carb, medley::recode_small_levels(mtcars$carb, threshold = 2))
#>       [,1] [,2]
#>  [1,]    4    4
#>  [2,]    4    4
#>  [3,]    1    1
#>  [4,]    1    1
#>  [5,]    2    2
#>  [6,]    1    1
#>  [7,]    4    4
#>  [8,]    2    2
#>  [9,]    2    2
#> [10,]    4    4
#> [11,]    4    4
#> [12,]    3    3
#> [13,]    3    3
#> [14,]    3    3
#> [15,]    4    4
#> [16,]    4    4
#> [17,]    4    4
#> [18,]    1    1
#> [19,]    2    2
#> [20,]    1    1
#> [21,]    1    1
#> [22,]    2    2
#> [23,]    2    2
#> [24,]    4    4
#> [25,]    2    2
#> [26,]    1    1
#> [27,]    2    2
#> [28,]    2    2
#> [29,]    4    4
#> [30,]    6   NA
#> [31,]    8   NA
#> [32,]    2    2
```
