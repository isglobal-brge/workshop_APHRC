library(DSI)
library(DSOpal)
library(dsBaseClient)
library(dsOMOPClient)
library(dsOMOPHelper)

library(httr)
httr::set_config(httr::config(ssl_verifypeer = 0L, 
                              ssl_verifyhost = 0L))

builder <- newDSLoginBuilder()
builder$append(server="dgh",
               url="https://192.168.1.130:443",
               user="administrator",
               password="password",
               driver = "OpalDriver",
               profile = "omop")

logindata <- builder$build()
conns <- datashield.login(logins=logindata)

o <- ds.omop.helper(
  connections = conns,
  resource = "omop.respiratory", 
  symbol = "data"
)

# Check the current state of your dataset
ds.summary("data")

# Explore the database
o$tables()
o$columns("measurement")
o$concepts("measurement")

# Usually: 
# - value_as_number for numerical values, 
# - value_as_concept_id for categorical values,
# - get the xxx_id then transform to boolean for presence of a certain variable registry 
#   for a person (below is the function to do that)

# Function to transform presence of variable to boolean
convert_to_boolean <- function(table, variable_name, id_type, conns) {
  cat(sprintf("Converting %s to boolean...\n", variable_name))
  
  # Step 1: Construct the full variable name
  full_variable_name <- paste0(table, "$", variable_name, ".", id_type)
  
  # Step 2: Convert to numeric (IDs are often strings)
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