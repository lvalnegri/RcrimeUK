####################################################
# 12a- LOAD "STREET" FILES from the start: 2010-12 #
####################################################

pkgs <- c('popiFun', 'data.table', 'fst', 'rgdal', 'sp')
lapply(pkgs, require, char = TRUE)
setDTthreads(0)

base_path <- file.path(ext_path, 'uk', 'crime_incidents')
out_path <- file.path(datauk_path, 'crime_incidents')
mnths <- c('2010-12', paste0(rep(2011:2020, each = 12), '-', c(paste0('0', 1:9), 10, 11, 12)))
cnames <- c('crime_id', 'datefield', 'force', 'x_lon', 'y_lat', 'location', 'LSOA', 'type', 'outcome')
cpos <- c(1:2, 4:8, 10:11)

dts <-data.table(
        crime_id = character(), datefield = integer(), force = factor(), 
        x_lon = numeric(), y_lat = numeric(), location = factor(),
        type = factor(), outcome = factor()
)
for(mn in mnths){
    message('\n-----------------------------------------------------------------\n')
    message('Processing month ', mn, ':\n')
    data_path <- file.path(ext_path, 'uk', 'crime_incidents', mn)
    fnames <- list.files(data_path, pattern = '-street', full.names = TRUE)
    if(length(fnames) == 0) exit
    for(fn in fnames){
        message(' - Loading ', gsub('-street.csv', '', gsub(paste0(data_path, '/', mn, '-'), '', fn)))
        y <- fread(fn, select = cpos, col.names = cnames, na.strings = '')
        y <- y[, LSOA := NULL]
        y <- y[location != 'No Location']
        y[, location := gsub("'S", 's', location)]
        y[, location := gsub("St ", 'St. ', location)]
        y[, location := gsub("  ", ' ', location)]
        y[, location := gsub(" - | -|- ", '-', location)]
        y[, datefield := as.numeric(gsub('-', '', datefield))]
        message('\n - Adding to previous dataset...')
        dts <- rbindlist(list( dts, y ))
    }
}
message(' - Reordering factor variables...')
dts[, `:=`(
    force = factor(force, levels = sort(levels(dts$force)))
    location = factor(location, levels = sort(levels(dts$location)))
    type = factor(type, levels = sort(levels(dts$type)))
    outcome = factor(outcome, levels = sort(levels(dts$outcome)))
)]

message(' - Saving first version...')
write_fst_idx('incidents', c('force', 'datefield'), dts, out_path)

message('Processing <LOCATIONS>...')
message(' - Loading OA Boundaries...')
bnd <- readRDS(file.path(bnduk_path, 'rds', 's00', 'OA'))
message(' - Creating unique spatial locations...')
y <- SpatialPoints(unique(dts[, .(x_lon, y_lat)]))
coordinates(y) <- ~x_lon+y_lat
proj4string(y) <- crs.wgs
message(' - Calculating Points In Polygons...')
yo <- y[bnd,]
message(' - Adding OA codes...')
yo <- cbind( bnd@data$OA, yo)
message(' - Adding OA to main dataset...')
dts <- yo[dts, on = c('x_lon', 'y_lat')]
message(' - Saving final version...')
write_fst_idx('incidents', c('force', 'datefield'), dts, out_path)




message('Processing <FORCES>...')
y <- data.table()
for(mn in mnths){
    message(' processing ', mn)
    y <- unique( rbindlist(list( y, unique(dts[[mn]][, .(name = force)]) )) )
}
setorder(y, name)
y[, force_id := 1:.N]
dbm_do('uk_crime_incidents', 'w', 'forces', y)

message('Processing <LOCATIONS>...')
y <- data.table()
for(mn in mnths){
    message(' processing ', mn)
    y <- unique( rbindlist(list( y, unique(dts[[mn]][, .(name = location, LSOA, x_lon, y_lat)]) )) )
}

bnd <- readRDS(file.path(bnduk_path, 'rds', 's00', 'OA'))
y.sp <- SpatialPoints(unique(y[, .(x_lon, y_lat)]))
coordinates(y.sp) <- ~x_lon+y_lat
proj4string(y.sp) <- crs.wgs
y.sp.over <- y.sp[bnd,]

y.sp <- y[, .(LSOA, x_lon, y_lat)]
coordinates(y.sp) <- ~x_lon+y_lat
proj4string(y.sp) <- crs.wgs

y.spip <- y.sp[bnd,]$LSOA


y[, name := gsub('By Pass', 'Bypass', name)]
y[, name := gsub('By-Pass', 'Bypass', name)]
y[grepl('Park-View|Garden-Lane', name), name := gsub('-', ' ', name)]
# add dash to names without and with
yd <- unique(y[grepl('-', name), .(name_old = name)])[, name := gsub('-', ' ', name_old)]
y[, name := gsub('Ashton Under Lyne', 'Ashton-Under-Lyne', name)]

setorderv(y, c('LSOA', 'name'))
y[, location_id := 1:.N]
dbm_do('uk_crime_incidents', 'w', 'locations', y)

'x_lon', 'y_lat', 'location', 'LSOA'
dt[, .N, type]






message('Cleaning...')
rm(list = ls())
gc()
