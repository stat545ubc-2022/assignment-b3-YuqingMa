library(shiny)
library(ggplot2)
library(tidyr)
#This is an app made for users to conveniently view students' grades distribution 
#and mean value.

#Feature1:Allow users to select class they'd like to view the students' average score
#and store distribution

#Feature2:Allow users to select the subject they'd like to view the students' average score
#and store distribution


set.seed(0814)
data <- data.frame(
  ID = rep(1:300, 5),
  class = rep(1:3, 500),
  subject = rep(c("Chinese", "Math", "English", 
                  "Physics", "Histroy"), each = 300),
  grade = as.integer(runif(500, 30, 100))
)

data <- spread(data, key = "subject", value = "grade")

ui <- fluidPage(
  img(src="d.jpg",height="200px",width="100%"),
  
  titlePanel("Class Score"),
  
  sidebarLayout(
    
    sidebarPanel(
      selectInput(
        inputId = "class",
        label = "class",
        choices = c("class 1" = 1, "class 2" = 2, "class 3" = 3),
        selected = "class 1"
      ),
      
      checkboxGroupInput(
        inputId = "subject", 
        label = "subject",
        choices = c("Chinese" = "Chinese", "Math" = "Math", "English" = "English",
                    "Physics" = "Physics", "History" = "Histroy"),
        selected = c("Chinese", "English")
      )
    ),
   
    mainPanel(
      
      plotOutput(outputId = "plot")
    )
  )
)
  

server <- function(input, output) {
  
  output$plot <- renderPlot({
    data0 <- data[data$class == input$class, ]
    
    ggplot(data0, aes_string(x = input$subject[1], 
                             y = input$subject[2])) +
      geom_point() +
      geom_smooth(method = "lm") +
      theme_bw() 
  })
}



shinyApp(ui = ui, server = server)