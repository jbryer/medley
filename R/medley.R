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
	results$data <- data
	results$n_models <- length(var_sets)
	results$messages <- character()

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
		results$messages <- c(
			results$messages,
			paste0('There are ', obs_no_model, ' (',
				   round(100 * obs_no_model / nrow(data), digits = 2),
				   '%) observations that do not have enough data for any model.')
		)
	}

	for(i in seq_len(length(var_sets))) {
		f <- var_sets[[i]]
		rows <- obs_membership[,i,drop=TRUE]
		model_data <- data[rows, all.vars(f)] |> as.data.frame() # In case it is a tibble
		for(v in all.vars(f)) {
			if(is.factor(model_data[,v])) {
				if(!all(levels(model_data[,v]) %in% unique(model_data[,v]))) {
					if(is.ordered(model_data[,v])) {
						stop(paste0(v, ' variable has unused levels in model ', i,
									'. May want to consider converting to an integer.'))
					}
					results$messages <- c(
						results$messages,
						paste0(v, ' variable recoded to remove unused contrasts for model ', i)
					)
					model_data[,v] <- model_data[,v] |> as.character() |> as.factor()
				}
				if(length(unique(model_data[,v])) == 1) {
					results$messages <- c(
						results$messages,
						paste0(v, ' variable has only one contrast. Removing from model ', i)
					)
					vars <- all.vars(f)
					vars <- vars[vars != v]
					f <- as.formula(paste0(vars[1], ' ~ ', paste0(vars[-1], collapse = ' + ')))
					var_sets[[i]] <- f
				}
			}
		}
		results$models[[i]] <- method(formula = f, data = model_data, ...)
	}

	results$formulas <- var_sets
	if(length(results$messages) > 0) {
		warning('There were warnings generated during training. See messages on the returned object.')
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
	dep_var <- all.vars(object$formulas[[1]])[1]
	model_sum <- data.frame(
		Model = seq_len(object$n_models),
		n = apply(object$model_observation, 2, sum),
		Success = apply(object$model_observation, 2, FUN = function(x) {
			object$data[x,dep_var] |> mean() * 100
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
