# https://archive.ics.uci.edu/dataset/222/bank+marketing
bank <- read.csv('data-raw/bank/bank.csv', sep = ';') |>
	dplyr::rename(subscribed = y) |>
	dplyr::mutate(subscribed = subscribed == 'yes')

table(bank$subscribed) |> prop.table()

usethis::use_data(bank, overwrite = TRUE)

bank_split <- splitstackshape::stratified(
	bank, group = "subscribed", size = 0.75, bothSets = TRUE)
bank_train <- bank_split[[1]]
bank_valid <- bank_split[[2]]
bank_lr_out <- glm(subscribed ~ ., data = bank_train, family = binomial(link = 'logit'))
bank_lr_fitted <- predict(bank_lr_out, newdata = bank_valid, type = 'response')

library(ggplot2)
ggplot(data.frame(fitted = bank_lr_fitted, subscribed = bank_valid$subscribed),
	   aes(x = fitted, color = subscribed)) +
	geom_density()

medley::calculate_roc(predictions = bank_lr_fitted, observed = bank_valid$subscribed) |> plot()
medley::confusion_matrix(bank_valid$subscribed, bank_lr_fitted > 0.5)

bank_ds_out <- medley::downsample(subscribed ~ ., data = bank_train,
								  model_fun = glm, family = binomial(link = 'logit'))
bank_ds_fitted <- predict(bank_ds_out, newdata = bank_valid, type = 'response')
bank_ds_fitted2 <- bank_ds_fitted |> apply(1, mean)

ggplot(data.frame(fitted = bank_ds_fitted2, subscribed = bank_valid$subscribed),
	   aes(x = fitted, color = subscribed)) +
	geom_density()

medley::calculate_roc(predictions = bank_ds_fitted2, observed = bank_valid$subscribed) |> plot()
medley::confusion_matrix(bank_valid$subscribed, bank_ds_fitted2 > 0.5)

medley::calculate_roc(predictions = bank_ds_fitted[,1], observed = bank_valid$subscribed) |> plot()
medley::confusion_matrix(bank_valid$subscribed, bank_ds_fitted[,1] > 0.5)

apply(bank_ds_fitted, 2, FUN = function(x) {
	accuracy(bank_valid$subscribed, x > 0.5)
}) #|> mean()
