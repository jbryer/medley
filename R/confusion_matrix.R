#' Calculate a confusion matrix
#'
#' @param observed vector of observed values.
#' @param predicted vector of predicted values.
#' @return a data.frame of the confusion matrix.
#' @export
confusion_matrix <- function(observed, predicted) {
	if(length(unique(predicted)) > 2) {
		warning('Looks like predicted probabilities were provided. Dichotomizing at 0.5.')
		predicted <- predicted > 0.5
	}
	ct <- table(observed, predicted)
	pt <- prop.table(ct)
	result <- cbind(as.data.frame(ct), percent = as.data.frame(pt)[,3])
	attr(result, 'accuracy') <- pt[1,1] + pt[2,2]
	class(result) <- c('confusionmatrix', 'data.frame')
	return(result)
}

#' @rdname confusion_matrix
#' @param x the result of [confusion_matrix()].
#' @param digits number of decimal places to print.
#' @param ... currently not used.
#' @method as.data.frame confusionmatrix
#' @export
as.data.frame.confusionmatrix <- function(x, digits = 2, ...) {
	class(x) <- 'data.frame'
	x$value <- paste0(
		x$Freq, ' (', formatC(100 * x$percent, digits = digits, flag = '0', format = 'f'), '%)'
	)
	x1 <- reshape2::dcast(x, observed ~ predicted, value.var = 'value')
	x2 <- reshape2::dcast(x, observed ~ predicted, value.var = 'percent')
	x1[,1] <- as.character(x1[,1])
	x1 <- cbind(c('Observed', ''), x1)
	x1 <- rbind(names(x1), x1)
	names(x1) <- c('', '', 'predicted', '')
	x1[1:2, 1] <- ''
	return(x1)
}

#' @rdname confusion_matrix
#' @param x the result of [confusion_matrix()].
#' @param digits number of decimal places to print.
#' @param ... currently not used.
#' @method print confusionmatrix
#' @importFrom reshape2 dcast
#' @export
print.confusionmatrix <- function(x, digits = 2, ...) {
	class(x) <- 'data.frame'
	x$value <- paste0(
		x$Freq, ' (', formatC(100 * x$percent, digits = digits, flag = '0', format = 'f'), '%)'
	)
	x1 <- reshape2::dcast(x, observed ~ predicted, value.var = 'value')
	x2 <- reshape2::dcast(x, observed ~ predicted, value.var = 'percent')
	x1[,1] <- as.character(x1[,1])
	x1 <- cbind(c('Observed', ''), x1)
	x1 <- rbind(names(x1), x1)
	names(x1) <- c('', '', 'predicted', '')
	x1[1:2, 1] <- ''
	print(x1, row.names = FALSE, na.print = '')
	cat(paste0('Accuracy: ', round(100 * (x2[1,2] + x2[2,3]), digits = digits), '%'))
}

#' Calculate the accuracy rate.
#'
#' This function provides the overall accuracy rate for the two vectors.
#'
#' @param observed vector of observed values.
#' @param predicted vector of predicted values.
#' @return the accuracy as a numeric value.
#' @export
accuracy <- function(observed, predicted) {
	tab_out <- table(observed, predicted) |> prop.table()
	tab_out[1,1] + tab_out[2,2]
}

#' Combine multiple confusion matrices into a single table.
#'
#' This will combine multiple confusion matrices into a single table ideal
#' for comparing the performance across multiple models.
#'
#' @param ... results from [confusion_matrix()]. If the parameters are named
#'        those will be used as the row names for each matrix.
#' @param digits number of digits.
#' @export
combine_confusion_matrices <- function(..., digits = 2) {
	cm <- list(...)
	if(is.null(names(cm))) {
		model_names <- paste0('Model ', 1:length(cm))
	} else {
		model_names <- names(cm)
	}

	cm2 <- list()
	for(i in 1:length(cm)) {
		cm2[[i]] <- as.data.frame(cm[[i]], digits = digits)
		cm2[[i]] <- cm2[[i]][2:3, 1:4]
		cm2[[i]][1,1] <- model_names[i]
		names(cm2[[i]]) <- c('Model', 'Observed', unname(as.data.frame(cm[[i]])[1,3:4]))
		cm2[[i]]$Accuracy <- ''
		cm2[[i]][3,] <- c('', '', '', '',
						  Accuracy = paste0(round(100 * attr(cm[[i]], 'accuracy'), digits = digits), '%') )
	}

	results <- do.call(rbind, cm2)
	results <- rbind(names(results), results)
	names(results) <- c('', '', 'Predicted', '', '')
	return(results)
}
