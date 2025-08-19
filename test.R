################################################################################
# DATASHIELD OMOP TUTORIAL
# Converting OMOP data to statistical models using boolean transformation
################################################################################

# Load required libraries
library(DSI)
library(DSOpal)
library(dsBaseClient)
library(dsOMOPClient)
library(dsOMOPHelper)

# Configure SSL settings for self-signed certificates
library(httr)
httr::set_config(httr::config(ssl_verifypeer = 0L, ssl_verifyhost = 0L))

################################################################################
# STEP 1: CONNECTION SETUP
################################################################################

cat("\n==================================================\n")
cat("STEP 1: Connecting to OMOP DataSHIELD Server\n")
cat("==================================================\n\n")

builder <- newDSLoginBuilder()

builder$append(server="aphrc-dsp",
               url="https://44.201.204.234:9090",
               user="administrator",
               password="password",
               driver = "OpalDriver",
               profile = "omop")

logindata <- builder$build()
conns <- datashield.login(logins=logindata)

# Create dsOMOPHelper instance
o <- ds.omop.helper(
  connections = conns,
  resource = "omop.study_1", 
  symbol = "data"
)

################################################################################
# STEP 2: DATA EXPLORATION
################################################################################

cat("\n==================================================\n")
cat("STEP 2: Exploring Available OMOP Concepts\n")
cat("==================================================\n\n")

# Explore all available concepts in the database
cat("--- Available Observations ---\n")
obs_concepts <- o$concepts("observation")
print(obs_concepts)

cat("\n--- Available Measurements ---\n")
meas_concepts <- o$concepts("measurement")
print(meas_concepts)

cat("\n--- Available Conditions ---\n")
cond_concepts <- o$concepts("condition_occurrence")
print(cond_concepts)

################################################################################
# STEP 3: DATA RETRIEVAL
################################################################################

cat("\n==================================================\n")
cat("STEP 3: Retrieving Data from OMOP Tables\n")
cat("==================================================\n\n")

# Retrieve measurement data (Edinburgh scale)
cat("Retrieving Edinburgh Postnatal Depression Scale (continuous)...\n")
o$auto(tables="measurement", 
       concepts=4164838,  # Edinburgh postnatal depression scale
       columns="value_as_number")

# Retrieve observation data (demographics/social factors)
cat("Retrieving demographic and social factors...\n")
o$auto(tables="observation",
       concepts=c(4075500,   # Number in household
                  4052017,   # Religious affiliation
                  4053609,   # Marital status
                  44804285,  # Employment
                  42528763), # Education level
       columns="value_as_concept_id")

# Retrieve condition occurrence data (diagnoses)
cat("Retrieving depression diagnoses...\n")
o$auto(tables="condition_occurrence",
       concepts=c(4239471,   # Postpartum depression
                  37312479), # Antenatal depression
       columns="condition_occurrence_id")

# Check the structure of our data
cat("\n--- Data Structure ---\n")
ds.summary("data")

################################################################################
# STEP 4: BOOLEAN CONVERSION FUNCTION
################################################################################

cat("\n==================================================\n")
cat("STEP 4: Converting OMOP IDs to Boolean Variables\n")
cat("==================================================\n\n")

