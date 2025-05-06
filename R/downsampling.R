#' Model training using downsampling.
#'
#' Consider a dataset where there is 10-to-1 ratio between class A and B in the dependent varaible.
#' Assuming we wish to maintain a 1-to-1 ratio for each model (this can modified using the `ratio`
#' parameter), each observation in larger class (say A here) will be randomly assigned a number
#' between 1 and 10. In this example, 10 models will be estimated. Observations from the smaller
#' class will be used in every model but observations in the larger class will be used in only
#' one of the models. This is potentially advantageous since all data is used in the model.
#'
#' It should be noted that this function is simply a wrapper to any prediction function as long as
#' the first parameter is model formula and the second parameter is a data frame. The `downsample`
#' function will pass any parameters to the `model_fun` through the `...`.
#'
#' The `predict` function will return a data frame where each row corresponds to the row in the
#' training data frame or the `newdata` data frame and the columns are the predicted values from
#' each of the trained models. Note that the `...` parameter will be passed to the appropriate
#' `predict` function. For example, if the models were trained using `glm` for a logistic regression,
#' the passing `type = 'response'` will provided the predicted probabilities.
#'
#' @param formu an object of class "formula" (or one that can be coerced to that class): a symbolic
#'        description of the model to be fitted.
#' @param data data frame with the data to estimate the model from.
#' @param ratio the ratio of small class to the larger class when downsampling.
#' @param model_fun modeling function (e.g. `glm`).
#' @param ... other parameters passed to `model_fun`.
#' @return a list of model outputs, the results of `model_fun`.
#' @rdname downsample
#' @export
#' @examples
#' data("pisa", package = "medley")
#' train_rows <- sample(nrow(pisa) * .7)
#' pisa_train <- pisa[train_rows,]
#' pisa_valid <- pisa[-train_rows,]
#' pisa_ds_out <- downsample(
#'     formu = Public ~ .,
#'     data = pisa_train,
#'     model_fun = glm,
#'     ratio = 2,
#'     family = binomial(link = 'logit')
#' )
#' pisa_predictions_ds <- predict(pisa_ds_out, newdata = pisa_valid, type = 'response')
#' pisa_predictions_ds2 <- pisa_predictions_ds |> apply(1, mean)
downsample <- function(formu, data, model_fun, ratio = 1, ...) {
	data <- as.data.frame(data)
	dep_var <- all.vars(formu)[1]
	tab_out <- table(data[,dep_var])
	big_class <- names(tab_out[tab_out == max(tab_out)])
	small_class <- names(tab_out[tab_out == min(tab_out)])
	train_big <- data[data[,dep_var] == big_class,]
	train_small <- data[data[,dep_var] == small_class,]
	n_models <- floor(nrow(train_big) / (ratio * nrow(train_small)))
	if(n_models == 1) {
		warning('Only training one model. Is this really what you want to do?')
	}
	model <- rep(1:n_models, length.out = nrow(train_big)) |> sample()
	# model <- sample(n_models, size = nrow(train_big), replace = TRUE)
	models <- list()
	for(i in seq_len(n_models)) {
		train_data <- rbind(train_small, train_big[model == i,])
		models[[i]] <- model_fun(formu, train_data, ...)
	}
	attr(models, 'formula') <- formu
	attr(models, 'data') <- data
	class(models) <- c('downsample', 'list')
	return(models)
}

#' Predict values from downsampling
#'
#' @param object result of [downsample()].
#' @param newdata An optional data frame in which to look for variables with which to predict.
#'        If omitted, the fitted values are used.
#' @rdname downsample
#' @method predict downsample
#' @export
predict.downsample <- function(object, newdata, ...) {
	if(missing(newdata)) {
		newdata <- attr(object, 'data')
	}
	predictions <- data.frame(predict(object[[1]], newdata = newdata, ...))
	if(length(object) > 1) {
		for(i in 2:length(object)) {
			predictions <- cbind(predictions, predict(object[[i]], newdata = newdata, ...))
		}
	}
	names(predictions) <- paste0('model', 1:length(object))
	return(predictions)
}
