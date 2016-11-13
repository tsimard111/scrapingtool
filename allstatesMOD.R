##I'm sorry that the following code is not reproducible. I need to leave out the URL that I used. Nevertheless, I hope it's helpful to see how a scraper can be constructed.
##Load required packages
require("rvest") 
require("XML")
require("xlsx")
require("magrittr")

##The following code loops through webpages for each of the US states, extracting selected elements. The method used here is to replace the text in the URL based on known structure of those URLs. This may not be the best solution in your case. In some cases, you may be able to cycle through a list of urls contained in a sitemap/main menu like this:
       ##urls <- read_html("https://www.SITEMAP") %>%
       ##html_nodes("#block-system-main a[href]") %>%
       ##html_attr("href")
       ##for (i in urls) {...
##In other cases, neither of these methods may work. One thing you could consider is using the method just mentioned, then extracting the urls from each of THOSE pages. You would want to put in safegards to avoid redundancy and to avoid leaving the domain you want to look at, but that should allow you to spider through the entire website. Sorry, I haven't actually written something that does that, but it seems easy enough to extend to that.

##Creates variables for loops. 
states <- c("AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DC", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY")
##Each of the states has pages with 50 results each, and the highest number of results for a state is under 2500.
pages <-seq(from=50,to=2500, by=50)
##Creates empty data frames for storing loop results
namesall <-data.frame()
statesall <- data.frame()
citiesall <- data.frame()
locationsall <- data.frame()
startdateall <- data.frame()
enddateall <- data.frame()
namesall2 <-data.frame()
statesall2 <- data.frame()
citiesall2 <- data.frame()
locationsall2 <- data.frame()
startdateall2 <- data.frame()
enddateall2 <- data.frame()
##Loop for pulling desired elements by state
for(i in states) {
## This line has left out the acutual url to protect their data and to avoid potentially overwhelming their server with queries. The paste command is inserting the state name into the URL.
html <- read_html(paste0("http://DIRECTORYGOESHERE/index.php?State_local=",i,collapse = ""))
##The following lines use rvest to extract the nodes I want, convert to text, make into data frame, and bind to the results of the previous loops. Following Hadley Wickam's suggestion, I started by using Chrome's "SelectorGadget" to get CSS elements, but ran into some major limitations of that tool. For example, metadata that is not visible on the page can not be selected using that tool. It also has problems if there are hidden tabs in a page because it can't unselect items from the hidden tabs. Finally, it's worth noting that this method of using CSS selectors is only going to work if the pages are structured in an orderly way. If not, you'll probably need to do more complex text mining.
names<- html_nodes(html,".event-name[itemprop=name]") %>%
                     html_text %>%
                     data.frame(row.names=NULL)
namesall <- rbind(namesall,names)
states <- html_nodes(html,".event-location span span+ span") %>%
                     html_text %>%
                     data.frame
statesall <- rbind(statesall,states)
cities <- html_nodes(html,".event-location span span:nth-child(1)") %>%
                     html_text %>%
                     data.frame
citiesall <- rbind(citiesall,cities)
locations <- html_nodes(html,".event-location > span:nth-child(1)") %>%
                     html_text %>%
                     data.frame
locationsall <- rbind(locationsall,locations)
startdate <- html_nodes(html,"meta[itemprop=startDate]") %>% 
                     html_attrs %>% 
                     data.frame %>%
                     t %>% 
                     subset(select="content") %>% 
                     data.frame(row.names=NULL)
startdateall <- rbind(startdateall,startdate)
enddate <- html_nodes(html,"meta[itemprop=endDate]") %>%
                     html_attrs %>%
                     data.frame %>%
                     t %>%
                     subset(select="content") %>%
                     data.frame(row.names=NULL)
enddateall <- rbind(enddateall,enddate)
##Now that this has been done for the first pages of each of the states. There is a second loop for cycling through additional pages of results. The way the loop is written is very similar to the state loop, but using the page results in the url.
for (p in pages){
##This error catching is required because not all states have the same number of pages. More careful error catching may be recommended if there's an expectation that other things may go wrong.
       tryCatch({
##Again, I've left out the actual URL
htmlpage2 <- read_html(paste0("http://DIRECTORYGOESHERE/index.php?State_local=",i,"&back_link=http%3A%2F%2Findexes.html&start=",p,collapse = ""))
names2 <- html_nodes(htmlpage2,".event-name[itemprop=name]") %>%
       html_text %>%
       data.frame(row.names=NULL)
namesall2 <- rbind(namesall2, names2)
states2 <- html_nodes(htmlpage2,".event-location span span+ span") %>%
       html_text %>%
       data.frame
statesall2 <- rbind(statesall2, states2)
cities2 <- html_nodes(htmlpage2,".event-location span span:nth-child(1)") %>%
       html_text %>%
       data.frame
citiesall2 <- rbind(citiesall2, cities2)
locations2 <- html_nodes(htmlpage2,".event-location > span:nth-child(1)") %>%
       html_text %>%
       data.frame
locationsall2 <- rbind(locationsall2, locations2)
startdate2 <- html_nodes(htmlpage2,"meta[itemprop=startDate]") %>% 
       html_attrs %>% 
       data.frame %>%
       t %>% 
       subset(select="content") %>% 
       data.frame(row.names=NULL)
startdateall2 <- rbind(startdateall2, startdate2)
enddate2 <- html_nodes(htmlpage2,"meta[itemprop=endDate]") %>%
       html_attrs %>%
       data.frame %>%
       t %>%
       subset(select="content") %>%
       data.frame(row.names=NULL)
enddateall2 <- rbind(enddateall2, enddate2)},
        error=function(e){})
}
}
##Closing section binds the data together, names the columns, removes duplicates, and saves to an excel file.
tot <- cbind(namesall,statesall,citiesall,locationsall,startdateall,enddateall)
tot2 <- cbind(namesall2,statesall2,citiesall2,locationsall2,startdateall2,enddateall2)
colnames(tot)<-c("name","state","location","city","startdate","enddate")
colnames(tot2)<-c("name","state","location","city","startdate","enddate")
allstates <- unique(rbind(tot,tot2))
write.xlsx(x = allstates, file = "scrape.xlsx", sheetName = "rdata", row.names = FALSE)