# Bank Marketing

The data is related with direct marketing campaigns (phone calls) of a
Portuguese banking institution. The classification goal is to predict if
the client will subscribe a term deposit (variable \`subscribed\`).

## Format

a data frame with 4,521 observations of 17 variables.

- age (numeric):

  age

- job:

  type of job

- marital:

  marital status (categorical: "married","divorced","single"; note:
  "divorced" means divorced or widowed)

- education:

  educational level (categorical:
  "unknown","secondary","primary","tertiary")

- default:

  has credit in default? (binary: "yes","no")

- balance:

  average yearly balance, in euros (numeric)

- housing:

  has housing loan? (binary: "yes","no")

- loan:

  has personal loan? (binary: "yes","no")

- contact:

  contact communication type (categorical:
  "unknown","telephone","cellular")

- day:

  last contact day of the month (numeric)

- month:

  last contact month of year (categorical: "jan", "feb", "mar", ...,
  "nov", "dec")

- duration:

  last contact duration, in seconds (numeric)

- campaign:

  number of contacts performed during this campaign and for this client
  (numeric, includes last contact)

- pdays:

  number of days that passed by after the client was last contacted from
  a previous campaign (numeric, -1 means client was not previously
  contacted)

- previous:

  number of contacts performed before this campaign and for this client
  (numeric)

- poutcome:

  outcome of the previous marketing campaign (categorical:
  "unknown","other","failure","success")

- subscribed:

  has the client subscribed a term deposit? (binary: "yes","no")

## Source

https://archive.ics.uci.edu/dataset/222/bank+marketing
