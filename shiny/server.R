#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

# import libraries, custom functions and snomed dictionary
  library(shiny)
  source('midata-helper.R')
  source('graphics.R')
  coding <- read.csv("codingSCT.csv", sep=",", header=T, row.names = "code")
  debug <- "OK"
# / import libraries, custom functions and snomed dictionary
  
# import and prepare data
  # midata: load, extract, prepare
    client <- setupMidata(url="https://ch.midata.coop", forceLogin = FALSE)
    conditions <- extractObservation(queryMidata(client))
    conditions <- extractObservation(res)
    conditions <- prepareData(conditions)

  # split off headache
    headaches <- data.frame(day = subset(conditions, (conditions$type == "headache"))$day, intensity = subset(conditions, (conditions$type == "headache"))$intensity, duration = subset(conditions, (conditions$type == "headache"))$duration, uid = subset(conditions, (conditions$type == "headache"))$uid)
    headaches <- colourize(headaches, c("darkolivegreen4", "orange", "red3"))

# / import and prepare data




shinyServer(function(input, output) {
   
  output$intensity <- renderPlot({
    
    title <- "Kopfschmerz-Intensität nach Tagen"
    alldates <- c()
    
    alldates <- c(alldates, headaches$day)
    
    if(input$autodate){
      if(length(alldates) == 0){
        startDate <- Sys.Date #as.Date("2018-11-13", origin="1970-01-01")
        endDate <- Sys.Date   #as.Date("2018-11-13", origin="1970-01-01")
      }
      else{
        startDate <- as.Date(min(alldates), origin="1970-01-01") # find earliest date
        endDate <- as.Date(max(alldates), origin="1970-01-01")  # find latest date
      }
    }
    else{
      startDate <- as.Date(input$daterange[1], origin="1970-01-01")
      endDate <- as.Date(input$daterange[2], origin="1970-01-01")
    }
    
    dayFrame <- preparePlot(from=startDate, to=endDate,label="UID", yLim=c(0.5,6.2))
    plotFrame <- merge(x=dayFrame,y=headaches, all.x=TRUE)
    pat <- as.numeric(input$patient)
    if(pat > 0){
      # draw migraine curve
      drawCurve(amplitude = input$amplitude/2, zero = pat, threshold = input$threshold, offset = input$offset, period = input$period, showLine = input$line)
    }
    # draw data points
    lines(plotFrame$day, plotFrame$uid, type="p", col=plotFrame$col, pch = 16, cex = (plotFrame$duration)/2 )
    
    # draw intensity values if requested
    if(input$values){
      text(plotFrame$day, plotFrame$uid, plotFrame$intensity, cex=0.6)
    }
    
    # draw all checked symptoms
    i <- 1
    if(!is.null(input$symptoms)){
      for(code in input$symptoms){
        addToPlot(code, colour="wheat4", symbol=as.character(coding[code,'symbol']), days = dayFrame, conditions = conditions, offset = i)
        i <- i+1
      }
    }
    
    

  })
  
  ## plot defacto migraine intensity curve
  output$patientDetail <- renderPlot({
    

    ## adjust date
    if(input$autodate2){
      usr <- subset(conditions, conditions$uid == input$uid)
      daterange <- c(min(usr$startTime) - (24*60*60), max(usr$endTime) + (24*60*60))
    }
    else{
      daterange <- c(input$daterange2[1],input$daterange2[2])
    }
    
    
    plotBySCT(userid=input$uid, conditions = conditions, daterange = daterange, description = "Headache", ypos = 10)
    
    pos <- 9.5
    
    if(!is.null(input$symptoms2)){
      for(code in input$symptoms2){
        plotBySCT(sct=code, userid=input$uid, conditions = conditions, colour= as.character(coding[code,'col']), daterange = daterange, description = as.character(coding[code,'textEN']), ypos = pos)
        pos <- pos - 0.5
      }
    }
   
    
  })
  
    # output$stats2 <- renderPrint({
    #   debug
    # })
  output$patname <- renderText("Migraine curve")
  
})
