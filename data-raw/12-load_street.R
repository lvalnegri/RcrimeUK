###############################################################
# 12- LOAD "STREET" FILES
###############################################################

## 1- load packages -------------------------------------------------------------------------------------------------------------
pkg <- c('data.table', 'RMySQL')
invisible(lapply(pkg, require,  char = TRUE))

## 2- Define variables ----------------------------------------------------------------------------------------------------------
cur_month <- '2011-12'
data_path <- 
    if (substr(Sys.info()['sysname'], 1, 1) == 'W') {
        'D:/cloud/OneDrive/data/UK/crime_incidents/'
    } else {
        '/home/datamaps/data/UK/crime_incidents/'
    }
data_path <- paste0(data_path, cur_month, '/')
fnames <- list.files(data_path, pattern = '-street', full.names = TRUE)
cnames <- c('crime_id', 'datefield', 'force', 'x_lon', 'y_lat', 'location', 'LSOA', 'type', 'outcome')
cpos <- c(1:2, 4:8, 10:11)

## 3- Define functions ----------------------------------------------------------------------------------------------------------
inv_substr <- function(x, n) substr(x, nchar(x)-n+1, nchar(x))

## 4- Read and clean data, build unique dataset ---------------------------------------------------------------------------------
dt <- fread(fnames[1], select = cpos, col.names = cnames)
for(fn in fnames[2:length(fnames)]){
    print(paste('Processing ', fn))
    t <- fread(fn, select = cpos, col.names = cnames)
    dt <- rbindlist(list(dt, t))
}
dt[, `:=`(datefield = gsub('-', '', datefield), location = trimws(location), force = gsub(' Service', '', force))]
dt[is.na(x_lon), x_lon := 0]
dt[is.na(y_lat), y_lat := 0]
dt[is.na(LSOA), LSOA := '']
dt[outcome == '', outcome := NA]

## 5- Check and eventually store new locations, get location_id -----------------------------------------------------------------
locations <- unique(dt[, .(x_lon, y_lat, name = location, LSOA)]) 
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'crime_incidents_uk')
dbWriteTable(dbc, 'locations', locations, row.names = FALSE, append = TRUE, overwrite = FALSE)
locations <- data.table(dbReadTable(dbc, 'locations'), key = c('x_lon', 'y_lat', 'name', 'LSOA'))
dbDisconnect(dbc)
setkey(dt, 'x_lon', 'y_lat', 'location', 'LSOA')
dt <- locations[dt][, c('x_lon', 'y_lat', 'name', 'LSOA', 'OA') := NULL][is.na(location_id), location_id := 1]

## 6- Recode Forces, Types, Outcomes --------------------------------------------------------------------------------------------
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'crime_incidents_uk')
forces <- data.table(dbGetQuery(dbc, 'SELECT force_id, long_name FROM forces'))
types <- data.table(dbGetQuery(dbc, 'SELECT type_id, description FROM types'))
outcomes <- data.table(dbGetQuery(dbc, 'SELECT outcome_id, description FROM outcomes'))
dbDisconnect(dbc)
dt <- forces[dt, on = c(long_name = 'force')][, long_name := NULL]
dt <- types[dt, on = c(description = 'type')][, description := NULL]
no_out <- (nrow(dt[!is.na(outcome), .N, outcome]) == 0)
if(!no_out) dt <- outcomes[dt, on = c(description = 'outcome')][, description := NULL]

## 11- Save abs [type = 1] and proper crime with no id --------------------------------------------------------------------------
t1 <- dt[type_id == 1, .N, by = .(force_id, type_id, location_id, datefield)]
dt <- dt[type_id > 1]
t2 <- dt[is.na(crime_id), .N, by = .(force_id, type_id, location_id, datefield)]
t <- rbindlist(list(t1, t2))[order(force_id, type_id, location_id)]
setnames(t, 'N', 'counting')
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'crime_incidents_uk')
dbWriteTable(dbc, 'crimes_noid', t, row.names = FALSE, append = TRUE)
dbDisconnect(dbc)
dt <- dt[!is.na(crime_id)]

## 12- Create alt crime_id

## 13- Save crime outcomes ------------------------------------------------------------------------------------------------------
if(!no_out){
    t <- unique(dt[!is.na(outcome_id), .(crime_id, outcome_id)])
}

## 14- Save all remaining proper crime ------------------------------------------------------------------------------------------
dt[, outcome_id := NULL]
dbc = dbConnect(MySQL(), group = 'dataOps', dbname = 'crime_incidents_uk')
dbWriteTable(dbc, 'crimes', dt[!is.na(crime_id)] , row.names = FALSE, append = TRUE)
dbDisconnect(dbc)


## Clean & Exit -----------------------------------------------------------------------------------------------------------------
rm(list = ls())
gc()
