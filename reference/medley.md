# Train models using different combinations of predictor variables based upon missing data patterns.

This function will train a collection of models based upon the pattern
of missingness. Each observation will be used in the model with most
dependent variables available. For example, consider the following
data.frame where \`y\` is the dependent variable, \`x\` represents an
observed value, and \`NA\` indicates a missing value:

## Usage

``` r
medley(
  formula,
  data,
  method = glm,
  var_sets = get_variable_sets(data = data, formula = formula, min_set_size =
    min_set_size),
  min_set_size = 0.1,
  exclusive_membership = TRUE,
  ...
)

# S3 method for class 'medley'
summary(object, ...)

# S3 method for class 'medley'
print(x, ...)

# S3 method for class 'medley'
predict(object, newdata, ...)

# S3 method for class 'medley'
fit(object, ...)
```

## Arguments

- formula:

  with all possible predictor varaibles to be considered.

- data:

  data.frame used to estimate the models.

- method:

  the function used to train the models (e.g. glm, randomForest).

- var_sets:

  a list of formulas to use for the predictive models.

- min_set_size:

  the minimum set size as a percentage to incldue as a model.

- exclusive_membership:

  whether an observation should only be used only in the model for which
  the most predictor variables are available. If \`FALSE\` then
  observations may be used in training more than one model. This is
  experimental.

- ...:

  other parameters passed to the \`fit()\` function.

- object:

  the results from \`medley\`.

- x:

  the results of \`medley\`.

- newdata:

  (optional) a new data.frame to get predictions for.

## Value

an object with the following elements:

- n_models:

  the number of models trained.

- formulas:

  the list of formulas used to train the models.

- models:

  list of objects returned from the training method.

- data:

  the data.frame used to train the models.

- model_observations:

  a data.frame that specifies which observations are used for which
  model(s).

a vector of predictions.

a vector of fitted values.

## Details

“\` ID Y Var1 Var2 Var3 1 x x x x 2 x x x NA 3 x x NA NA “\`

We can train three different models:

\* Model 1: Y ~ Var1 + Var2 + Var3 \* Model 2: Y ~ Var1 + Var2 \* Model
3: Y ~ Var1

When deciding what model each observation will be used in is determined
by examining which model has the most dependent variables that row has
values for. In the example above, row 1 would be used with model 1, row
2 would be used with model 2, and row 3 would be used with model 3.

If \`exclusive_membership = FALSE\` then row 1 would be used in all 3
models and row 2 would be used in models 2 and 3. I do recommend using
this parameter with caution as model assumptions are not confirmed,
especially independence.

## Examples

``` r
formulas <- medley::get_variable_sets(daacs, retained ~ .)
medley_out <- medley(data = daacs, formula = retained ~ ., var_sets = formulas)
predicted_values <- predict(medley_out)
#> Warning: Predictions will be returned from the first model only.
```
