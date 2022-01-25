

library(shiny)
library(ggplot2)
library(sf)


load('objects.RData')

app <- shinyApp(
  
  ### design interface
  ui = fluidPage( 
    titlePanel( '' ),
    mainPanel(plotOutput('map')),
    
    sidebarLayout(
      mainPanel = mainPanel( h3( '' ) ),

      sidebarPanel(
        h3('Select County'),
        selectInput('county',
          label    = NULL,
          choices  = c(names(dat.list)[1], 
                       sort(names(dat.list)[2:length(names(dat.list))])),
          selected = 'All Counties'
        ),

        h3(''),
        radioButtons('metric',
          label = NULL,
          choices = c('Total Vacant Homes',
                      'Vacant Homes per 1,000 Residents'
          ),
          selected = 'Total Vacant Homes'
        )
      )
    )
  ),
  
  ### generate output
  server = function( input, output ){
    
    # determine break points 
    breaks <- reactive({
      if (input$metric == 'Total Vacant Homes' & input$county == 'All Counties'){
        digs1 <- -4
        digs2 <- -2
        plus <- 10000
      }else{
        digs1 <- digs2 <- -1
        plus <- 10
      }

      if (input$metric == 'Total Vacant Homes'){
        unique(round(
          c(-Inf, 
            quantile(dat.list[input$county][[1]]$B25004_008E,
                     c(0.2, 0.4, 0.6, 0.8, .95)),
            round(max(dat.list[input$county][[1]]$B25004_008E),
                  digits = digs1) + plus),
          digits = digs2
        ))
      }else{
        unique(round(
          c(-Inf, 
            quantile((dat.list[input$county][[1]]$B25004_008E /
                        dat.list[input$county][[1]]$B01001_001E)*1000,
                     c(0.2, 0.4, 0.6, 0.8, .95), na.rm = T),
            round(max((dat.list[input$county][[1]]$B25004_008E /
                         dat.list[input$county][[1]]$B01001_001E)*1000,
                      na.rm = T),
              digits = digs1) + plus),
          digits = digs2
        ))
      }
    })
    
    labs <- reactive({
      y <- c()
      x1 <- 0
      i <- 1
      for (x in breaks()){
        if (i > 1){
          y <- c(y, paste0(scales::comma(x1), '-',
                           scales::comma(x)))
          x1 <- x
        }
        i <- i + 1
      }
      y
    })


    # subset to selected geography
    df <- reactive({
      #browser()
      x <- dat.list[input$county][[1]]
      if (input$metric == 'Total Vacant Homes'){
        x$vhome_bracket <- cut(x$B25004_008E, breaks())
      }else{
        var <- (x$B25004_008E / x$B01001_001E)*1000
        x$vhome_bracket <- cut(var, breaks())
      }
      x
    })

    # set color palette
    pal <- reactive({hcl.colors(length(breaks()), 'Inferno', rev = TRUE,
                                alpha = 0.7)})
    
    # define legend title
    ltitle <- reactive({
      if (input$metric == 'Total Vacant Homes'){
        '"Other" Vacant Homes\n(ACS variable B025004_008E)'
      }else{
        paste0('"Other" Vacant Homes per 1,000 residents\n',
               '(B025004_008E/B01001_001E)*1000')
      }
    })
      
      
    
    ### generate map
    output$map = renderPlot({
      ggplot(df()) + 
      geom_sf(aes(fill = vhome_bracket),
              color = NA) + 
      #coord_sf(crs = us_longlat_proj) + 
      scale_fill_manual(values = pal(),
                        drop = FALSE,
                        na.value = 'grey80',
                        labels = labs(),
                        guide = guide_legend(direction = 'horizonal',
                                            nrow = 1,
                                            title = ltitle(),
                                            title.position = 'left')) + 
      theme(legend.position = 'bottom',
            axis.text.x      = element_blank(),
            axis.text.y      = element_blank(),
            axis.ticks       = element_blank(),
            panel.background = element_blank())
    })
  }
)
