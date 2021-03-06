## Copyright 2015,2016,2017,2018,2019 Institut National de la Recherche Agronomique
## and Montpellier SupAgro.
##
## This file is part of PlantBreedGame.
##
## PlantBreedGame is free software: you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## PlantBreedGame is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public
## License along with PlantBreedGame.  If not, see
## <http://www.gnu.org/licenses/>.


## Function
source("src/func_eval.R", local=TRUE, encoding="UTF-8")$value



###### server for "genotyping" ######

## Main UI ----
output$evalUI <- renderUI({
  if (breeder()!="No Identification" & breederStatus()!="player"){
    source("src/ui_eval_loggedIn.R", local=TRUE, encoding="UTF-8")$value
  }else{
    shinydashboard::box(width=12, title = "Content unavailable",
                                div(p("Sorry, you need the 'game-master' status or the 'tester' status to access this."))
    )
  }
})




## read uploaded file ----
readQryEval <- reactive({

  # no input fileI
  if(is.null(input$file.eval)){
    return(NULL)
  }

  # read input file
  df <- try(readCheckEvalFile(input$file.eval$datapath))

  if (is.data.frame(df)){
    # add controls in the data.frame
    df.controls <- read.table(paste0(setup$init.dir, "/controls.txt"), col.names="ind")
    df.controls$breeder <- rep("control", length(df.controls))
    df <- rbind(df, df.controls)
    return(df)

  }else {return("error - wrong file format")}

})


dfPhenoEval <- eventReactive(input$requestEval,{
  dfPheno <- phenotype4Eval(readQryEval(), nRep=input$nRep)
  dfPheno$breeder <- sapply(as.character(dfPheno$ind), FUN = function(x){strsplit(x,split = "_")[[1]][1]})
  return(dfPheno)
})



## graph ----
output$evalGraphT1 <- renderPlotly({
  dfPheno <- dfPhenoEval()
  breederOrder <- c(unique(as.character(dfPheno$ind[dfPheno$breeder=="control"])),
                    unique(as.character(dfPheno$ind[dfPheno$breeder!="control"])))

  target <- median(dfPheno$trait1[dfPheno$breeder=="control"])*constants$register.min.trait1


  ## Plot
  m <- list(
    l = 40,
    r = 80,
    b = 80,
    t = 50,
    pad = 0
  )


  p <- plot_ly(data=dfPheno,
               type = 'box',
               y = ~trait1,
               x= ~ind,
               color = ~breeder,
               colors = mycolors) %>%
      layout(title = "Phenotypic values of trait 1",
             xaxis = list(title = "",
                          categoryorder = "array",
                          categoryarray = breederOrder
                          ),
             yaxis = list(title = ""),
             autosize = T,
             margin = m) %>%
      add_lines(data=NULL,
                type='scatter',
                y=target,
                mode='lines',
                color = "Target")


})
output$evalGraphT2 <- renderPlotly({
  dfPheno <- dfPhenoEval()
  breederOrder <- c(unique(as.character(dfPheno$ind[dfPheno$breeder=="control"])),
                    unique(as.character(dfPheno$ind[dfPheno$breeder!="control"])))

  target <- constants$register.min.trait2


  ## Plot
  m <- list(
    l = 40,
    r = 80,
    b = 80,
    t = 50,
    pad = 0
  )

  p <- plot_ly(data=dfPheno,
               type = 'box',
               y = ~trait2,
               x= ~ind,
               color = ~breeder,
               colors = mycolors) %>%
    add_lines(data=NULL,
              type='scatter',
              y=target,
              mode='lines',
              color = "Target")%>%
    layout(title = "Phenotypic values of trait 2",
           xaxis = list(title = "",
                        categoryorder = "array",
                        categoryarray = breederOrder),
           yaxis = list(title = ""),
           autosize = T,
           margin = m)


})




