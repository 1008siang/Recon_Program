options(shiny.maxRequestSize = 500*1024^2)
options(scipen = 999)
options(useFancyQuotes = FALSE)
options(warn = -1)

# Load R packages
library(shiny)
library(shinyWidgets)
library(shinyjs)
library(shinythemes)
library(dplyr)
library(gtools)
library(readxl)
library(writexl)
library(openxlsx)
library(shinydashboard)
library(filesstrings)


# Loading GIF
img <- 'https://c.tenor.com/5o2p0tH5LFQAAAAi/hug.gif'

# GIF Size
imgsize <- "auto 10%"



### DEFINE UI ###
ui <- fluidPage(
                
                shinyjs::useShinyjs(),
                
                navbarPage(
                  "Dashboard",
                  
                    tabPanel("Comparison Dataset",
                           # input panel
                           sidebarPanel(
                             textInput("title","Title"),
                             
                             textInput("primarySkip","Enter the row number for column names of primary dataset"),
                             
                             fileInput("primary","Select Primary Dataset",accept = ".xlsx"),
                             uiOutput("xCompare"), 
                             
                             
                             textInput("secondarySkip","Enter the row number for column names of secondary dataset"),
                             
                             fileInput("secondary","Select Secondary Dataset",accept = ".xlsx"),
                             uiOutput("yCompare"),
                             
                             
                             #textInput("reconRow","Enter the Number of Rows to Skip"),
                             #textInput("cashRow","Enter the Number of Rows to Skip"),
                             
                             
                             # Javasript Code
                             singleton(tags$head(HTML("
                                  <script type='text/javascript'>
                                  
                                  /* When recalculating starts, show loading screen */
                                  $(document).on('shiny:recalculating', function(event) {
                                  $('div#divLoading').addClass('show');
                                  });
                                  
                                  /* When new value or error comes in, hide loading screen */
                                  $(document).on('shiny:value shiny:error', function(event) {
                                  $('div#divLoading').removeClass('show');
                                  });
  
                                  </script>"))),
                             
                             # CSS Code
                             singleton(tags$head(HTML(paste0("
                                    <style type='text/css'>
                                    #divLoading
                                    {
                                      display : none;
                                      }
                                      #divLoading.show
                                      {
                                      display : block;
                                      position : fixed;
                                      z-index: 100;
                                      background-image : url('",img,"');
                                      background-size:", imgsize, ";
                                      background-repeat : no-repeat;
                                      background-position : center;
                                      left : 0;
                                      bottom : 0;
                                      right : 0;
                                      top : 0;
                                      }
                                      #loadinggif.show
                                      {
                                      left : 50%;
                                      top : 50%;
                                      position : absolute;
                                      z-index : 101;
                                      -webkit-transform: translateY(-50%);
                                      transform: translateY(-50%);
                                      width: 100%;
                                      margin-left : -16px;
                                      margin-top : -16px;
                                      }
                                      div.content {
                                      width : 800px;
                                      height : 800px;
                                      }
                                      
                                    </style>")))),
                             
                             # HTML Code   
                             
                             box(tags$body(HTML("<div id='divLoading'> </div>")),width = 12, height = 50),
                             column(10,actionButton("buttonComparePrim", "Compare Non-Matched Values (Primary with secondary)"),actionButton("buttonCompareSec", "Compare Non-Matched Values (Secondary with primary)"),actionButton("buttonCompareMatched", "Compare Matched and Duplicated Values")),
                             

   
                             
                          
                             uiOutput("text1"),uiOutput("text2"), uiOutput("text3"))
                           
                  ),

                  mainPanel(
                    h1("Comparison Summary"),
                    tags$h1(tags$style("{
                                 margin-bottom: 80px;
                                 }"
                    )
                    ),
                    
                    uiOutput("timetaken"),
                    tags$head(tags$style("#timetaken{
                                 font-size: 18px;
                                 margin-bottom: 10px;
                                                                 }"
                      )
                    ),
                    uiOutput("time"),
                    tags$head(tags$style("#time{
                                 font-size: 18px;
                                 margin-bottom: 50px;
                                 text-decoration: underline;
                                 }"
                    )
                    ),
                    uiOutput("no_data"),
                    tags$head(tags$style("#no_data{
                                 font-size: 18px;
                                 margin-bottom: 10px;
                                 }"
                      )
                    ),
                    uiOutput("data"),
                    tags$head(tags$style("#data{
                                 font-size: 18px;
                                 margin-bottom: 50px;
                                 text-decoration: underline;                                 }"
                    )
                    ),
                    uiOutput("no_null"),
                    tags$head(tags$style("#no_null{
                                 font-size: 18px;
                                 margin-bottom: 10px;

                                 }"
                      )
                    ),
                    uiOutput("null"),
                    tags$head(tags$style("#null{
                                 font-size: 18px;
                                 margin-bottom: 50px;
                                 text-decoration: underline;

                                 }"
                    )
                    )
                    
                    
                  )
                  
                ) # navbarPage 
                
) # fluidPage

