# Model training using downsampling.

Consider a dataset where there is 10-to-1 ratio between class A and B in
the dependent varaible. Assuming we wish to maintain a 1-to-1 ratio for
each model (this can modified using the \`ratio\` parameter), each
observation in larger class (say A here) will be randomly assigned a
number between 1 and 10. In this example, 10 models will be estimated.
Observations from the smaller class will be used in every model but
observations in the larger class will be used in only one of the models.
This is potentially advantageous since all data is used in the model.

## Usage

``` r
downsample(formu, data, model_fun, ratio = 1, show_progress = TRUE, ...)

# S3 method for class 'downsample'
predict(object, newdata, ...)
```

## Arguments

- formu:

  an object of class "formula" (or one that can be coerced to that
  class): a symbolic description of the model to be fitted.

- data:

  data frame with the data to estimate the model from.

- model_fun:

  modeling function (e.g. \`glm\`).

- ratio:

  the ratio of small class to the larger class when downsampling.

- show_progress:

  if TRUE a progress bar will be displayed showing the status of the
  model estimations.

- ...:

  other parameters passed to \`model_fun\`.

- object:

  result of \[downsample()\].

- newdata:

  An optional data frame in which to look for variables with which to
  predict. If omitted, the fitted values are used.

## Value

a list of model outputs, the results of \`model_fun\`.

## Details

It should be noted that this function is simply a wrapper to any
prediction function as long as the first parameter is model formula and
the second parameter is a data frame. The \`downsample\` function will
pass any parameters to the \`model_fun\` through the \`...\`.

The \`predict\` function will return a data frame where each row
corresponds to the row in the training data frame or the \`newdata\`
data frame and the columns are the predicted values from each of the
trained models. Note that the \`...\` parameter will be passed to the
appropriate \`predict\` function. For example, if the models were
trained using \`glm\` for a logistic regression, the passing \`type =
'response'\` will provided the predicted probabilities.

## Examples

``` r
data("pisa", package = "medley")
train_rows <- sample(nrow(pisa) * .7)
pisa_train <- pisa[train_rows,]
pisa_valid <- pisa[-train_rows,]
pisa_ds_out <- downsample(
    formu = Public ~ .,
    data = pisa_train,
    model_fun = glm,
    ratio = 2,
    family = binomial(link = 'logit')
)
#>   |                                                                              |                                                                      |   0%  |                                                                              |==============                                                        |  20%  |                                                                              |============================                                          |  40%  |                                                                              |==========================================                            |  60%  |                                                                              |========================================================              |  80%  |                                                                              |======================================================================| 100%
pisa_predictions_ds <- predict(pisa_ds_out, newdata = pisa_valid, type = 'response')
pisa_predictions_ds2 <- pisa_predictions_ds |> apply(1, mean)
```
