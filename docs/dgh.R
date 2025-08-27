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

ds.summary("data")