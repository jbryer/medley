#' Train models using different combinations of predictor variables based upon
#' missing data patterns.
#'
#'
#' @param data data.frame used to estimate the models.
#' @param formula with all possible predictor varaibles to be considered.
#' @param method the function used to train the models (e.g. glm, randomForest).
#' @param var_sets a list of formulas to use for the predictive models.
#' @param min_set_size the minimum set size as a percentage to incldue as a model.
#' @param exclusive_membership whether an observation should only be used only in
#'        the model for which the most predictor variables are available. If
#'        `FALSE` then observations may be used in training more than one model.
#' @param ... other parameters passed to `method` function.
#' @return an object with the following elements:
#' \describe{
#'	\item{n_models}{the number of models trained.}
#'	\item{formulas}{the list of formulas used to train the models.}
#'	\item{models}{list of objects returned from the training method.}
#'	\item{data}{the data.frame used to train the models.}
#'	\item{model_observations}{a data.frame that specifies which observations are used for which model(s).}
#' }
#' @importFrom ComplexHeatmap make_comb_mat
#' @export
medley_train <- function(
		data,
		formula,
		method = glm,
		var_sets = get_variable_sets(data = data, formula = formula, min_set_size = min_set_size),
		min_set_size = 0.1, # TODO: May want to consider raw n instead of percentage
		exclusive_membership = TRUE,
		...
) {
	formula <- expand_formula(formula, data)
	data <- data[,all.vars(formula)]
	dep_var <- all.vars(formula)[1]
	shadow_matrix <- as.data.frame(!is.na(data))

	results <- list()
	results$models <- list()
	results$formulas <- var_sets
	results$data <- data
	results$n_models <- length(var_sets)

	obs_membership <- matrix(FALSE,
							 ncol = length(var_sets),
							 nrow = nrow(data))
	colnames(obs_membership) <- paste0('m', 1:length(var_sets))
	for(i in seq_len(length(var_sets))) {
		f <- var_sets[[i]]
		rows <- apply(shadow_matrix[,all.vars(f)], 1, FUN = all)
		obs_membership[,i] <- rows
	}
	if(exclusive_membership) {
		for(i in 2:length(var_sets)) {
			rows <- apply(obs_membership[,1:(i - 1), drop = FALSE], 1, any) |> which()
			obs_membership[rows,i] <- FALSE
		}
	}

	results$model_observations <- obs_membership

	obs_no_model <- apply(obs_membership, 1, FUN = function(x) { !any(x) }) |> sum()
	if(obs_no_model > 0) {
		warning(paste0('There are ', obs_no_model, ' (',
					   round(100 * obs_no_model / nrow(data), digits = 2),
					   '%) observations that do not have enough data for any model.'))
	}

	for(i in seq_len(length(var_sets))) {
		f <- var_sets[[i]]
		rows <- obs_membership[,i,drop=TRUE]
		results$models[[i]] <- method(formula = f, data = data[rows,])
	}

	class(results) <- 'medley'
	return(results)
}

#' @rdname medley_train
#' @method summary medley
#' @importFrom huxtable huxreg print_screen
#' @export
summary.medley <- function(object, ...) {
	# huxtable::huxreg(object$models) |> huxtable::print_screen()
	model_sum <- data.frame(
		Model = seq_len(object$n_models),
		n = apply(object$model_observation, 2, sum),
		Success = apply(object$model_observation, 2, FUN = function(x) {
			object$data[x,]$retained |> mean() * 100
		}),
		Formula = as.character(object$formulas),
		check.names = FALSE
	)
	model_sum
}

#' @rdname medley_train
#' @method print medley
#' @param x the results of `medley_train`.
#' @param ... currently not used.
print.medley <- function(x, ...) {
	summary(x, ...)
}

#' @rdname medley_train
#' @param object the results from `medley_train`.
#' @param newdata (optional) a new data.frame to get predictions for.
#' @param ... other parameters passed to the `predict()` function.
#' @return a vector of predictions.
#' @importFrom stats predict
#' @export
#' @method predict medley
predict.medley <- function(object, newdata, ...) {
	if(missing(newdata)) {
		newdata <- object$data
	}

	predictions <- rep(NA_real_, nrow(newdata))
	shadow_matrix <- as.data.frame(!is.na(newdata))

	# TODO: Currently predictions are only provided from the first model (i.e. the
	# one with the most variables). Perhaps allow for weighted averages based upon
	# model fit.
	for(i in rev(seq_len(length(object$models)))) {
		model <- object$models[[i]]
		f <- object$formulas[[i]]
		rows <- apply(shadow_matrix[,all.vars(f)], 1, FUN = all)
		predictions[rows] <- predict(model, newdata = newdata[rows,], ...)
	}
	return(predictions)
}
