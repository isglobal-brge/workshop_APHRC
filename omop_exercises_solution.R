################################################################################
# DATASHIELD OMOP PRACTICAL EXERCISES
# Learning to explore and analyze OMOP data with DataSHIELD
################################################################################

# INTRODUCTION:
# This tutorial will guide you through exploring and analyzing OMOP data
# using DataSHIELD. You'll learn how to:
# - Connect to an OMOP database
# - Explore available data
# - Transform OMOP concepts into analyzable variables
# - Perform statistical analyses

# Load required libraries
library(DSI)
library(DSOpal)
library(dsBaseClient)
library(dsOMOPClient)
library(dsOMOPHelper)

# Configure SSL settings (for self-signed certificates)
library(httr)
httr::set_config(httr::config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))

################################################################################
# EXERCISE 1: Server Connection and Initial Data Exploration
################################################################################

cat("\n==================================================\n")
cat("EXERCISE 1: Connect to the server and explore the data structure\n")
cat("==================================================\n\n")

# Task 1.1: Create a connection to the OMOP DataSHIELD server
# Hint: Use newDSLoginBuilder() to create a builder object

# YOUR CODE HERE:
# builder <- ...
# builder$append(...)
# logindata <- ...
# conns <- ...

# SOLUTION:
builder <- newDSLoginBuilder()
builder$append(server="aphrc",
               url="https://44.201.204.234:9090",
               user="administrator",
               password="password",
               driver = "OpalDriver",
               profile = "omop")

logindata <- builder$build()
conns <- datashield.login(logins=logindata)

# Task 1.2: Create a dsOMOPHelper instance
# The resource name is "omop.study_1" and we'll call our symbol "data"

# YOUR CODE HERE:
# o <- ...

# SOLUTION:
o <- ds.omop.helper(
  connections = conns,
  resource = "omop.study_1", 
  symbol = "data"
)

# Task 1.3: Check the initial data summary
# Hint: Use ds.summary() on your data symbol

# YOUR CODE HERE:

# SOLUTION:
cat("Initial data summary:\n")
ds.summary("data")

################################################################################
# EXERCISE 2: Who Are We Studying?
################################################################################

cat("\n\n==================================================\n")
cat("EXERCISE 2: Who Are We Studying?\n")
cat("==================================================\n\n")

# Task 2.1: First Clue - Gender Distribution
# Check the gender distribution
# Question: What do you notice about the gender distribution?

# YOUR CODE HERE:

# SOLUTION:
cat("Task 2.1: Gender distribution\n")
ds.table("data$gender_concept_id")
cat("\nObservation: All participants are female! This is our first clue.\n")

# Task 2.2: Second Clue - Age Distribution
# Calculate age and examine the distribution
# Question: What is the age range?

# YOUR CODE HERE:

# SOLUTION:
cat("\nTask 2.2: Age distribution\n")
ds.assign(
  toAssign = "2025 - data$year_of_birth",
  newobj = "age",
  datasources = conns
)
cat("Age statistics:\n")
ds.mean("age", datasources = conns)
ds.quantileMean("age", datasources = conns)
cat("\nObservation: Women of reproductive age (roughly 30-45)\n")

# Task 2.3: Sample Size
# Check how many participants we have

# YOUR CODE HERE:

# SOLUTION:
cat("\nTask 2.3: Sample size\n")
print(ds.dim("data"))
cat("\nWe have 188 female participants of reproductive age. What might they have in common?\n")

################################################################################
# EXERCISE 3: What Was Measured?
################################################################################

cat("\n\n==================================================\n")
cat("EXERCISE 3: What Was Measured?\n")
cat("==================================================\n\n")

# Task 3.1: Explore Conditions (Diagnoses)
# Start with medical conditions
# Question: What conditions are tracked? What does this reveal?

# YOUR CODE HERE:

# SOLUTION:
cat("Task 3.1: Available conditions:\n")
cond_concepts <- o$concepts("condition_occurrence")
print(cond_concepts)
cat("\nReveal: Depression during and after pregnancy! This is a maternal mental health study.\n")

# Task 3.2: Explore Measurements
# Check what clinical measurements were taken
# Question: What scale is being used?

# YOUR CODE HERE:

