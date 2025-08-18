# Load libraries
library(DSI)
library(DSOpal)
library(dsBaseClient)

# login to the servers 
builder <- DSI::newDSLoginBuilder()


builder$append(
  server = 'Server_1', 
  url = "https://opal-demo.obiba.org",
  user = "administrator", 
  password = "password", 
  table = "GWAS.ega_phenotypes_1",
  profile = "default"
)

builder$append(
  server = 'Server_2', 
  url = "https://opal.isglobal.org/repo",
  user = "invited", 
  password = "12345678Aa@",
  table = "EGA.ega_phenotypes_2",
  profile = "rock-inma"
)



# connect to the servers
logindata <- builder$build()
conns <- datashield.login(logins = logindata, assign = TRUE, symbol = "ega")

# check data is loaded into the R servers
ds.ls()
ds.colnames("ega")

# question 1
ds.class("ega")

# question 2
ds.table("ega$diabetes_diagnosed_doctor")

# question 3
ds.table("ega$diabetes_diagnosed_doctor", "ega$sex")

# question 4
ds.histogram("ega$height")

# question 5
ds.scatterPlot("ega$weight", "ega$bmi")

# question 6
ds.cor("ega$weight", "ega$bmi")
ds.corTest("ega$weight", "ega$bmi")

# question 7
ds.glm("ega$cholesterol ~ ega$weight", family = "gaussian")

# question 8
ds.glm("ega$diabetes_diagnosed_doctor ~ ega$cholesterol",
       family = "binomial")

# question 9
ds.glm("ega$diabetes_diagnosed_doctor ~ ega$cholesterol + ega$bmi",
       family = "binomial")

# question 10
ds.glm("ega$diabetes_diagnosed_doctor ~ ega$cholesterol*ega$sex + ega$bmi",
       family = "binomial")