server <- function(input, output,session) {

  
  
  M = reactive({
    M = tagList()
    skipRows = as.numeric(input$primarySkip)-1
    D = primaryFile <- read_excel(input$primary$datapath,skip = skipRows,n_max=skipRows+1)
    D = as.data.frame(D)
    
    ## Upating file names
    colnames(D) <- labs <- gsub("\r\n"," ", colnames(D))
    nums = labs[which(sapply(D, is.numeric) == TRUE)]
    
    M[[1]] = D
    M[[2]] = nums
    
    M
  })
  
  # UI selection input for X axis
  output$xCompare <- renderUI({
    if(!is.null(input$primary$datapath)){
      selectInput("xInput", "Column difference for primary file :",
                  choices = colnames(M()[[1]]), selected = M()[[2]][1]
      )
    }
    
  })
  
  M2 = reactive({
    M2 = tagList()
    skipRows = as.numeric(input$secondarySkip)-1
    D = secondaryFile <- read_excel(input$secondary$datapath,skip = skipRows,n_max=skipRows+1)
    D = as.data.frame(D)
    
    ## Upating file names
    colnames(D) <- labs <- gsub("\r\n"," ", colnames(D))
    nums = labs[which(sapply(D, is.numeric) == TRUE)]
    
    M2[[1]] = D
    M2[[2]] = nums
    
    M2
  })
  
  # UI selection input for X axis
  output$yCompare <- renderUI({
    if(!is.null(input$secondary$datapath)){
      selectInput("yInput", "Column difference for file 2:",
                  choices = colnames(M2()[[1]]), selected = M2()[[2]][1]
      )
    }
    
  })
  
  
  M3 = reactive({
    M3 = tagList()
    skipRows = as.numeric(input$primarySkip)-1
    D = primaryFile <- read_excel(input$primary$datapath,skip = skipRows,n_max=skipRows+1)
    D = as.data.frame(D)
    
    ## Upating file names
    colnames(D) <- labs <- gsub("\r\n"," ", colnames(D))
    nums = labs[which(sapply(D, is.numeric) == TRUE)]
    
    M3[[1]] = D
    M3[[2]] = nums
    
    M3
  })
  

  
  M4 = reactive({
    M4 = tagList()
    skipRows = as.numeric(input$secondarySkip)-1
    D = secondaryFile <- read_excel(input$secondary$datapath,skip = skipRows,n_max=skipRows+1)
    D = as.data.frame(D)
    
    ## Upating file names
    colnames(D) <- labs <- gsub("\r\n"," ", colnames(D))
    nums = labs[which(sapply(D, is.numeric) == TRUE)]
    
    M4[[1]] = D
    M4[[2]] = nums
    
    M4
  })
  

  
  time <- reactiveValues(timetaken = " ") 
  no_data_compared <- reactiveValues(count = " ")
  no_row_null <- reactiveValues(count = " ")

  
  comparingPrimary <- eventReactive(input$buttonComparePrim,{
    
    begin <- Sys.time()
    
    
    j = 1
    pointer1 = 1
    pointer2 = 0
    
    skipRows = as.numeric(input$primarySkip)-1
    if(length(getSheetNames(input$primary$datapath)) > 1){
      for (i in seq(1,length(getSheetNames(input$primary$datapath)))){
        pages = getSheetNames(input$primary$datapath)
        if (i == 1){
          primaryFile <- read_excel(input$primary$datapath,skip = skipRows,sheet = pages[i])%>%mutate_all(as.character)
        }
        else{
          primaryFile <- bind_rows(primaryFile,read_excel(input$primary$datapath,skip = skipRows,sheet = pages[i])%>%mutate_all(as.character))
        }
      }
      xcomp <- primaryFile[[input$xInput]]
      dfPrimary = primaryFile[order(xcomp),]    }
    else{
      primaryFile <- read_excel(input$primary$datapath,skip = skipRows)
      xcomp <- primaryFile[[input$xInput]]
      dfPrimary = primaryFile[order(xcomp),]   
      }
    
    skipRows = as.numeric(input$secondarySkip)-1
    if(length(getSheetNames(input$secondary$datapath)) > 1){
      for (i in seq(1,length(getSheetNames(input$secondary$datapath)))){
        pages = getSheetNames(input$secondary$datapath)
        if (i == 1){
          secondaryFile <- read_excel(input$secondary$datapath,skip = skipRows, sheet = pages[1])%>%mutate_all(as.character)
          
        }
        else{
          secondaryFile <- bind_rows(secondaryFile,read_excel(input$secondary$datapath,skip = skipRows, sheet = pages[i])%>%mutate_all(as.character))
          
        }
      }
      ycomp <- secondaryFile[[input$yInput]]
      dfSecondary = secondaryFile[order(ycomp),]
    }
    else{
      secondaryFile <- read_excel(input$secondary$datapath,skip = skipRows)
      ycomp <- secondaryFile[[input$yInput]]
      dfSecondary = secondaryFile[order(ycomp),]
    }
    
    #create data frame
    df <- data.frame(matrix(ncol = ncol(dfPrimary), nrow = 0))
    #provide column names
    colnames(df) <- colnames(M()[[1]])
    
    x <- dfPrimary[[input$xInput]]
    y <- dfSecondary[[input$yInput]]
    
    discrepancy = NULL
    flag = FALSE
    for ( i in 1:nrow(dfPrimary)){
      while( j <= nrow(dfSecondary)){
        
        if(gtools::invalid(x[i]) | gtools::invalid(y[j])){
          j = j + 1
          if (is.null(discrepancy) & gtools::invalid(x[i])){
            discrepancy = i
          }
          break
        }
        else if(x[i] == y[j]){
          if(pointer2 >= pointer1){
            flag = FALSE
            if(nrow(df) >= 1){
              df = bind_rows(df,dfPrimary[pointer1:pointer2,])
            }
            else{
              df = rbind(df,dfPrimary[pointer1:pointer2,])
            }
          }
          
          pointer1 = i + 1

          
          if(i < (nrow(dfPrimary)-1) & j < (nrow(dfSecondary)-1)){
            if(!gtools::invalid(x[i+1]) & x[i+1] == y[j]){
              break
            }
            else if(!gtools::invalid(y[j+1]) & x[i] == y[j+1]){
              j = j + 1
            }
            else{
              j = j + 1
              break
            }
          }
          else{
            j = j + 1
            break
          }

        }
        else if (x[i] < y[j]){
          flag = TRUE
          pointer2 = i
          break
        }
        else{
          flag = TRUE
          j = j + 1
          
        }
      }
      
      if(j >= nrow(dfSecondary) & i <= nrow(dfPrimary)){
        if(!gtools::invalid(x[i]) & i != nrow(dfPrimary)){
          pointer2 = i
          
        }
        else{
          if (is.null(discrepancy) & gtools::invalid(x[i])){
            discrepancy = i
          }
          flag = FALSE

          if( i == nrow(dfPrimary)){
            if(i > 1){
              
              if (is.null(discrepancy) & gtools::invalid(x[i])){
                pointer2 = i-1
              }
              else{
                pointer2 = i
              }
            }
            else{
              pointer2 = i
            }

          }
          if(pointer2 >= pointer1){
            if(nrow(df) >= 1){
              df = bind_rows(df,dfPrimary[pointer1:pointer2,])
            }
            else{
              df = rbind(df,dfPrimary[pointer1:pointer2,])
            }
          }
          break
        }
      }
      
    }
    
    if(flag & pointer2 >= pointer1){
      if(nrow(df) >= 1){
        df = bind_rows(df,dfPrimary[pointer1:pointer2,])
      }
      else{
        df = rbind(df,dfPrimary[pointer1:pointer2,])
      }
    }
    
    if(!is.null(discrepancy) && nrow(dfPrimary) >= discrepancy){
      if(nrow(df) >= 1){
        df = bind_rows(df,dfPrimary[discrepancy:nrow(dfPrimary),])
      }
      else{
        df = rbind(df,dfPrimary[discrepancy:nrow(dfPrimary),])
      }
    }
     
    folderName <-paste("reconResult",input$title)  
        if(nrow(df) <= 1048575){
          
          dir.create(folderName)
          
          write_xlsx(df,"Non-Matched_Primary.xlsx")
          
          file.move("Non-Matched_Primary.xlsx",folderName,overwrite = TRUE)
        }
        else if (nrow(df) <= 2097150){
          dir.create(folderName)
          df1 <- df[1:1048575,]
          df2 <- df[1048576:nrow(df),]
          sheets <- list("Sheet1" = df1, "Sheet2" = df2) #assume sheet1 and sheet2 are data frames
          write_xlsx(sheets,"Non-Matched_Primary.xlsx")
          file.move("Non-Matched_Primary.xlsx",folderName,overwrite = TRUE)
          
        }
        else if (nrow(df) <= 3145725){
          df1 <- df[1:1048575,]
          df2 <- df[1048576:2097150,]
          df3 <- df[2097151:nrow(df),]
          sheets <- list("Sheet1" = df1, "Sheet2" = df2, "Sheet3" = df3) #assume sheet1 and sheet2 are data frames
          write_xlsx(sheets,"Non-Matched_Primary.xlsx")
          file.move("Non-Matched_Primary.xlsx",folderName,overwrite = TRUE)
          
         }
        else if (nrow(df) <= 4194301){
          df1 <- df[1:1048575,]
          df2 <- df[1048576:2097150,]
          df3 <- df[2097151:3145725,]
          df4 <- df[3145726:nrow(df),]
          sheets <- list("Sheet1" = df1, "Sheet2" = df2, "Sheet3" = df3,"Sheet4" = df4) #assume sheet1 and sheet2 are data frames
          write_xlsx(sheets,"Non-Matched_Primary.xlsx")
          file.move("Non-Matched_Primary.xlsx",folderName,overwrite = TRUE)
          
          }
        else if (nrow(df) <= 5242877){
          df1 <- df[1:1048575,]
          df2 <- df[1048576:2097150,]
          df3 <- df[2097151:3145725,]
          df4 <- df[3145726:4194301,]
          df5 <- df[4194302:nrow(df),]
          sheets <- list("Sheet1" = df1, "Sheet2" = df2, "Sheet3" = df3,"Sheet4" = df4,"Sheet5" = df5) #assume sheet1 and sheet2 are data frames
          write_xlsx(sheets,"Non-Matched_Primary.xlsx")
          file.move("Non-Matched_Primary.xlsx",folderName,overwrite = TRUE)
          
          
        }
        else{
          validate(
            need(nrow(df)<= 5242877,'THERE ARE TOO MANY FILES/FILES TOO LARGE')
          )
        }
        
    
    end <- Sys.time()
    time$timetaken <- difftime(end, begin, units='mins')
    time$timetaken <- format(round(time$timetaken, 2), nsmall = 2)
    no_data_compared$count <- i
    no_row_null$count <- nrow(dfPrimary) - discrepancy + 1

  })
  
  comparingSecondary <- eventReactive(input$buttonCompareSec,{
    
    begin <- Sys.time()
    
    j = 1
    pointer1 = 1
    pointer2 = 0
    
    
    
    skipRows = as.numeric(input$primarySkip)-1
    if(length(getSheetNames(input$primary$datapath)) > 1){
      for (i in seq(1,length(getSheetNames(input$primary$datapath)))){
        pages = getSheetNames(input$primary$datapath)
        if (i == 1){
          primaryFile <- read_excel(input$primary$datapath,skip = skipRows,sheet = pages[i])%>%mutate_all(as.character)
        }
        else{
          primaryFile <- bind_rows(primaryFile,read_excel(input$primary$datapath,skip = skipRows,sheet = pages[i])%>%mutate_all(as.character))
        }
      }
      xcomp <- primaryFile[[input$xInput]]
      dfSecondary = primaryFile[order(xcomp),]    
  }
    else{
      primaryFile <- read_excel(input$primary$datapath,skip = skipRows)
      xcomp <- primaryFile[[input$xInput]]
      dfSecondary = primaryFile[order(xcomp),]    
}
    
    skipRows = as.numeric(input$secondarySkip)-1
    if(length(getSheetNames(input$secondary$datapath)) > 1){
      for (i in seq(1,length(getSheetNames(input$secondary$datapath)))){
        pages = getSheetNames(input$secondary$datapath)
        if (i == 1){
          secondaryFile <- read_excel(input$secondary$datapath,skip = skipRows, sheet = pages[1])%>%mutate_all(as.character)
          
        }
        else{
          secondaryFile <- bind_rows(secondaryFile,read_excel(input$secondary$datapath,skip = skipRows, sheet = pages[i])%>%mutate_all(as.character))
          
        }
      }
      ycomp <- secondaryFile[[input$yInput]]
      dfPrimary = secondaryFile[order(ycomp),]
    }
    else{
      secondaryFile <- read_excel(input$secondary$datapath,skip = skipRows)
      ycomp <- secondaryFile[[input$yInput]]
      dfPrimary = secondaryFile[order(ycomp),]
    }
    
    #create data frame
    df <- data.frame(matrix(ncol = ncol(dfPrimary), nrow = 0))
    #provide column names
    colnames(df) <- colnames(M2()[[1]])
    
    x <- dfPrimary[[input$yInput]]
    y <- dfSecondary[[input$xInput]]
    
    discrepancy = NULL
    flag = FALSE
    for ( i in 1:nrow(dfPrimary)){
      while( j <= nrow(dfSecondary)){
        if(gtools::invalid(x[i]) | gtools::invalid(y[j])){
          j = j + 1
          if (is.null(discrepancy) & gtools::invalid(x[i])){
            discrepancy = i
          }
          
          break
        }
        else if(x[i] == y[j]){
          
          if(pointer2 >= pointer1){
            flag = FALSE
            if(nrow(df) >= 1){
              df = bind_rows(df,dfPrimary[pointer1:pointer2,])
            }
            else{
              df = rbind(df,dfPrimary[pointer1:pointer2,])
            }
          }
          
          pointer1 = i + 1
          
          if(i < (nrow(dfPrimary)-1) & j < (nrow(dfSecondary)-1)){
            if(!gtools::invalid(x[i+1]) & x[i+1] == y[j]){
              break
            }
            else if(!gtools::invalid(y[j+1]) & x[i] == y[j+1]){
              j = j + 1
            }
            else{
              j = j + 1
              break
            }
          }
          else{
            j = j + 1
            break
          }
          
        }
        else if (x[i] < y[j]){
          flag = TRUE
          pointer2 = i
          break
        }
        else{
          flag = TRUE
          j = j + 1
          
        }
      }
      
      if(j >= nrow(dfSecondary) & i <= nrow(dfPrimary)){
        if(!gtools::invalid(x[i]) & i != nrow(dfPrimary)){
          pointer2 = i
        }
        else{
          if (is.null(discrepancy) & gtools::invalid(x[i])){
            discrepancy = i
          }
          
          flag = FALSE
          if( i == nrow(dfPrimary)){
            if(i > 1){
              
              if (is.null(discrepancy) & gtools::invalid(x[i])){
                pointer2 = i-1
              }
              else{
                pointer2 = i
              }
            }
            else{
              pointer2 = i
            }
          }
          if(pointer2 >= pointer1){
            if(nrow(df) >= 1){
              df = bind_rows(df,dfPrimary[pointer1:pointer2,])
            }
            else{
              df = rbind(df,dfPrimary[pointer1:pointer2,])
            }
          
          }
          
          break
        }
      }
    }
    
    if(flag & pointer2 >= pointer1){
      if(nrow(df) >= 1){
        df = bind_rows(df,dfPrimary[pointer1:pointer2,])
      }
      else{
        df = rbind(df,dfPrimary[pointer1:pointer2,])
      }
    }
    
    if(!is.null(discrepancy) && nrow(dfPrimary) >= discrepancy){
      if(nrow(df) >= 1){
        df = bind_rows(df,dfPrimary[discrepancy:nrow(dfPrimary),])
      }
      else{
        df = rbind(df,dfPrimary[discrepancy:nrow(dfPrimary),])
      }
    }
    
    folderName <-paste("reconResult",input$title) 
    
        if(nrow(df) <= 1048575){
          dir.create(folderName)
          
          write_xlsx(df,"Non-Matched_Secondary.xlsx")
          
          file.move("Non-Matched_Secondary.xlsx",folderName,overwrite = TRUE)

        }
        else if (nrow(df) <= 2097150){
          dir.create(folderName)
          df1 <- df[1:1048575,]
          df2 <- df[1048576:nrow(df),]
          sheets <- list("Sheet1" = df1, "Sheet2" = df2) #assume sheet1 and sheet2 are data frames
          write_xlsx(sheets,"Non-Matched_Secondary.xlsx")
          file.move("Non-Matched_Secondary.xlsx",folderName,overwrite = TRUE)
          
    
        }
        else if (nrow(df) <= 3145725){
          dir.create(folderName)
          df1 <- df[1:1048575,]
          df2 <- df[1048576:2097150,]
          df3 <- df[2097151:nrow(df),]
          sheets <- list("Sheet1" = df1, "Sheet2" = df2, "Sheet3" = df3) #assume sheet1 and sheet2 are data frames
          write_xlsx(sheets,"Non-Matched_Secondary.xlsx")
          file.move("Non-Matched_Secondary.xlsx",folderName,overwrite = TRUE)
          
       }
        else if (nrow(df) <= 4194301){
          dir.create(folderName)
          df1 <- df[1:1048575,]
          df2 <- df[1048576:2097150,]
          df3 <- df[2097151:3145725,]
          df4 <- df[3145726:nrow(df),]
          sheets <- list("Sheet1" = df1, "Sheet2" = df2, "Sheet3" = df3,"Sheet4" = df4) #assume sheet1 and sheet2 are data frames
          write_xlsx(sheets,"Non-Matched_Secondary.xlsx")
          file.move("Non-Matched_Secondary.xlsx",folderName,overwrite = TRUE)
          
           }
        else if (nrow(df) <= 5242877){
          dir.create(folderName)
          df1 <- df[1:1048575,]
          df2 <- df[1048576:2097150,]
          df3 <- df[2097151:3145725,]
          df4 <- df[3145726:4194301,]
          df5 <- df[4194302:nrow(df),]
          sheets <- list("Sheet1" = df1, "Sheet2" = df2, "Sheet3" = df3,"Sheet4" = df4,"Sheet5" = df5) #assume sheet1 and sheet2 are data frames
          write_xlsx(sheets,"Non-Matched_Secondary.xlsx")
          file.move("Non-Matched_Secondary.xlsx",folderName,overwrite = TRUE)
          
         
        }
        else{
          validate(
            need(nrow(df)<= 5242877,'THERE ARE TOO MANY FILES/FILES TOO LARGE')
          )
        }

    
    end <- Sys.time()
    time$timetaken <- difftime(end, begin, units='mins')
    time$timetaken <- format(round(time$timetaken, 2), nsmall = 2)
    no_data_compared$count <- i
    no_row_null$count <- nrow(dfPrimary) - discrepancy + 1

  })
  
  comparingMatchedPrimary <- eventReactive(input$buttonCompareMatched,{
    
    begin <- Sys.time()
    
    
    j = 1
    pointer1 = 1
    pointer2 = 0
    prev_pointer2 = 0
    pointer1A = 1
    pointer2A = 0
    duplicates_i = FALSE
    duplicates_j = FALSE
    skipRows = as.numeric(input$primarySkip)-1
    if(length(getSheetNames(input$primary$datapath)) > 1){
      for (i in seq(1,length(getSheetNames(input$primary$datapath)))){
        pages = getSheetNames(input$primary$datapath)
        if (i == 1){
          primaryFile <- read_excel(input$primary$datapath,skip = skipRows,sheet = pages[i])%>%mutate_all(as.character)
        }
        else{
          primaryFile <- bind_rows(primaryFile,read_excel(input$primary$datapath,skip = skipRows,sheet = pages[i])%>%mutate_all(as.character))
        }
      }
      xcomp <- primaryFile[[input$xInput]]
      dfPrimary = primaryFile[order(xcomp),]   
    }
    else{
      primaryFile <- read_excel(input$primary$datapath,skip = skipRows)
      xcomp <- primaryFile[[input$xInput]]
      dfPrimary = primaryFile[order(xcomp),]   
    }
    
    skipRows = as.numeric(input$secondarySkip)-1
    if(length(getSheetNames(input$secondary$datapath)) > 1){
      for (i in seq(1,length(getSheetNames(input$secondary$datapath)))){
        pages = getSheetNames(input$secondary$datapath)
        if (i == 1){
          secondaryFile <- read_excel(input$secondary$datapath,skip = skipRows, sheet = pages[1])%>%mutate_all(as.character)
          
        }
        else{
          secondaryFile <- bind_rows(secondaryFile,read_excel(input$secondary$datapath,skip = skipRows, sheet = pages[i])%>%mutate_all(as.character))
          
        }
      }
      ycomp <- secondaryFile[[input$yInput]]
      dfSecondary = secondaryFile[order(ycomp),]   
          }
    else{
      secondaryFile <- read_excel(input$secondary$datapath,skip = skipRows)
      ycomp <- secondaryFile[[input$yInput]]
      dfSecondary = secondaryFile[order(ycomp),]   
    }
    
    #create data frame
    df2 <- data.frame(matrix(ncol = ncol(dfPrimary), nrow = 0))
    #provide column names
    colnames(df2) <- colnames(M3()[[1]])
    
    #create data frame
    df3 <- data.frame(matrix(ncol = ncol(dfSecondary), nrow = 0))
    #provide column names
    colnames(df3) <- colnames(M4()[[1]])
    
    #create data frame
    df4 <- data.frame(matrix(ncol = ncol(dfPrimary), nrow = 0))
    #provide column names
    colnames(df4) <- colnames(M3()[[1]])
    
    #create data frame
    df5 <- data.frame(matrix(ncol = ncol(dfSecondary), nrow = 0))
    #provide column names
    colnames(df5) <- colnames(M4()[[1]])
    
    
    x <- dfPrimary[[input$xInput]]
    y <- dfSecondary[[input$yInput]]
    
    discrepancy = NULL
    flag = FALSE
    for ( i in 1:nrow(dfPrimary)){
      while( j <= nrow(dfSecondary)){
        if(gtools::invalid(x[i]) | gtools::invalid(y[j])){
          j = j + 1
          if (is.null(discrepancy) & gtools::invalid(x[i])){
            discrepancy = i
          }
          break
        }
        else if(x[i] == y[j]){
          flag = TRUE
          
          
          if(i <= (nrow(dfPrimary)-1) && !gtools::invalid(x[i+1]) && x[i+1] == y[j]){
            
            if (pointer2 >= pointer1 ){
              df2 = rbind(df2,dfPrimary[pointer1:pointer2,])
              
            }
            
            if (pointer2A >= pointer1A ){
              df3 = rbind(df3,dfSecondary[pointer1A:pointer2A,])
              
            }
            
            if (!duplicates_i){
              if(!duplicates_j){
                df4 = rbind(df4,dfPrimary[i,])
              }
              df4 = rbind(df4,dfPrimary[i+1,])
              df5 = rbind(df5,dfSecondary[j,])
              pointer1A = j + 1
              duplicates_i = TRUE
              
            }
            else {
              df4 = rbind(df4,dfPrimary[i+1,])
              
            }
            pointer1 = i + 2
            break
          }
          else if(j <= (nrow(dfSecondary)-1) && !gtools::invalid(y[j+1]) && x[i] == y[j+1]){
            
            
            if (pointer2 >= pointer1 ){
              df2 = rbind(df2,dfPrimary[pointer1:pointer2,])
              
            }
            if (pointer2A >= pointer1A ){
              df3 = rbind(df3,dfSecondary[pointer1A:pointer2A,])
              
            }
            
            if (!duplicates_j){
              if(!duplicates_i){
                df4 = rbind(df4,dfPrimary[i,])
                
                df5 = rbind(df5,dfSecondary[j,])
              }
              df5 = rbind(df5,dfSecondary[j+1,])
              pointer1 = i + 1
              duplicates_j = TRUE
            }
            else {
              df5 = rbind(df5,dfSecondary[j+1,])
            }                
            j = j + 1
            pointer1A = j + 1
          }
          else{
            flag = TRUE
            pointer2 = i
            pointer2A = j
            duplicates_i = FALSE
            duplicates_j = FALSE
            j = j + 1
            break
          }
          
          
        }
        else if (x[i] < y[j]){
          if(pointer2 >= pointer1){
            flag = FALSE
            if(nrow(df2) >= 1){
              df2 = bind_rows(df2,dfPrimary[pointer1:pointer2,])
            }
            else{
              df2 = rbind(df2,dfPrimary[pointer1:pointer2,])
            }
          }
          if(pointer2A >= pointer1A){
            flag = FALSE
            if(nrow(df3) >= 1){
              df3 = bind_rows(df3,dfSecondary[pointer1A:pointer2A,])
            }
            else{
              df3 = rbind(df3,dfSecondary[pointer1A:pointer2A,])
            }
          }
          pointer1 = i + 1
          pointer1A = j
          
          break
        }
        else{
          if(pointer2 >= pointer1){
            flag = FALSE
            if(nrow(df2) >= 1){
              df2 = bind_rows(df2,dfPrimary[pointer1:pointer2,])
            }
            else{
              df2 = rbind(df2,dfPrimary[pointer1:pointer2,])
            }
          }
          if(pointer2A >= pointer1A){
            flag = FALSE
            if(nrow(df3) >= 1){
              df3 = bind_rows(df3,dfSecondary[pointer1A:pointer2A,])
            }
            else{
              df3 = rbind(df3,dfSecondary[pointer1A:pointer2A,])
            }
          }
          pointer1 = i
          pointer1A = j + 1
          j = j + 1
        }
      }
      if(j >= nrow(dfSecondary) & i <= nrow(dfPrimary)){
        if(gtools::invalid(x[i]) & i == nrow(dfPrimary)){
          if (is.null(discrepancy) & gtools::invalid(x[i])){
            discrepancy = i
          }
          flag = FALSE
          break
        }
      }
    }
    
    if(pointer2 >= pointer1){
      if(nrow(df2) >= 1){
        df2 = bind_rows(df2,dfPrimary[pointer1:pointer2,])
      }
      else{
        df2 = rbind(df2,dfPrimary[pointer1:pointer2,])
      }
    }
    
    if(pointer2A >= pointer1A){
      if(nrow(df3) >= 1){
        df3 = bind_rows(df3,dfSecondary[pointer1A:pointer2A,])
      }
      else{
        df3 = rbind(df3,dfSecondary[pointer1A:pointer2A,])
      }
    }
    
    folderName <-paste("reconResult",input$title) 
    
      
      if(nrow(df2) <= 1048575){
        #write_xlsx(df2,file)
        dir.create(folderName)

        write_xlsx(df2,"Matched_Primary.xlsx")
        write_xlsx(df3,"Matched_Secondary.xlsx")
        write_xlsx(df4,"Duplicates_Primary.xlsx")
        write_xlsx(df5,"Duplicates_Secondary.xlsx")
        
        file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)

        
      }
      else if (nrow(df2) <= 2097150){
        dir.create(folderName)

        dfa <- df2[1:1048575,]
        dfb <- df2[1048576:nrow(df2),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Matched_Primary.xlsx")
        
        dfa <- df3[1:1048575,]
        dfb <- df3[1048576:nrow(df3),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Matched_Secondary.xlsx")
        
        dfa <- df4[1:1048575,]
        dfb <- df4[1048576:nrow(df4),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Duplicates_Primary.xlsx")
        
        dfa <- df5[1:1048575,]
        dfb <- df5[1048576:nrow(df5),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Duplicates_Secondary.xlsx")
        
        file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
        

      }
      else if (nrow(df2) <= 3145725){
        dir.create(folderName)

        dfa <- df2[1:1048575,]
        dfb <- df2[1048576:2097150,]
        dfc <- df2[2097151:nrow(df2),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc) #assume sheet1 and sheet2 are data frames
        
        write_xlsx(sheets,"Matched_Primary.xlsx")
        
        dfa <- df3[1:1048575,]
        dfb <- df3[1048576:2097150,]
        dfc <- df3[2097151:nrow(df3),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Matched_Secondary.xlsx")
        
        dfa <- df4[1:1048575,]
        dfb <- df4[1048576:2097150,]
        dfc <- df4[2097151:nrow(df4),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Duplicates_Primary.xlsx")
        
        dfa <- df5[1:1048575,]
        dfb <- df5[1048576:2097150,]
        dfc <- df5[2097151:nrow(df5),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Duplicates_Secondary.xlsx")
        
        
        file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
        
      }
      else if (nrow(df2) <= 4194301){
        dir.create(folderName)

        dfa <- df2[1:1048575,]
        dfb <- df2[1048576:2097150,]
        dfc <- df2[2097151:3145725,]
        dfd <- df2[3145726:nrow(df2),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Matched_Primary.xlsx")
        
        dfa <- df3[1:1048575,]
        dfb <- df3[1048576:2097150,]
        dfc <- df3[2097151:3145725,]
        dfd <- df3[3145726:nrow(df3),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Matched_Secondary.xlsx")
        
        dfa <- df4[1:1048575,]
        dfb <- df4[1048576:2097150,]
        dfc <- df4[2097151:3145725,]
        dfd <- df4[3145726:nrow(df4),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Duplicates_Primary.xlsx")
        
        dfa <- df5[1:1048575,]
        dfb <- df5[1048576:2097150,]
        dfc <- df5[2097151:3145725,]
        dfd <- df5[3145726:nrow(df5),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Duplicates_Secondary.xlsx")
        
        file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
        

      }
      else if (nrow(df2) <= 5242877){
        dir.create(folderName)

        dfa <- df2[1:1048575,]
        dfb <- df2[1048576:2097150,]
        dfc <- df2[2097151:3145725,]
        dfd <- df2[3145726:4194301,]
        dfe <- df2[4194302:nrow(df2),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd,"Sheet5" = dfe) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Matched_Primary.xlsx")
        
        dfa <- df3[1:1048575,]
        dfb <- df3[1048576:2097150,]
        dfc <- df3[2097151:3145725,]
        dfd <- df3[3145726:4194301,]
        dfe <- df3[4194302:nrow(df3),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd,"Sheet5" = dfe) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Matched_Secondary.xlsx")
        
        dfa <- df4[1:1048575,]
        dfb <- df4[1048576:2097150,]
        dfc <- df4[2097151:3145725,]
        dfd <- df4[3145726:4194301,]
        dfe <- df4[4194302:nrow(df4),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd,"Sheet5" = dfe) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Duplicates_Primary.xlsx")
        
        dfa <- df5[1:1048575,]
        dfb <- df5[1048576:2097150,]
        dfc <- df5[2097151:3145725,]
        dfd <- df5[3145726:4194301,]
        dfe <- df5[4194302:nrow(df5),]
        sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd,"Sheet5" = dfe) #assume sheet1 and sheet2 are data frames
        write_xlsx(sheets,"Duplicates_Secondary.xlsx")
        
        file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
        file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
        
      }
      else{
        validate(
          need(nrow(df2)<= 5242877,'THERE ARE TOO MANY FILES/FILES TOO LARGE')
        )
      }

    
  
    # output$downloadOuput3 <- downloadHandler( filename = function(){
    #   #paste("Matched_Primary", input$title, Sys.Date(), ".xlsx", sep="")
    #   paste("output", input$title, Sys.Date(), ".tgz", sep="")
    # },
    # 
    # content = function(file){
    #   if(nrow(df2) <= 1048575){
    #     #write_xlsx(df2,file)
    #     dir.create(folderName)
    #     filesZip <- dir(folderName,full.names = TRUE)
    #     
    #     write_xlsx(df2,"Matched_Primary.xlsx")
    #     write_xlsx(df3,"Matched_Secondary.xlsx")
    #     write_xlsx(df4,"Duplicates_Primary.xlsx")
    #     write_xlsx(df5,"Duplicates_Secondary.xlsx")
    #     
    #     file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
    #     
    #     tar(file,folderName,compression = 'gzip')
    #     
    #   }
    #   else if (nrow(df2) <= 2097150){
    #     dir.create(folderName)
    #     filesZip <- dir(folderName,full.names = TRUE)
    #     
    #     dfa <- df2[1:1048575,]
    #     dfb <- df2[1048576:nrow(df2),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Matched_Primary.xlsx")
    #     
    #     dfa <- df3[1:1048575,]
    #     dfb <- df3[1048576:nrow(df3),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Matched_Secondary.xlsx")
    #     
    #     dfa <- df4[1:1048575,]
    #     dfb <- df4[1048576:nrow(df4),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Duplicates_Primary.xlsx")
    #     
    #     dfa <- df5[1:1048575,]
    #     dfb <- df5[1048576:nrow(df5),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Duplicates_Secondary.xlsx")
    #     
    #     file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
    #     
    #     tar(file,folderName,compression = 'gzip')
    #     
    #   }
    #   else if (nrow(df2) <= 3145725){
    #     dir.create(folderName)
    #     filesZip <- dir(folderName,full.names = TRUE)
    #     
    #     dfa <- df2[1:1048575,]
    #     dfb <- df2[1048576:2097150,]
    #     dfc <- df2[2097151:nrow(df2),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc) #assume sheet1 and sheet2 are data frames
    #     
    #     write_xlsx(sheets,"Matched_Primary.xlsx")
    #     
    #     dfa <- df3[1:1048575,]
    #     dfb <- df3[1048576:2097150,]
    #     dfc <- df3[2097151:nrow(df3),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Matched_Secondary.xlsx")
    #     
    #     dfa <- df4[1:1048575,]
    #     dfb <- df4[1048576:2097150,]
    #     dfc <- df4[2097151:nrow(df4),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Duplicates_Primary.xlsx")
    #     
    #     dfa <- df5[1:1048575,]
    #     dfb <- df5[1048576:2097150,]
    #     dfc <- df5[2097151:nrow(df5),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Duplicates_Secondary.xlsx")
    #     
    #     
    #     file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
    #     
    #     tar(file,folderName,compression = 'gzip')
    #   }
    #   else if (nrow(df2) <= 4194301){
    #     dir.create(folderName)
    #     filesZip <- dir(folderName,full.names = TRUE)
    #     
    #     dfa <- df2[1:1048575,]
    #     dfb <- df2[1048576:2097150,]
    #     dfc <- df2[2097151:3145725,]
    #     dfd <- df2[3145726:nrow(df2),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Matched_Primary.xlsx")
    #     
    #     dfa <- df3[1:1048575,]
    #     dfb <- df3[1048576:2097150,]
    #     dfc <- df3[2097151:3145725,]
    #     dfd <- df3[3145726:nrow(df3),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Matched_Secondary.xlsx")
    #     
    #     dfa <- df4[1:1048575,]
    #     dfb <- df4[1048576:2097150,]
    #     dfc <- df4[2097151:3145725,]
    #     dfd <- df4[3145726:nrow(df4),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Duplicates_Primary.xlsx")
    #     
    #     dfa <- df5[1:1048575,]
    #     dfb <- df5[1048576:2097150,]
    #     dfc <- df5[2097151:3145725,]
    #     dfd <- df5[3145726:nrow(df5),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Duplicates_Secondary.xlsx")
    #     
    #     file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
    #     
    #     tar(file,folderName,compression = 'gzip')
    #     
    #   }
    #   else if (nrow(df2) <= 5242877){
    #     dir.create(folderName)
    #     filesZip <- dir(folderName,full.names = TRUE)
    #     
    #     dfa <- df2[1:1048575,]
    #     dfb <- df2[1048576:2097150,]
    #     dfc <- df2[2097151:3145725,]
    #     dfd <- df2[3145726:4194301,]
    #     dfe <- df2[4194302:nrow(df2),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd,"Sheet5" = dfe) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Matched_Primary.xlsx")
    #     
    #     dfa <- df3[1:1048575,]
    #     dfb <- df3[1048576:2097150,]
    #     dfc <- df3[2097151:3145725,]
    #     dfd <- df3[3145726:4194301,]
    #     dfe <- df3[4194302:nrow(df3),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd,"Sheet5" = dfe) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Matched_Secondary.xlsx")
    #     
    #     dfa <- df4[1:1048575,]
    #     dfb <- df4[1048576:2097150,]
    #     dfc <- df4[2097151:3145725,]
    #     dfd <- df4[3145726:4194301,]
    #     dfe <- df4[4194302:nrow(df4),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd,"Sheet5" = dfe) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Duplicates_Primary.xlsx")
    #     
    #     dfa <- df5[1:1048575,]
    #     dfb <- df5[1048576:2097150,]
    #     dfc <- df5[2097151:3145725,]
    #     dfd <- df5[3145726:4194301,]
    #     dfe <- df5[4194302:nrow(df5),]
    #     sheets <- list("Sheet1" = dfa, "Sheet2" = dfb, "Sheet3" = dfc,"Sheet4" = dfd,"Sheet5" = dfe) #assume sheet1 and sheet2 are data frames
    #     write_xlsx(sheets,"Duplicates_Secondary.xlsx")
    #     
    #     file.move("Matched_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Matched_Secondary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Primary.xlsx",folderName,overwrite = TRUE)
    #     file.move("Duplicates_Secondary.xlsx",folderName,overwrite = TRUE)
    #     
    #     tar(file,folderName,compression = 'gzip')
    #   }
    #   else{
    #     validate(
    #       need(nrow(df2)<= 5242877,'THERE ARE TOO MANY FILES/FILES TOO LARGE')
    #     )
    #   }
    # })
    
    
    end <- Sys.time()
    time$timetaken <- difftime(end, begin, units='mins')
    time$timetaken <- format(round(time$timetaken, 2), nsmall = 2)
    no_data_compared$count <- i
    no_row_null$count <- nrow(dfPrimary) - discrepancy + 1
    
  })
  

  
  
  output$timetaken <- renderUI({
    "Time taken: "
    
  })
  
  output$time <- renderUI({
    time$timetaken
    
  })

  output$no_data <- renderUI({
    "Number of data compared: "
  })
  
  output$data <- renderUI({
    no_data_compared$count    
  })
  
  output$no_null <- renderUI({
    "Number of rows not found (discrepancy): "
  })
  
  output$null <- renderUI({
    if(gtools::invalid(no_row_null$count)){
      no_row_null$count = 0
    }
    no_row_null$count
  })
  

  
  output$text1 <- renderUI({
    comparingPrimary()

  })
  
  output$text2 <- renderUI({
    comparingSecondary()

  })
  
  output$text3 <- renderUI({
    comparingMatchedPrimary()
  })
  
}

### CREATE SHINY OBJECT ###
shinyApp(ui = ui, server = server)