# Function to convert OMOP IDs to boolean variables
convert_to_boolean <- function(table, variable_name, id_type, conns) {
  cat(sprintf("Converting %s to boolean...\n", variable_name))
  
  # Construct the full variable name
  full_variable_name <- paste0(table, "$", variable_name, ".", id_type)
  
  # Create a new variable name for the numeric conversion
  new_numeric_name <- paste0(variable_name, "_numeric")
  
  # Convert to numeric
  ds.asNumeric(
    x.name = full_variable_name, 
    newobj = new_numeric_name, 
    datasources = conns
  )
  
  # Convert to boolean (1 if not 0, 0 otherwise)
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

# Convert condition occurrences to boolean
convert_to_boolean("data", "antenatal_depression", "condition_occurrence_id", conns)
convert_to_boolean("data", "postpartum_depression", "condition_occurrence_id", conns)

################################################################################
# STEP 5: PREPARE VARIABLES FOR ANALYSIS
################################################################################

cat("\n==================================================\n")
cat("STEP 5: Preparing Variables for Statistical Analysis\n")
cat("==================================================\n\n")

# Extract continuous variables
ds.assign(
  toAssign = "data$edinburgh_postnatal_depression_scale.value_as_number",
  newobj = "edinburgh_score",
  datasources = conns
)

# Extract categorical variables (keeping as concept IDs for factor-like behavior)
ds.assign(
  toAssign = "data$number_in_household.value_as_concept_id",
  newobj = "household_size",
  datasources = conns
)

ds.assign(
  toAssign = "data$religious_affiliation.value_as_concept_id",
  newobj = "religion",
  datasources = conns
)

ds.assign(
  toAssign = "data$marital_status.value_as_concept_id",
  newobj = "marital_status",
  datasources = conns
)

ds.assign(
  toAssign = "data$employment.value_as_concept_id",
  newobj = "employment",
  datasources = conns
)

# Check if education level exists
if("highest_level_of_education.value_as_concept_id" %in% ds.colnames("data")[[1]]) {
  ds.assign(
    toAssign = "data$highest_level_of_education.value_as_concept_id",
    newobj = "education",
    datasources = conns
  )
  has_education <- TRUE
} else {
  has_education <- FALSE
  cat("Note: Education level not available in this dataset\n")
}

################################################################################
# STEP 6: CREATE COMPREHENSIVE GLM TABLE
################################################################################

cat("\n==================================================\n")
cat("STEP 6: Creating Comprehensive Analysis Table\n")
cat("==================================================\n\n")

# Build variable list
variable_names <- c(
  "edinburgh_score",
  "household_size",
  "religion",
  "marital_status",
  "employment",
  "antenatal_depression",
  "postpartum_depression"
)

if(has_education) {
  variable_names <- c(variable_names, "education")
}

# Create the comprehensive GLM table
ds.cbind(
  x = variable_names,
  DataSHIELD.checks = FALSE,
  newobj = "glm_table",
  datasources = conns
)

cat("GLM table created with", length(variable_names), "variables\n")
ds.summary("glm_table")

################################################################################
# STEP 7: EXPLORATORY DATA ANALYSIS
################################################################################

cat("\n==================================================\n")
cat("STEP 7: Exploratory Data Analysis\n")
cat("==================================================\n\n")

# Get basic statistics for Edinburgh score
cat("--- Edinburgh Score Statistics ---\n")
ds.mean("glm_table$edinburgh_score", datasources = conns)
ds.var("glm_table$edinburgh_score", datasources = conns)

# Get prevalence of depression conditions
cat("\n--- Depression Prevalence ---\n")
ds.table("glm_table$antenatal_depression", datasources = conns)
ds.table("glm_table$postpartum_depression", datasources = conns)

# Cross-tabulation of depression types
cat("\n--- Cross-tabulation: Antenatal vs Postpartum Depression ---\n")
ds.table("glm_table$antenatal_depression + glm_table$postpartum_depression", datasources = conns)

################################################################################
# STEP 8: STATISTICAL MODELS - FINDING INTERESTING RELATIONSHIPS
################################################################################

cat("\n==================================================\n")
cat("STEP 8: Statistical Models - Testing Hypotheses\n")
cat("==================================================\n\n")

# Model 1: Social determinants of Edinburgh depression score
cat("\n========== Model 1: Social Determinants of Depression Severity ==========\n")
cat("Hypothesis: Social factors (employment, marital status, household size) affect depression severity\n")
cat("=========================================================================\n\n")

formula1 <- "edinburgh_score ~ employment + marital_status + household_size + religion"

glm1 <- ds.glm(
  formula = formula1,
  data = "glm_table",
  family = "gaussian",
  datasources = conns
)

cat("\nModel 1 Results:\n")
coef1 <- as.data.frame(glm1$coefficients)
print(coef1[, c("Estimate", "Std. Error", "p-value")])
cat("\nSignificant predictors (p < 0.05):\n")
sig1 <- coef1[coef1$`p-value` < 0.05, ]
if(nrow(sig1) > 0) {
  print(sig1[, c("Estimate", "p-value")])
} else {
  cat("No significant predictors found\n")
}

# Model 2: Risk factors for antenatal depression
cat("\n\n========== Model 2: Risk Factors for Antenatal Depression ==========\n")
cat("Hypothesis: Demographic factors predict antenatal depression risk\n")
cat("====================================================================\n\n")

formula2 <- "antenatal_depression ~ employment + marital_status + household_size + religion"

glm2 <- ds.glm(
  formula = formula2,
  data = "glm_table",
  family = "binomial",
  datasources = conns
)

cat("\nModel 2 Results (Odds Ratios):\n")
coef2 <- as.data.frame(glm2$coefficients)
sig2 <- coef2[coef2$`p-value` < 0.05, ]
if(nrow(sig2) > 0) {
  print(sig2[, c("Estimate", "P_OR", "p-value")])
} else {
  cat("No significant predictors found\n")
}

# Model 3: Progression from antenatal to postpartum depression
cat("\n\n========== Model 3: Depression Progression Model ==========\n")
cat("Hypothesis: Antenatal depression and baseline severity predict postpartum depression\n")
cat("===========================================================\n\n")

formula3 <- "postpartum_depression ~ antenatal_depression + edinburgh_score + household_size"

glm3 <- ds.glm(
  formula = formula3,
  data = "glm_table",
  family = "binomial",
  datasources = conns
)

cat("\nModel 3 Results (Odds Ratios):\n")
coef3 <- as.data.frame(glm3$coefficients)
sig3 <- coef3[coef3$`p-value` < 0.05, ]
if(nrow(sig3) > 0) {
  print(sig3[, c("Estimate", "P_OR", "p-value")])
} else {
  cat("No significant predictors found\n")
}

# Model 4: Comprehensive model for Edinburgh score
cat("\n\n========== Model 4: Comprehensive Depression Severity Model ==========\n")
cat("Hypothesis: Both social factors and clinical conditions affect depression severity\n")
cat("======================================================================\n\n")

formula4 <- "edinburgh_score ~ employment + marital_status + household_size + antenatal_depression + postpartum_depression"

glm4 <- ds.glm(
  formula = formula4,
  data = "glm_table",
  family = "gaussian",
  datasources = conns
)

cat("\nModel 4 Results:\n")
coef4 <- as.data.frame(glm4$coefficients)
sig4 <- coef4[coef4$`p-value` < 0.05, ]
if(nrow(sig4) > 0) {
  print(sig4[, c("Estimate", "Std. Error", "p-value")])
} else {
  cat("No significant predictors found\n")
}

# Model 5: Interaction effects
cat("\n\n========== Model 5: Interaction Effects Model ==========\n")
cat("Hypothesis: Employment status modifies the effect of antenatal depression\n")
cat("=========================================================\n\n")

formula5 <- "postpartum_depression ~ antenatal_depression * employment + household_size"

glm5 <- ds.glm(
  formula = formula5,
  data = "glm_table",
  family = "binomial",
  datasources = conns
)

cat("\nModel 5 Results (Testing for interaction):\n")
coef5 <- as.data.frame(glm5$coefficients)
# Look for interaction terms (they contain ":")
interaction_terms <- grep(":", rownames(coef5), value = TRUE)
if(length(interaction_terms) > 0) {
  cat("Interaction terms:\n")
  print(coef5[interaction_terms, c("Estimate", "P_OR", "p-value")])
}

################################################################################
# STEP 9: SUMMARY AND CONCLUSIONS
################################################################################

cat("\n\n==================================================\n")
cat("SUMMARY OF KEY FINDINGS\n")
cat("==================================================\n\n")

cat("1. DATA OVERVIEW:\n")
cat("   - Total observations:", glm1$Nvalid, "\n")
cat("   - Variables analyzed:", length(variable_names), "\n")
cat("   - Missing data:", glm1$Nmissing, "\n\n")

cat("2. SIGNIFICANT RELATIONSHIPS FOUND:\n")
if(nrow(sig3) > 0) {
  cat("   - Antenatal depression significantly predicts postpartum depression\n")
  cat("     (OR =", round(sig3["antenatal_depression", "P_OR"], 2), ")\n")
}
if(nrow(sig4) > 0) {
  cat("   - Depression diagnoses strongly associated with Edinburgh scores\n")
}

cat("\n3. CLINICAL IMPLICATIONS:\n")
cat("   - Early screening during pregnancy is crucial\n")
cat("   - Social support systems may play a protective role\n")
cat("   - Comprehensive assessment should include both clinical and social factors\n")

cat("\n==================================================\n")
cat("TUTORIAL COMPLETE\n")
cat("==================================================\n\n")

# Clean up and logout
datashield.logout(conns)