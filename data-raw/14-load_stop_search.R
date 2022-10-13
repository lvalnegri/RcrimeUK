###############################################################
# 14- LOAD "STOP AND SEARCH" FILES
###############################################################

pkg <- c('popiFun', 'data.table', 'rgdal', 'rgeos', 'RMySQL')
invisible(lapply(pkg, require,  char = TRUE))

data_path <- file.path(ext_path, 'uk', 'crime_incidents')

recode_var <- function(vid){
    lkp <- lk[domain_id == vid, .(lookup_id, label)]
    lbl  <- lk[domain_id == 0 & lookup_id == vid, label]
    if(lkp[1, label] == 'No' & lkp[2, label] == 'Yes'){
        t <- dt[, get('lbl') := as.numeric(get(lbl))] 
        setnames(t, lbl, paste0('X', vid))
    } else {
        t  <- lkp[dt, on = c(label = lbl)][, label := NULL]
        setnames(t, 'lookup_id', paste0('X', vid))
    }
    t
}

yr <- 2019
mt <- 1
dts <- data.table()

for(yr in 2015:2020){

    for(mt in 1:12){
        
        mtc <- ifelse(mt < 10, paste0('0', mt), mt)
        yrc <- paste0(yr, '-', mtc)
        print(paste('\nProcessing ', yrc))
        
        fnames <- list.files(file.path(data_path, yrc), pattern = '-search', full.names = TRUE)
        if(length(fnames) == 0) break
        for(fn in fnames){
            print(paste('Processing ', fn))
            y <- fread(fn, na.strings = '')
            y <- data.table(force = gsub('-', ' ', substr(fn, max(gregexpr("[0-9$]", fn)[[1]] + 2), nchar(fn) - 20)), y)
            dts <- rbindlist(list( dts, y ))
        }
    
    }
    
}

dts[force == 'Btp', force := 'British Transport Police']
dts[, `Policing operation` := NULL]
setnames(dts, c(
    'force', 'type', 'datetime', 'is_operation', 'y_lat', 'x_lon', 'gender', 'age', 
    'self_ethnicity', 'ethnicity', 'legislation', 'object', 'outcome', 'out_linked_obj', 'outer_clothing'
))

dts[, datetime := fasttime::fastPOSIXct(datetime)]
dts[, `:=`(date.day = as.numeric(format(dts$datetime, '%Y%m%d')), date.hour = hour(datetime), date.min = minute(datetime))]

dts[, self_ethnicity := gsub('/', ' or ', self_ethnicity)]
dts[, self_ethnicity := gsub('\\s*\\([^\\)]+\\)', '',  self_ethnicity)]
dts[, self_ethnicity := gsub('ethnic ', '', self_ethnicity)]

for(col in c('force', 'type', 'gender', 'age', 'self_ethnicity', 'ethnicity', 'legislation', 'object', 'outcome'))
    dts <- capitalize(dts, col)

dts[, `:=`( is_operation = as.logical(is_operation), out_linked_obj = as.logical(out_linked_obj), outer_clothing = as.logical(outer_clothing) )]

y <- data.table(var = character(0), levels = character(0))
for(col in c('force', 'type', 'gender', 'age', 'self_ethnicity', 'ethnicity', 'legislation', 'object', 'outcome'))
    y <- rbindlist(list( y, data.table(var = col, levels = levels(dts[[col]])) ))    

# save as fst


# save as mysql



load_all_data <- function(y, start = 1, end = 12){
    m <- start:end
    m <- paste0(y, '-', paste0(ifelse(m<10, '0',''),m))
    lapply(m, load_data)
}
lookup_oas <- function(){

    # Load packages --------------------------------------------------------------------------------------------------
    pkg <- c('data.table', 'rgdal', 'rgeos', 'RMySQL')
    invisible(lapply(pkg, require,  char = TRUE))
    
    # Define variables -----------------------------------------------------------------------------------------------
    boundaries_path <- 
        if(substr(Sys.info()['sysname'], 1, 1) == 'W'){
            'D:/cloud/OneDrive/data/UK/geography/boundaries'
        } else {
            '/home/datamaps/data/UK/geography/boundaries'
        }
    
    # Load locations coordinates --------------------------------------------------------------------------------------
    dbc <- dbConnect(MySQL(), group = 'dataOps', dbname = 'crime_incidents_uk')
    strSQL <- "
        SELECT id AS s_id, x_lon, y_lat 
        FROM stop_search 
        WHERE ISNULL(OA) AND NOT ISNULL(x_lon)
    "
    locations <- data.table(dbGetQuery(dbc, strSQL))
    dbDisconnect(dbc)
    # build spatial references
    coordinates(locations) <- ~x_lon+y_lat
    
    # Load OA boundaries for UK ---------------------------------------------------------------------------------------
    shp <- readOGR(boundaries_path, 'OA')
    # delete Scotland
    shp <- subset(shp, substr(id, 1, 1) != 'S')
    # align poly and oas on same projection
    proj4string(locations) <- proj4string(shp)
    # returns OA polygon that includes location
    t <- cbind(locations@data, over(locations, shp))
    
    # Update table ----------------------------------------------------------------------------------------------------
    dbc <- dbConnect(MySQL(), group = 'dataOps', dbname = 'crime_incidents_uk')
    dbSendQuery(dbc, 'DROP TABLE IF EXISTS tmp')
    dbWriteTable(dbc, 'tmp', t[!is.na(t$id),], row.names = FALSE, append = TRUE)
    dbSendQuery(dbc, "
        ALTER TABLE `tmp`
        	CHANGE COLUMN `s_id` `s_id` MEDIUMINT(8) UNSIGNED NOT NULL FIRST,
        	CHANGE COLUMN `id` `id` CHAR(9) NOT NULL COLLATE 'utf8_unicode_ci' AFTER `s_id`,
        	ADD PRIMARY KEY (`s_id`);
    ")
    dbSendQuery(dbc, "UPDATE stop_search s JOIN tmp t ON t.s_id = s.id SET s.OA = t.id")
    dbSendQuery(dbc, 'DROP TABLE tmp')
    dbDisconnect(dbc)

}

