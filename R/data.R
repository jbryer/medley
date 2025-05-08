#' Data from the Diagnostic Assessment and Achievement of College Skills (DAACS)
#'
#' This is data part of a larger randomized control trial designed to test
#' the effect of DAACS on student success. These data are from the treatment
#' group at a large online college. DAACS was embedded within orientation.
#' Although students were expected to complete orientation there were no
#' consequences for not doing so. As a result some or all DAACS data are missing
#' for a large proportion of the students.
#'
#' For more information about DAACS, see https://daacs.net.
#'
#' @format
#' A data frame with 5,154 observations of 14 variables.
#' \describe{
#'     \item{retained}{whether the student was retained for a second semester}
#'     \item{srl}{the student's self-regulated learning score}
#'     \item{math}{the student's mathematics score}
#'     \item{reading}{the student's reading score}
#'     \item{writing}{the student's writing score}
#'     \item{income}{the student's income level as an ordered factor}
#'     \item{employment}{the student's employment status}
#'     \item{ell}{whether the student is an English Language Learner}
#'     \item{ed_mother}{the highest education level of the student's mother}
#'     \item{ed_father}{the highest education level of the student's father}
#'     \item{ethnicity}{the ethnicity of the student}
#'     \item{gender}{the gender of the student}
#'     \item{military}{whether the student is active in the military}
#'     \item{age}{the age of the student at the time of enrollment}
#'     \item{page_views}{the number of feedback pages the student viewed}
#' }
#' @docType data
#' @source https://daacs.net
#' @name daacs
NULL

#' Programme of International Student Assessment
#'
#' This data is from the 2019 PISA implementation for the United States. It is used to predict
#' whether a student attends a public or private school. The dependent variable (`Public`) is
#' is imbalanced with approximately 93% of students attending public schools.
#'
#' This dataset was modified from the original data provided by OECD.
#' The [`pisa`](https://github.com/jbryer/pisa) R package on Github provides the complete data
#' for the 2019 administration.
#'
#' @format
#' A data frame with 5,233 observations of 45 variables.
#' \describe{
#'     \item{Public}{Whether student attends a public or private school.}
#'     \item{ST04Q01}{Sex}
#'     \item{ST05Q01}{Attend <ISCED 0>}
#'     \item{ST06Q01}{Age at <ISCED 1>}
#'     \item{ST07Q01}{Repeat <ISCED 1>}
#'     \item{ST08Q01}{At Home - Mother}
#'     \item{ST08Q02}{At Home - Father}
#'     \item{ST08Q03}{At Home - Brothers}
#'     \item{ST08Q04}{At Home - Sisters}
#'     \item{ST08Q05}{At Home - Grandparents}
#'     \item{ST08Q06}{At Home - Others}
#'     \item{ST10Q01}{Mother  <Highest Schooling>}
#'     \item{ST12Q01}{Mother Current Job Status}
#'     \item{ST14Q01}{Father  <Highest Schooling>}
#'     \item{ST16Q01}{Father Current Job Status}
#'     \item{ST19Q01}{Language at home}
#'     \item{ST20Q01}{Possessions desk}
#'     \item{ST20Q02}{Possessions own room}
#'     \item{ST20Q03}{Possessions study place}
#'     \item{ST20Q04}{Possessions  computer}
#'     \item{ST20Q05}{Possessions software}
#'     \item{ST20Q06}{Possessions Internet}
#'     \item{ST20Q07}{Possessions literature}
#'     \item{ST20Q08}{Possessions poetry}
#'     \item{ST20Q09}{Possessions art}
#'     \item{ST20Q10}{Possessions textbooks}
#'     \item{ST20Q12}{Possessions dictionary}
#'     \item{ST20Q13}{Possessions dishwasher}
#'     \item{ST21Q01}{How many cellular phones}
#'     \item{ST21Q02}{How many televisions}
#'     \item{ST21Q03}{How many computers}
#'     \item{ST21Q04}{How many cars}
#'     \item{ST21Q05}{How many rooms bath or shower}
#'     \item{ST22Q01}{How many books at home}
#'     \item{ST23Q01}{Reading Enjoyment Time}
#'     \item{ST31Q01}{<Enrich> in <test lang>}
#'     \item{ST31Q02}{<Enrich> in <mathematics>}
#'     \item{ST31Q03}{<Enrich> in <science>}
#'     \item{ST31Q05}{<Remedial> in <test lang>}
#'     \item{ST31Q06}{<Remedial> in <mathematics>}
#'     \item{ST31Q07}{<Remedial> in <science>}
#'     \item{ST32Q01}{Out of school lessons <test lang>}
#'     \item{ST32Q02}{Out of school lessons <maths>}
#'     \item{ST32Q03}{Out of school lessons <science>}
#' }
#' @docType data
#' @source https://www.pisa.oecd.org
#' @name pisa
NULL

#' Programme of International Student Assessment
#'
#' This is a character vector where the names of the variables correspond to the variables names
#' in the `pisa` data frame and the values are descriptions of the variables.
#'
#' @format a character vector.
#' @docType data
#' @source https://www.pisa.oecd.org
#' @name pisa_variables
NULL

#' Bank Marketing
#'
#' The data is related with direct marketing campaigns (phone calls) of a Portuguese banking
#' institution. The classification goal is to predict if the client will subscribe a term deposit
#' (variable `subscribed`).
#'
#' @format a data frame with 4,521 observations of 17 variables.
#' \description{
#'     \item{age (numeric)}
#'     \item{job}{type of job}
#'     \item{marital}{marital status (categorical: "married","divorced","single"; note: "divorced" means divorced or widowed)}
#'     \item{education (categorical: "unknown","secondary","primary","tertiary")}
#'     \item{default}{has credit in default? (binary: "yes","no")}
#'     \item{balance}{average yearly balance, in euros (numeric)}
#'     \item{housing}{has housing loan? (binary: "yes","no")}
#'     \item{loan}{has personal loan? (binary: "yes","no")}
#'     \item{contact}{contact communication type (categorical: "unknown","telephone","cellular")}
#'     \item{day}{last contact day of the month (numeric)}
#'     \item{month}{last contact month of year (categorical: "jan", "feb", "mar", ..., "nov", "dec")}
#'     \item{duration}{last contact duration, in seconds (numeric)}
#'     \item{campaign}{number of contacts performed during this campaign and for this client (numeric, includes last contact)}
#'     \item{pdays}{number of days that passed by after the client was last contacted from a previous campaign (numeric, -1 means client was not previously contacted)}
#'     \item{previous}{number of contacts performed before this campaign and for this client (numeric)}
#'     \item{poutcome}{outcome of the previous marketing campaign (categorical: "unknown","other","failure","success")}
#'     \item{subscribed}{has the client subscribed a term deposit? (binary: "yes","no")}
#' }
#' @docType data
#' @source https://archive.ics.uci.edu/dataset/222/bank+marketing
#' @name bank
NULL