# SOLUTION:
cat("\nTask 3.2: Clinical measurements:\n")
meas_concepts <- o$concepts("measurement")
print(meas_concepts)
cat("\nThe Edinburgh Postnatal Depression Scale - a standard tool for screening maternal depression\n")

# Task 3.3: Explore Observations
# Look at other observations (social/demographic factors)
# Question: What social factors were collected? Why might these be relevant?

# YOUR CODE HERE:

# SOLUTION:
cat("\nTask 3.3: Social and demographic factors:\n")
obs_concepts <- o$concepts("observation")
print(obs_concepts)
cat("\nKey factors: Employment, marital status, household size, religion, education\n")
cat("These social determinants can influence mental health outcomes!\n")

################################################################################
# EXERCISE 4: Building Your Analysis Dataset
################################################################################

cat("\n\n==================================================\n")
cat("EXERCISE 4: Building Your Analysis Dataset\n")
cat("==================================================\n\n")

# Task 4.1: Start with the Clinical Outcome
# Retrieve the main clinical measurement

# YOUR CODE HERE:

# SOLUTION:
cat("Task 4.1: Retrieving Edinburgh Postnatal Depression Scale...\n")
o$auto(tables="measurement", 
       concepts=4164838,
       columns="value_as_number")

cat("\nData structure after adding Edinburgh scale:\n")
ds.summary("data")
cat("\n✓ Added: edinburgh_postnatal_depression_scale.value_as_number\n")

# Task 4.2: Add Social Determinants
# Mental health is influenced by social factors

# YOUR CODE HERE:

# SOLUTION:
cat("\nTask 4.2: Retrieving social determinants...\n")

# First, employment status
cat("- Adding employment status...\n")
o$auto(tables="observation",
       concepts=44804285,
       columns="value_as_concept_id")

# Then, other social factors
cat("- Adding marital status, household size, and religious affiliation...\n")
o$auto(tables="observation",
       concepts=c(4053609, 4075500, 4052017),
       columns="value_as_concept_id")

# Let's also get education level if available
cat("- Checking for education level...\n")
o$auto(tables="observation",
       concepts=42528763,
       columns="value_as_concept_id")

cat("\nCurrent variables in our dataset:\n")
current_vars <- ds.colnames("data")[[1]]
print(current_vars)
cat("\n✓ Added social factors: employment, marital_status, number_in_household, religious_affiliation\n")

# Task 4.3: Retrieve the Diagnoses
# Get the depression diagnoses

# YOUR CODE HERE:

# SOLUTION:
cat("\nTask 4.3: Retrieving depression diagnoses...\n")
o$auto(tables="condition_occurrence",
       concepts=c(4239471, 37312479),
       columns="condition_occurrence_id")

# Final check
cat("\nFinal data structure:\n")
ds.summary("data")

cat("\n========== SUMMARY OF RETRIEVED VARIABLES ==========\n")
cat("Clinical Measurement:\n")
cat("  - Edinburgh Postnatal Depression Scale (continuous score)\n")
cat("\nSocial/Demographic Factors:\n")
cat("  - Employment status\n")
cat("  - Marital status\n")
cat("  - Number in household\n")
cat("  - Religious affiliation\n")
cat("  - Education level (if available)\n")
cat("\nClinical Diagnoses:\n")
cat("  - Antenatal depression (during pregnancy)\n")
cat("  - Postpartum depression (after delivery)\n")
cat("\nTotal variables: ", length(ds.colnames("data")[[1]]), "\n")
cat("===================================================\n")

################################################################################
# EXERCISE 5: Understanding the Data Transformation Challenge
################################################################################

cat("\n\n==================================================\n")
cat("EXERCISE 5: The Data Transformation Challenge\n")
cat("==================================================\n\n")

# The depression diagnoses we retrieved are stored as IDs
# Let's examine what we have

# YOUR CODE HERE:

# SOLUTION:
cat("Examining the depression diagnosis columns...\n")
cat("These are stored as condition_occurrence_id values (long ID numbers)\n")
cat("We need to transform these into analyzable boolean (0/1) variables\n\n")

# Let's see what columns we have now
current_cols <- ds.colnames("data")[[1]]
depression_cols <- grep("depression.*condition_occurrence_id", current_cols, value = TRUE)
cat("Depression-related columns:\n")
print(depression_cols)

