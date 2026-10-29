# Stratified Generalized Linear Models

This modeling approach subdivides the majority class into strata of size
of the minority class, times a ratio (which is 1 by default). The models
are combined using the same technique for combining multiple imputed
data sets in order to not decrease standard error estimates with
artificially large sample sizes. See stratified_glm vignette for more
details.

## Usage

``` r
stratified_glm(
  formula,
  data,
  ratio = 1,
  family = stats::binomial(link = "logit"),
  ...
)

# S3 method for class 'stratified.glm'
summary(object, ...)

# S3 method for class 'stratified.glm'
fitted(object, ...)

# S3 method for class 'stratified.glm'
predict(object, newdata = NULL, ...)

# S3 method for class 'stratified.glm'
plot(x, geom = ggplot2::geom_density(alpha = 0.5), facet = TRUE, ...)
```

## Arguments

- formula:

  an object of class "formula" (or one that can be coerced to that
  class): a symbolic description of the model to be fitted. See
  \[stats::glm()\] for more information.

- data:

  an optional data frame, list or environment (or object coercible by
  as.data.frame to a data frame) containing the variables in the model.
  See \[stats::glm()\] for more information.

- ratio:

  the ratio of the small-to-large group. That is, how many observations
  from the larger group should be randomly selected. A ratio of 1 means
  that there are the (approximately) same number of observations in both
  outcome groups.

- family:

  a description of the error distribution and link function to be used
  in the model. This should almost always be \`binomial(link='logit')\`.

- ...:

  currently not used.

- object:

  results from \`stratified_glm()\`.

- newdata:

  optionally, a data frame in which to look for variables with which to
  predict. If omitted, the fitted linear predictors are used.

- x:

  results from \`stratified_glm()\`

- geom:

  the \`ggplot2\` geometry to use. Typically \[ggplot2::geom_density()\]
  or \[ggplot2::geom_histogram()\].

- facet:

  whether to use \[ggplot2::facet_wrap()\] based on the model type.

## Value

a list object with the following elements:

- formula:

  an object of class "formula" (or one that can be coerced to that
  class): a symbolic description of the model to be fitted.

- data:

  data frame used for the model fitting.

- ratio:

  the ratio used for the big to small group.

- cont_tab:

  the contingency table for the outcome variable.

- data_big:

  subset of \`data\` for the bigger of the two groups.

- data_small:

  subset of \`data\` for the larger of the two groups.

- model:

  the \[stats::glm()\] results using all the data.

- n_models:

  the number of models that will be estimated.

- assignment:

  a numeric vector equal to \`nrow(data)\` that corresponds to what.

- models:

  a list with the following elements for each model run:

  model

  :   the results of \[stats::glm()\].

  data

  :   the subset of \`data\` used for this iteration.

  fitted

  :   the fitted values for this iteration. Note that the order of this
      vector corresponds to the \`data\` subset for this iteration, not
      the full data.

  rows

  :   an integer vector mapping the rows from this iteration back to the
      full data frame.

- fitted:

  matrix of fitted values. The columns correspond to each model
  iteration.

the results from \[mitools::MIcombine()\].

a numeric vector with the fitted values. Note that for the small group,
the fitted value is the average across all models. Individual vectors of
fitted values can be retrieved from \`object\$fitted\`.

a \`ggplot2\` expression.
