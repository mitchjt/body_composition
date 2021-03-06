### BODY COMPOSITION APP

library(shiny); library(TTR); library(googlesheets)

sheet <- gs_title('body_data')
data <- gs_read_csv(sheet)
data$date <- as.Date(data$date, format = "%Y-%m-%d")

# Define server logic
shinyServer(function(input, output) {
    values <- reactiveValues(df_data = data)
    
    observeEvent(input$submit, {
        tmp <- data.frame(date = as.Date(input$date, format = "%Y-%m-%d", origin="1970-01-01"), 
                          weight = input$weight, bf = input$bf, sm = input$sm,
                          vf = input$vf)
        gs_add_row(sheet, input = tmp)
        tmp_full <- data.frame(date = as.Date(input$date, origin="1970-01-01"), 
                          weight = input$weight, bf = input$bf, sm = input$sm,
                          vf = input$vf, bodycomp = 0, weight_7ma = 0,
                          bf_7ma = 0, sm_7ma = 0, bc_7ma = 0)
        values$df_data <- rbind(values$df_data, tmp_full)
        calculate()
    })    
    
    calculate <- reactive({
        values$df_data$bodycomp <- values$df_data$sm / values$df_data$bf
        values$df_data$weight_7ma <- SMA(values$df_data$weight, 7)
        values$df_data$bf_7ma <- SMA(values$df_data$bf, 7)
        values$df_data$sm_7ma <- SMA(values$df_data$sm, 7)
        values$df_data$bc_7ma <- SMA(values$df_data$bodycomp, 7)
    })
    
    # view table
    output$datatable = renderDataTable({
        calculate()
        values$df_data
    })
    
    # weight plot
    output$weightplot = renderPlotly({
        calculate()
        plot_ly(values$df_data, x = ~date, y = ~weight, 
                type = "scatter", mode = "lines", name = 'RAW') %>%
        add_trace(x = ~date, y = ~weight_7ma, name = 'MA7', mode = 'lines')
    })
    
    # bodyfat plot
    output$bfplot = renderPlotly({
        calculate()
        plot_ly(values$df_data[!is.na(values$df_data$bf), ], x = ~date, y = ~bf, 
                type = "scatter", mode = "lines", name = 'RAW') %>%
            add_trace(x = ~date, y = ~bf_7ma, name = 'MA7', mode = 'lines')
    })
    
    # skeletal muscle plot
    output$smplot = renderPlotly({
        calculate()
        plot_ly(values$df_data[!is.na(values$df_data$sm), ], x = ~date, y = ~sm, 
                type = "scatter", mode = "lines", name = 'RAW') %>%
            add_trace(x = ~date, y = ~sm_7ma, name = 'MA7', mode = 'lines')
    })
    
    # bodycomp plot
    output$bcplot = renderPlotly({
        calculate()
        plot_ly(values$df_data[!is.na(values$df_data$bodycomp), ], x = ~date, y = ~bodycomp, 
                type = "scatter", mode = "lines", name = 'RAW') %>%
            add_trace(x = ~date, y = ~bc_7ma, name = 'MA7', mode = 'lines')
    })
    
})