################################################################################
# EXERCISE 6: Converting OMOP IDs to Boolean Variables
################################################################################

cat("\n\n==================================================\n")
cat("EXERCISE 6: Transform condition IDs to analyzable format\n")
cat("==================================================\n\n")

# Here's a function to convert OMOP IDs to boolean variables
# Study this function carefully!

convert_to_boolean <- function(table, variable_name, id_type, conns) {
  cat(sprintf("Converting %s to boolean...\n", variable_name))
  
  # Step 1: Construct the full variable name
  full_variable_name <- paste0(table, "$", variable_name, ".", id_type)
  
  # Step 2: Convert to numeric (IDs are often stored as strings)
  new_numeric_name <- paste0(variable_name, "_numeric")
  ds.asNumeric(
    x.name = full_variable_name, 
    newobj = new_numeric_name, 
    datasources = conns
  )
  
  # Step 3: Convert to boolean (1 if ID exists, 0 if not)
  ds.Boole(
    V1 = new_numeric_name, 
    V2 = 0, 
    Boolean.operator = "!=", 
    numeric.output = TRUE, 
    na.assign = 0, 
    newobj = variable_name,
    datasources = conns
  )
}

# Task 6.1: Convert antenatal depression to boolean
# Use the function above

# YOUR CODE HERE:

# SOLUTION:
convert_to_boolean("data", "antenatal_depression", "condition_occurrence_id", conns)

# Task 6.2: Convert postpartum depression to boolean

# YOUR CODE HERE:

# SOLUTION:
convert_to_boolean("data", "postpartum_depression", "condition_occurrence_id", conns)

# Task 6.3: Check the distribution of these new variables
# Hint: Use ds.table()

# YOUR CODE HERE:

# SOLUTION:
cat("\nAntenatal depression prevalence:\n")
ds.table("antenatal_depression")
cat("\nPostpartum depression prevalence:\n")
ds.table("postpartum_depression")

################################################################################
# EXERCISE 7: Understanding Depression Patterns
################################################################################

cat("\n\n==================================================\n")
cat("EXERCISE 7: Understanding Depression Patterns\n")
cat("==================================================\n\n")

# Task 7.1: Create a histogram of Edinburgh scores
# First, assign the Edinburgh scores to a simple variable name

# YOUR CODE HERE:

# SOLUTION:
ds.assign(
  toAssign = "data$edinburgh_postnatal_depression_scale.value_as_number",
  newobj = "edinburgh_score",
  datasources = conns
)

cat("Edinburgh score distribution:\n")
ds.histogram("edinburgh_score", datasources = conns)

# Task 7.2: Calculate summary statistics for Edinburgh scores
# Get mean, variance, and quantiles

# YOUR CODE HERE:

# SOLUTION:
cat("\nEdinburgh score statistics:\n")
cat("Mean:", ds.mean("edinburgh_score", datasources = conns)$Global.Mean[1], "\n")
cat("Variance:", ds.var("edinburgh_score", datasources = conns)$Global.Variance[1], "\n")
cat("Quantiles:\n")
print(ds.quantileMean("edinburgh_score", datasources = conns))

# Task 7.3: Create a cross-tabulation of depression types
# Explore the relationship between antenatal and postpartum depression

# YOUR CODE HERE:

# SOLUTION:
cat("\nCross-tabulation of depression types:\n")
# DataSHIELD requires specific syntax for cross-tabulation
ds.table(rvar = "antenatal_depression", cvar = "postpartum_depression", datasources = conns)

################################################################################
# EXERCISE 8: Correlation Analysis
################################################################################

cat("\n\n==================================================\n")
cat("EXERCISE 8: Explore correlations\n")
cat("==================================================\n\n")

# Task 8.1: Create a dataset with numeric variables for correlation
# Include: edinburgh_score, age, and the boolean depression variables

# YOUR CODE HERE:

# SOLUTION:
# First create simplified variable names
ds.assign("data$employment.value_as_concept_id", "employment", conns)
ds.assign("data$number_in_household.value_as_concept_id", "household_size", conns)

