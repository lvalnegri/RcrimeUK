###############################################################
# 13- LOAD "OUTCOME" FILES
###############################################################

## 1- load packages -------------------------------------------------------------------------------------------------------------
pkg <- c('data.table', 'RMySQL')
invisible(lapply(pkg, require,  char = TRUE))

## 2- Define variables ----------------------------------------------------------------------------------------------------------
cur_month <- '2017-08' # <== LAST MONTH 
data_path <- 
    if (substr(Sys.info()['sysname'], 1, 1) == 'W') {
        'D:/cloud/OneDrive/data/UK/crime_incidents/'
    } else {
        '/home/datamaps/data/UK/crime_incidents/'
    }
data_path <- paste0(data_path, cur_month, '/')
fnames <- list.files(data_path, pattern = '-outcome', full.names = TRUE)
cnames <- c('crime_id', 'datefield', 'force', 'x_lon', 'y_lat', 'location', 'LSOA', 'outcome')
cpos <- c(1:2, 4:8, 10)

## 3- Define functions ----------------------------------------------------------------------------------------------------------

## 4- Read and clean data, build unique dataset ---------------------------------------------------------------------------------
dt <- fread(fnames[1], select = cpos, col.names = cnames)
for(fn in fnames[2:length(fnames)]){
    print(paste('Processing ', fn))
    t <- fread(fn, select = cpos, col.names = cnames)
    dt <- rbindlist(list(dt, t))
}

## 5- Recode columns ------------------------------------------------------------------------------------------------------------

# datefield

# force

# location (x_lon, y_lat, location, LSOA)

# outcome




