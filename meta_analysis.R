library(DSOpal)
library(dsBaseClient)

# prepare login data and resources to assign
builder <- DSI::newDSLoginBuilder()

builder$append(server = "study1", url = "https://opal-demo.obiba.org", 
               user = "dsuser", password = "P@ssw0rd", 
               table = "CNSIM.CNSIM1", profile = "default")

builder$append(server = "study2", url = "https://opal-demo.obiba.org", 
               user = "dsuser", password = "P@ssw0rd", 
               table = "CNSIM.CNSIM2", profile = "default")

builder$append(server = "study3", url = "https://opal-demo.obiba.org", 
               user = "dsuser", password = "P@ssw0rd", 
               table = "CNSIM.CNSIM3", profile = "default")



logindata <- builder$build()

# login and get tables
conns <- datashield.login(logins = logindata, assign = TRUE, symbol = "D")

ds.ls()

ds.colnames("D")


mod <- ds.glm("D$DIS_DIAB ~ D$LAB_HDL + D$LAB_TRIG", 
              family = "binomial")
mod$coef


mod2<-ds.glmSLMA(formula="D$DIS_DIAB ~ D$LAB_HDL + D$LAB_TRIG", 
                 family='binomial')

mod2$output.summary

estimates <- c(mod2$betamatrix.valid[2,])
se <- c(mod2$sematrix.valid[2,])

res <- rma(estimates, sei=se)
forest(res)