# Create a dataset for correlation
variable_list <- c("edinburgh_score", "age", "antenatal_depression", "postpartum_depression")
ds.dataFrame(
  x = variable_list,
  newobj = "cor_data",
  datasources = conns
)

# Task 8.2: Calculate the correlation matrix
# Hint: Use ds.cor()

# YOUR CODE HERE:

# SOLUTION:
cat("Correlation matrix:\n")
cor_matrix <- ds.cor("cor_data", datasources = conns)
print(cor_matrix)

################################################################################
# EXERCISE 9: Building Statistical Models
################################################################################

cat("\n\n==================================================\n")
cat("EXERCISE 9: Create and interpret GLM models\n")
cat("==================================================\n\n")

# First, let's create a comprehensive dataset for modeling

# Prepare all variables
ds.assign("data$marital_status.value_as_concept_id", "marital_status", conns)
ds.assign("data$religious_affiliation.value_as_concept_id", "religion", conns)

# Create modeling dataset
model_vars <- c(
  "edinburgh_score",
  "age",
  "employment",
  "marital_status",
  "household_size",
  "religion",
  "antenatal_depression",
  "postpartum_depression"
)

ds.cbind(
  x = model_vars,
  DataSHIELD.checks = FALSE,
  newobj = "model_data",
  datasources = conns
)

# Task 9.1: Build a linear model predicting Edinburgh scores
# Use age and employment as predictors

# YOUR CODE HERE:

# SOLUTION:
cat("Model 1: Simple linear regression\n")
cat("Research question: Do age and employment affect depression severity?\n\n")

model1 <- ds.glm(
  formula = "edinburgh_score ~ age + employment",
  data = "model_data",
  family = "gaussian",
  datasources = conns
)

# NOTE: we use gaussian for the linear regression because edinburgh_score 
# is a continuous variable

cat("Model 1 Results:\n")
print(model1$coefficients[, c("Estimate", "Std. Error", "p-value")])

# Task 9.2: Build a logistic regression for postpartum depression
# Use antenatal_depression and edinburgh_score as predictors

# YOUR CODE HERE:

# SOLUTION:
cat("\n\nModel 2: Logistic regression\n")
cat("Research question: What predicts postpartum depression?\n\n")

model2 <- ds.glm(
  formula = "postpartum_depression ~ antenatal_depression + edinburgh_score + age",
  data = "model_data",
  family = "binomial",
  datasources = conns
)

# NOTE: we use binomial for the logistic regression because postpartum_depression 
# is a binary variable

cat("Model 2 Results (with Odds Ratios):\n")
coef2 <- as.data.frame(model2$coefficients)
print(coef2[, c("Estimate", "P_OR", "low0.95CI.P_OR", "high0.95CI.P_OR", "p-value")])

# Task 9.3: Build a comprehensive model
# Include multiple social factors

# YOUR CODE HERE:

# SOLUTION:
cat("\n\nModel 3: Comprehensive model\n")
cat("Research question: How do social factors influence depression severity?\n\n")

model3 <- ds.glm(
  formula = "edinburgh_score ~ age + employment + marital_status + household_size + antenatal_depression + postpartum_depression",
  data = "model_data",
  family = "gaussian",
  datasources = conns
)

cat("Model 3 Results:\n")
coef3 <- as.data.frame(model3$coefficients)
print(coef3[, c("Estimate", "Std. Error", "p-value")])

################################################################################
# CHALLENGE: Create Your Own Research Question
################################################################################

cat("\n\n==================================================\n")
cat("CHALLENGE: Create Your Own Research Question\n")
cat("==================================================\n\n")

# This is just an example of how you can create your own research question

# YOUR CODE HERE:

# SOLUTION:
cat("Research question: Does employment modify the effect of antenatal depression?\n\n")

model4 <- ds.glm(
  formula = "edinburgh_score ~ antenatal_depression * employment + age",
  data = "model_data",
  family = "gaussian",
  datasources = conns
)

# Look for interaction terms
coef4 <- as.data.frame(model4$coefficients)
interaction_terms <- grep(":", rownames(coef4), value = TRUE)
if(length(interaction_terms) > 0) {
  coef4[interaction_terms, c("Estimate", "Std. Error", "p-value")]
}

################################################################################
# LOG OUT
################################################################################

# Very important!!!
datashield.logout(conns)
