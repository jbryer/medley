#' Calculate a confusion matrix
#'
#' @param observed vector of observed values. The vector should either be a numeric vector of 0s
#'        and 1s or logical.
#' @param predicted vector of predicted values. The vector should either be a numeric vector of 0s
#'        and 1s or logical.
#' @param label_true label for TRUE values.
#' @param label_false label for FALSE values
#' @return a data.frame of the confusion matrix.
#' @export
#' @examples
#' observed <- c(rep(FALSE, 10), rep(TRUE, 2))
#' predicted <- rep(TRUE, 12)
#' confusion_matrix(observed, predicted, label_true = 'Success', label_false = 'Failure')
confusion_matrix <- function(observed, predicted, label_false = 'FALSE', label_true = 'TRUE') {
	if(length(unique(predicted)) > 2) {
		warning('Looks like predicted probabilities were provided. Dichotomizing at 0.5.')
		predicted <- predicted > 0.5
	}
	if(!is.logical(observed)) {
		observed <- as.logical(observed)
		if(all(is.na(observed))) {
			stop('observed vector could not be converted to a logical vector.')
		}
	}
	if(!is.logical(predicted)) {
		predicted <- as.logical(predicted)
		if(all(is.na(predicted))) {
			stop('predicted vector could not be converted to a logical vector.')
		}
	}
	observed <- factor(observed, levels = c(FALSE, TRUE), labels = c(label_false, label_true))
	predicted <- factor(predicted, levels = c(FALSE, TRUE), labels = c(label_false, label_true))
	ct <- table(predicted, observed)
	pt <- prop.table(ct)
	result <- cbind(as.data.frame(ct), percent = as.data.frame(pt)[,3])
	attr(result, 'accuracy') <- pt[1,1] + pt[2,2]
	attr(result, 'specificity') <- result[result$predicted == 'TRUE' & result$observed == 'TRUE',]$Freq / sum(result[result$observed == 'TRUE',]$Freq)
	attr(result, 'sensitivity') <- result[result$predicted == 'FALSE' & result$observed == 'FALSE',]$Freq / sum(result[result$observed == 'FALSE',]$Freq)
	# attr(result, 'kappa') <- base::kappa(ct)[[1]]
	class(result) <- c('confusionmatrix', 'data.frame')
	return(result)
}

#' @rdname confusion_matrix
#' @param x the result of [confusion_matrix()].
#' @param digits number of decimal places to print.
#' @param row.names not used.
#' @param optional not used.
#' @param ... currently not used.
#' @method as.data.frame confusionmatrix
#' @export
as.data.frame.confusionmatrix <- function(x, row.names = NULL, optional = FALSE, digits = 2, ...) {
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
	cat(paste0('Accuracy: ', round(100 * attr(x, 'accuracy'), digits = digits), '%\n'))
	cat(paste0('Sensitivity: ', round(100 * attr(x, 'sensitivity'), digits = digits), '%\n'))
	cat(paste0('Specificity: ', round(100 * attr(x, 'specificity'), digits = digits), '%\n'))
	# k <- attr(x, 'kappa')
	# if(is.list(k)) {
	# 	cat(paste0('Kappa: ', round(k[[1]], digits = digits), '\n'))
	# } else {
	# 	cat(paste0('Kappa: ', round(k, digits = digits), '\n'))
	# }
}

#' Calculate the accuracy rate.
#'
#' This function provides the overall accuracy rate for the two vectors. This is the sum of the
#' true positive and true negative values.
#'
#' @rdname metrics
#' @param observed vector of observed values.
#' @param predicted vector of predicted values.
#' @return the accuracy as a numeric value.
#' @export
accuracy <- function(observed, predicted) {
	tab_out <- confusion_matrix(observed, predicted)
	class(tab_out) <- 'data.frame'
	sum(tab_out[tab_out$observed == tab_out$predicted,]$percent)
}

#' Calculate the sensitivity.
#'
#' sum(True positive) / sum(Condition positive)
#'
#' @rdname metrics
#' @param observed vector of observed values.
#' @param predicted vector of predicted values.
#' @export
sensitivity <- function(observed, predicted) {
	tab_out <- confusion_matrix(observed, predicted)
	class(tab_out) <- 'data.frame'
	tab_out[tab_out$predicted == 'FALSE' & tab_out$observed == 'FALSE',]$Freq / sum(tab_out[tab_out$observed == 'FALSE',]$Freq)
}

#' Calculate the specificity.
#'
#' sum(True negative) / sum(Condition negative)
#'
#' @rdname metrics
#' @param observed vector of observed values.
#' @param predicted vector of predicted values.
#' @export
specificity <- function(observed, predicted) {
	tab_out <- confusion_matrix(observed, predicted)
	class(tab_out) <- 'data.frame'
	tab_out[tab_out$predicted == 'TRUE' & tab_out$observed == 'TRUE',]$Freq / sum(tab_out[tab_out$observed == 'TRUE',]$Freq)
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
