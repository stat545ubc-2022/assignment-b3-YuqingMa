library(shiny)
library(dplyr)
library(ggplot2)

#---------------------CSV---------------------
data<-read.csv(file="https://covid-19.nchc.org.tw/api/csv?CK=covid-19@nchc.org.tw&querydata=4051&limited=TWN",header=TRUE,sep=",",fileEncoding = "big5")

data<-data[,c(5:7,9)] 
names(data)<-list("Date","Total","Num","Per")

data$Date<-as.Date(data$Date)
#place to store average values
data$week_avg<-array(NA,nrow(data))
data$month_avg<-array(NA,nrow(data))
data$month<-format(data$Date,format="%m")
#calculate the average values
for(i in 7:nrow(data)){
  data$week_avg[i]<-mean(data$Num[(i-7+1):i])
}
for(i in 30:nrow(data)){
  data$month_avg[i]<-mean(data$Num[(i-30+1):i])
}

options(scipen = 999)

ui <- fluidPage(
  
  titlePanel("Recent Covid-19 Cases Panel"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("date_range",
                  "Select the date range you would like to view:",
                  min = as.Date("2022-01-01"),
                  max = data$Date[nrow(data)],
                  value=c(as.Date("2022-09-01"),data$Date[nrow(data)]),
                  timeFormat="%Y-%m-%d"),
      
      radioButtons("cycle","select the days for calculating the average cases",list("7 days"="week_avg","30 days"="month_avg"),"week_avg"),
      selectInput("switch","select data type",list("Daily confirmed cases"="Days","total confirmed cases"="Total","confirmed cases per million"="Per"),"Days"),
      tags$b("data sourse：",tags$br(),tags$a("COVID-19 Global Epidemic Map",href="https://covid-19.nchc.org.tw/index.php"))
    ),
    mainPanel(
      tabsetPanel(id="tabset",type="hidden",
                  
                  tabPanel(
                    "Days",
                    tags$h3(tags$b("Daily confirmed cases and average cases")),
                    plotOutput("day_plot",brush = "plot_brush"),
                    tags$b("The table displays the data for the date selected",style="color:blue"),
                    dataTableOutput("day_table"),
                  ),
                  
                  tabPanel(
                    "Total",
                    tags$h3(tags$b("　　2022 new and accumulated confirmed cases")),
                    plotOutput("total_plot",click = "plot_click"),
                    tags$b("The table shows the number of days around where the mouse clicked",style="color:blue"),
                    dataTableOutput("total_table"),
                  ),
                  
                  tabPanel(
                    "Per",
                    tags$h3(tags$b("　　confirmed cases per million")),
                    plotOutput("per_plot"),
                    tags$b("Till this time",data$Date[nrow(data)],"confirmed cases per million is",tags$em(data$Per[nrow(data)]),"people (",round(data$Per[nrow(data)]/10000,3),"% )"),
                    
                    plotOutput("per_pie")
                  )
      )
      
    )
  )
)

server <- function(input, output, session) {
  
  #data select range
  data_subset <- reactive(
    data %>% filter(Date >= input$date_range[1] & Date <= input$date_range[2])
  )
  
  #---------------------Day---------------------
  output$day_plot<-renderPlot(
    ggplot(data_subset())+
      geom_bar(aes(Date,Num,fill=month), stat = "identity")+
      geom_line(aes_string("Date",input$cycle),color="blue")+
      scale_x_date(date_labels = "%b",date_breaks = "1 month")+
      labs(x=NULL,y="confirmed cases",fill="month")+
      theme(panel.background = element_rect(fill="#faebd7")) 
  )
  #earliest date
  min_date<-reactive(
    if(is.null(input$plot_brush[[1]])){
      input$date_range[1]
    }else{
      round(max(input$date_range[1],input$plot_brush[[1]]),0)
    }
  )
  #latest date
  max_date<-reactive(
    if(is.null(input$plot_brush[[2]])){
      input$date_range[2]
    }else{
      round(min(input$date_range[2],input$plot_brush[[2]]),0)
    }
  )
  
  output$day_table<-renderDataTable(
    data2<-data %>% filter(Date >= min_date() & Date <= max_date()) %>% select("Date"=Date,"Newly confirmed cases"=Num,"7 days average"=week_avg,"30 days average"=month_avg),
    options=list(pageLength=10,searching = FALSE)
  )
  #---------------------Total---------------------
  
  output$total_plot<-renderPlot(
    ggplot(data_subset())+
      geom_bar(aes(Date,Num,fill=month), stat = "identity")+
      geom_density(aes(Date,Total/100), stat = "identity",color="blue",fill="blue",alpha=0.1)+
      scale_x_date(date_labels = "%b",date_breaks = "1 month")+
      scale_y_continuous(name="daily confirmed cases",
                         sec.axis = sec_axis(~.*100/10000, name="total confirmed cases(per million)"))+
      labs(x=NULL,fill="month")+
      theme(panel.background = element_rect(fill="#faebd7"))
  )
  
  date_click<-reactive(
    if(is.null(input$plot_click[[1]])){
      input$date_range[2]
    }else{
      round(input$plot_click[[1]],0)
    }
  )
  
  output$total_table<-renderDataTable(
    data %>% filter(Date >= date_click()-3 & Date <= date_click()+3 & Date >= min_date()) %>% select("Date"=Date,"newly confirmed cases"=Num,"total cases"=Total),
    options=list(pageLength = 1,paging=FALSE,searching = FALSE)
  )
  #---------------------Per Million---------------------
  output$per_plot<-renderPlot(
    ggplot(data_subset())+
      geom_density(aes(Date,Per/10000),stat = "identity",color="blue",fill="blue",alpha=0.1)+
      scale_x_date(date_labels = "%b",date_breaks = "1 month")+
      ylim(0,100)+
      labs(x=NULL,y="confirmed cases per million(unit:10000)")+
      theme(panel.background = element_rect(fill="#faebd7"))
  )
  
  output$per_pie<-renderPlot(
    data.frame(type=c("unconfirmed","confirmed"),num=c(1000000-data$Per[nrow(data)],data$Per[nrow(data)])) %>%
      ggplot(aes("",num,fill=type))+
      geom_bar(stat="identity",width=1)+
      coord_polar(theta="y",start=0)+
      labs(x=NULL, y=NULL,fill=NULL)
  )
  #---------------------Select---------------------
  
  observeEvent(input$switch,{
    updateTabsetPanel(inputId ="tabset",selected =input$switch)
  })
}

shinyApp(ui, server)
