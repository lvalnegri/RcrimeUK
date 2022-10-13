#####################################################
# SHINY APP - DEMO Crime Reporting UK - app.R
#####################################################

libs <- c('data.table', 'dplyr', 'reshape2', 'RMySQL', 'shiny') 
wrng <- lapply(libs, require, character.only = TRUE)
rm(libs)
# source('')
db_host = ''
db_usr = ''
db_pwd = ''

server <- function(input, output) {

}

ui <- fluidPage( # theme = shinytheme('flatly'),
    
    headerPanel('UK Crime analysis'),
    
    sidebarPanel(
        dateRangeInput('optDates', 'Date Range:',
            startview = 'year', separator = '►', format = 'MM yyyy',
            min = '2011-01', max = '2015-09', start = '2015-08', end = '2015-09'
        ),
        radioButtons('rdbWhat', label = 'Show:', choices = list('Metric' = '1', 'KPI' = '2'), selected = '2' ), 
        conditionalPanel(condition = "input.rdbWhat == '1'",
            selectInput('cboMetric', 'Choose a metric:', 
                choices = list('Buyers' = 1, 'Demands' = 2, 'Offers' = 3 , 'Orders' = 4, 'Revenues' =  5 ),
                selected = 4
            )
        ),
        conditionalPanel(condition = "input.rdbWhat == '2'",
            selectInput('cboKPI', 'Choose a KPI:', 
                choices = list('Conversion rate' = 1, 'AOV' = 2, 'ARPC' = 3 ),
                selected = 1
            )
        ),
        br(),
        selectInput('cboCountry', 'Country:', 
            choices = c('England' = 'E92000001', 'Wales' = 'W92000004', 'Scotland' = 'S92000003', 'Northern Ireland' = 'N92000002'),
            selected = 'E92000001'
        ),
        conditionalPanel(condition = "input.cboCountry == 'E92000001'",
            selectInput('cboRegion', 'Region:', 
                choices = c(
                    'East Midlands' = 'E12000004', 'East of England' = 'E12000006', 'London' = 'E12000007',
                    'North East' = 'E12000001', 'North West' = 'E12000002', 'South East' = 'E12000008',
                    'South West' = 'E12000009', 'Yorkshire and The Humber' = 'E12000003', 'West Midlands' = 'E12000005'
                ),
                selected = 'E12000007'
            )
        ),
        
        br(),
        selectInput('cboTheme', 'Geographical Division:', 
            choices = c(
                'Statistical Blocks' = '1', 'Electoral Wards' = '2', 'Parliamentary Constituency' = '3', 
                'Postcodes' = '4', 'EU NUTS Classification' = '5'
            ),
            selected = '1'
        ),
        conditionalPanel(condition = "input.cboTheme == '1'",
            selectInput('cboStatBlocks', 'Entity of Analysis:', 
                choices = c('Lower-layer Super OA' = 'LSOA', 'Middle-layer Super OA' = 'MSOA', 'Local Authority' = 'LAD', 'County' = 'CTY'),
                selected = 'MSOA'
            )
        ),
        conditionalPanel(condition = "input.cboTheme == '4'",
            selectInput('cboPostCodes', 'Entity of Analysis:', 
                choices = c('Sector' = 'PCS', 'District' = 'PCD', 'Area' = 'PCA'),
                selected = 'PCD'
            )
        ),
        conditionalPanel(condition = "input.cboTheme == '5'",
            selectInput('cboEU', 'Entity of Analysis:', 
                choices = c('Local Admin. Unit 2nd level' = 'LAU2', 
                   'Local Admin. Unit 1st level' = 'LAU1', 
                   'Small Regions (NUTS3)' = 'NUT3',
                   'Basic Regions (NUTS2)' = 'NUT2',
                   'Major Regions (NUTS1)' = 'NUT1'
                ),
                selected = 'LAU1'
            )
        ),
        
        br(), hr(), br(),

        radioButtons('optChartType', 'Download map as: ', choices = list('PNG', 'JPG', 'PDF'), selected = 'PNG' ),
        downloadButton('downloadPlot', label = "Download"),
        
        width = 2
      
    ),
    
    mainPanel( 
        textOutput('myText'),
        plotOutput('map', height = '1200', width = '1600px') 
    ) 
                  
)

shinyApp(ui = ui, server = server)