output$evalGraphT3 <- renderPlotly({
  dfPhenoPatho <- dfPhenoEval()
  dfPhenoPatho <- dfPhenoPatho[(as.numeric(dfPhenoPatho$plot) %% input$nRep) == 1,]

  breederOrder <- c(unique(as.character(dfPhenoPatho$ind[dfPhenoPatho$breeder=="control"])),
                    unique(as.character(dfPhenoPatho$ind[dfPhenoPatho$breeder!="control"])))


  ## Plot
  m <- list(
    l = 40,
    r = 80,
    b = 80,
    t = 50,
    pad = 0
  )


  p <- plot_ly(data=dfPhenoPatho,
               type = 'bar',
               y = ~trait3*2-1,
               x= ~ind,
               color = ~breeder,
               colors = mycolors) %>%
    layout(title = "Phenotypic values of trait 3",
           xaxis = list(title = "",
                        categoryorder = "array",
                        categoryarray = breederOrder),
           yaxis = list(title = ""),
           autosize = T,
           margin = m)

})




output$evalGraphT1vT2<- renderPlotly({
  dfPheno <- dfPhenoEval()
  dfPheno <- dfPheno[(as.numeric(dfPheno$plot) %% input$nRep) == 1,]

  # get the data for the initial collection
  f <- paste0(setup$truth.dir, "/", "p0.RData")
  load(f)
  dfInitColl <- data.frame(GAT1=p0$G.A[,1], GAT2=p0$G.A[,2], ind=names(p0$G.A[,2]))

  # linear regretion
  linMod <- lm(GAT2 ~ GAT1, data=dfInitColl)

  xLine <- c(min(dfInitColl$GAT1), max(dfInitColl$GAT1))
  yLine <- linMod$coefficients[1]+linMod$coefficients[2]*xLine


  p <- plot_ly(type = 'scatter',
               colors = mycolors) %>%
    add_markers(data=dfInitColl,
                type = 'scatter',
                y = ~GAT2,
                x= ~GAT1,
                color = "Initial Collection",
                marker=list(color="gray" , size=5 , opacity=0.5),
                text=~ind,
                inherit=FALSE) %>%
    add_lines(data=NULL,
              type='scatter',
              x=xLine,
              y=yLine,
              mode='lines',
              color = "Initial Collection",
              line=list(color="gray"),
              name="Linear regression",
              inherit=FALSE) %>%
    add_markers(data=dfPheno,
                type = 'scatter',
                y = ~GAT2,
                x= ~GAT1,
                marker=list(size=8, opacity=1),
                color=~breeder,
                text=~ind,
                inherit=FALSE) %>%
    layout(title = "Genotypic values of traits 1 vs 2",
           xaxis = list(title = "GA 1"),
           yaxis = list(title = "GA 2"))

})





output$evalUIAfsPlot <- renderUI({
  if (exists("dfPhenoEval")){
    breeders <- unique(dfPhenoEval()$breeder)
    breeders <- breeders[breeders!="control"]
    list(
      selectInput("afsBreeder","Breeder", choices=breeders),
      numericInput("propAFS", "Proportion of last individuals to take", 10, min = 1, max = 100),
      plotlyOutput("evalGraphAFsHist", height = "100%",width="100%") %>% withSpinner(),
      plotlyOutput("evalGraphAFsScatter", height = "100%",width="100%") %>% withSpinner())

  } else { p('no input')}

})

## AFs evaluation ----
afsEval <- reactive({


  # get parameters
  prop <- input$propAFS/100
  breeder <- input$afsBreeder
  f <- paste0(setup$truth.dir, "/afs0.RData")
  load(f) # afs0


  # get all individuals
  db <- dbConnect(SQLite(), dbname=setup$dbname)
  query <- paste0("SELECT * FROM plant_material_",breeder)
  res <- (dbGetQuery(conn=db, query))
  dbDisconnect(db)

  # select sample
  sampleSize <- round(nrow(res)*prop)
  selectedInd <- res[c((nrow(res)-sampleSize+1):nrow(res)), ]

  # calculate AFS
  progressAFS <- shiny::Progress$new(session, min=0, max=1)
  progressAFS$set(value = 0,
                  message = "Calculate AFs")
  afs1 <-  getAFs(selectedInd$child, breeder, progressAFS)

  dta <- data.frame(afs0=afs0, afs1=afs1)
  return(dta)
})


