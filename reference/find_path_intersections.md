# Find the x and y coordinates where two paths intersect.

This function will find the coordinates where two lines intersect.

## Usage

``` r
find_path_intersections(df1, df2, x_col = names(df1)[1], y_col = names(df1)[2])
```

## Arguments

- df1:

  data frame for the first line.

- df2:

  data frame for the second line.

- x_col:

  the name of the column for the x-coordinate.

- y_col:

  the name of the column for the y-coordinate.

## Value

a data frame with the intersections.
