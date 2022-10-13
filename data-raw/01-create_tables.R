########################################################
# UK CRIME INCIDENTS * 01 - Create database and tables #
########################################################

# preliminaries -----------------------------------------------------
lapply(c('popiFun', 'data.table', 'fst'), require, char = TRUE)
in_path <- file.path(pub_path, 'ancillaries', 'uk', 'crime_incidents')
dbname <- 'uk_crime_incidents'

# create database ---------------------------------------------------
create_db(dbname)

# FORCES ------------------------------------------------------------
x <- "
"
create_dbtable('forces', dbname, x)

# NEIGHBOURHOODS ----------------------------------------------------
x <- "
"
create_dbtable('neighbourhoods', dbname, x)

# LOCATIONS ---------------------------------------------------------
x <- "
"
create_dbtable('locations', dbname, x)

# INCIDENTS ---------------------------------------------------------
x <- "
"
create_dbtable('incidents', dbname, x)

# CRIMES ------------------------------------------------------------
x <- "
"
create_dbtable('crimes', dbname, x)

# CRIMES NO IDs (including ASB) -------------------------------------
x <- "
"
create_dbtable('crimes_noid', dbname, x) # asbos ???

# TYPES -------------------------------------------------------------
x <- "
"
create_dbtable('types', dbname, x)

# OUTCOMES ----------------------------------------------------------
x <- "
"
create_dbtable('outcomes', dbname, x)

# CRIMES <=> OUTCOMES -----------------------------------------------
x <- "
"
create_dbtable('crimes_outcomes', dbname, x)

# STOP AND SEARCH ---------------------------------------------------
x <- "
"
create_dbtable('stop_search', dbname, x)

# LOOKUPS FOR STOP AND SEARCH ---------------------------------------
x <- "
"
create_dbtable('ss_lookups', dbname, x)

# SUMMARIES ---------------------------------------------------------
x <- "
    location_type CHAR(4) NOT NULL,
    location_id CHAR(9) NOT NULL,
    datefield MEDIUMINT(8) UNSIGNED NOT NULL,
    type_id TINYINT(3) UNSIGNED NOT NULL,
    counting MEDIUMINT(8) UNSIGNED NOT NULL DEFAULT '0',
    PRIMARY KEY (datefield, PFL, type_id),
    INDEX location_type (location_type),
    INDEX location_id (location_id),
    INDEX datefield (datefield),
    INDEX type_id (type_id)
"
create_dbtable('summaries', dbname, x)

# CLEAN & EXIT ------------------------------------------------------
rm(list = ls())
gc()