output$evalGraphAFsHist<- renderPlotly({


  # plot
  dta <- afsEval()
  dta$afs1[dta$afs1==1] <- 0.9995 # get better display
  dta$afs1[dta$afs1==0] <- 0.0005 # get better display


  p <- plot_ly(alpha=0.6, colors=c("gray", "#009933")) %>%
        add_histogram(data = dta,
                      x = ~afs0,
                      color = "1",
                      name = "initial AFs",
                      xbins = list("start"=0, "end"=1.05, "size"=0.05 ),
                      inherit = TRUE) %>%
        add_histogram(data = dta,
                      x = ~afs1,
                      color = "2",
                      name = "final AFs",#paste0("AFs ", input$afsBreeder),
                      xbins = list("start"=0, "end"=1.05, "size"=0.05 ),
                      inherit = TRUE) %>%
        layout(barmode = "overlay",
               title = input$afsBreeder,
               xaxis = list(title="allele frequencies"))

})

output$evalGraphAFsScatter<- renderPlotly({

  ids <- sample(row.names(afsEval()), 5000)
  dta <- afsEval()[ids,]
  p <- plot_ly(type = 'scatter') %>%
       add_markers(data=dta,
                type = 'scatter',
                y = ~afs1,
                x= ~afs0,
                marker=list(color="#009933" , size=5 , opacity=0.3),
                text="",
                inherit=FALSE) %>%
    layout(title = input$afsBreeder,
           xaxis = list(title="initial allele frequencies"),
           yaxis = list(title="final allele frequencies"))

})


## pedigree ----
output$evalUIpedigree <- renderUI({
  if (exists("dfPhenoEval")){
    breeders <- unique(dfPhenoEval()$breeder)
    breeders <- breeders[breeders!="control"]
    list(
      selectInput("pedigreeBreeder","Breeder", choices=breeders),
      div(
        plotOutput("evalPlotPedigree",width = "800px", height = "800px")
      )
      )

  } else { p('no input')}

})


genealogy <- reactive({

  # extract all individuals
  db <- dbConnect(SQLite(), dbname=setup$dbname)
  query <- paste0("SELECT * FROM plant_material_",input$pedigreeBreeder)
  allInds <- (dbGetQuery(conn=db, query))
  dbDisconnect(db)

  # get submitted individuals
  inds <- readQryEval()$ind[readQryEval()$breeder==input$pedigreeBreeder]
  subsetPedigree(allInds, inds)
})

output$evalPlotPedigree <- renderPlot({
  plotPedigree(genealogy()$child,
               genealogy()$parent1,
               genealogy()$parent2,
               genealogy()$generation,
               edge.col.mother = "black",
               edge.col.father = "black",
               vertex.label.color = "darkgreen",
               vertex.size = 15,
               main = input$pedigreeBreeder)
})




## Additive relationships ----
output$evalUIaddRelation <- renderUI({
    if (exists("dfPhenoEval")){
        breeders <- unique(dfPhenoEval()$breeder)
        breeders <- breeders[breeders!="control"]
        list(
            selectInput("addRelBreeder","Breeder", choices=breeders),
            tableOutput("addRelTable")
        )

    } else { p('no input')}

})

output$addRelTable <- renderTable({
    calcAdditiveRelation(breeder=input$addRelBreeder,
                         query = readQryEval(),
                         setup=setup,
                         constants = constants)

}, rownames = TRUE, spacing ="s", digits = 3)






## requests history ----
output$evalUIrequestHistory <- renderUI({
    if (exists("dfPhenoEval")){
        breeders <- unique(dfPhenoEval()$breeder)
        breeders <- breeders[breeders!="control"]
        list(
            selectInput("historyBreeder","Breeder", choices=breeders),
            dataTableOutput("historyTable")
        )

    } else { p('no input')}

})

output$historyTable <- renderDataTable({
    outTable <- getBreederHistory(breeder=input$historyBreeder,
                                  setup=setup)
    DT::datatable(outTable,
                  rownames = F,
                  filter = list(position = 'top', clear = TRUE, plain = TRUE),
                  options = list(pageLength = 25,
                                 lengthMenu = list(c(10, 25, 50, -1),
                                                   c(10, 25, 50, "All") ),
                                 scrollX = T,
                                 columns.searchable = T,
                                 order = list(c(3),c("dsc"))
                  ),
                  class = c("compact row-border"))
})


## debug ----
output$evalDebug <- renderPrint({
  print("---------")
  print(dfPhenoEval())


})

