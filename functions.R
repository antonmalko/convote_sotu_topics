require(plyr)
require(dplyr) # should be loaded after plyr
require(tidyr)
require(ggplot2)
require(XML)

###############################
## Functions    ###############
###############################


run.mallet <- function(dirs, n.topics, n.chains, n.iters,
                       mallet.seed,
                       produce.output = FALSE ){
  mallet.output <- list()
  
  for (i in 1:n.chains){  
    # if we want to write some files out...
    if (produce.output == TRUE){
      # set file names for output of model, extensions must be as shown
      output.state <-     paste("topic-state", n.topics, "gz", sep = ".")
      output.topic.keys <- paste("output_keys", n.topics, "txt", sep = ".")
      output.doc.topics <- paste("output_composition", n.topics, "txt", sep = ".")
      diagnostics <-     paste("diagnostics", n.topics, "xml", sep = ".")
      
      # combine variables into strings to pass them to command line
      mallet.call  <- paste("train-topics",
                            " --input", file.path(shQuote(dirs$data),
                                                  dirs$topic.trainer.input),
                            "--num-topics", n.topics,
                            "--num-iterations", n.iters,
                            "--random-seed", mallet.seed[i],
                            "--output-state", output.state,
                            "--output-topic-keys", output.topic.keys,
                            "--output-doc-topics", output.doc.topics,
                            "--diagnostics-file", diagnostics,
                            sep = " ")
    } else  { # if we just run the code to get log-likelihood values 
      mallet.call <- paste("train-topics",
                           "--input", file.path(shQuote(dirs$data),
                                                dirs$topic.trainer.input),
                           "--num-topics", n.topics,
                           "--num-iterations", n.iters,
                           "--random-seed", mallet.seed[i],
                           sep = " ")
    }
    
    # call mallet and collect console output
    cat("Running chain", i, "out of", n.chains, "for model with",
        n.topics, "topics\n")
    mallet.output[[i]] <- system2(command = dirs$mallet,
                                  args = mallet.call,
                                  stdout = TRUE, stderr = TRUE)
    
  }
  
  out <- extract.LL(mallet.output)
  # rename columns for convenience
  colnames(out) <- 1:n.chains
  # create a column with n of topics for plotting the results later
  out$n.topics <- n.topics
  
  return(out)
}  

extract.LL <- function(mallet.output){
  # extract LogLikelihoods from a set of sampler runs. Assumes that
  # the input is a list, with entries corresponding to different
  # chains (for the same number of topics), and values are mallet
  # console output
  
  # gets the LL from the last iteration
  LL <- ldply(mallet.output,
              function(x) {
                # for each run (corresponding to the number of topics),
                # take the third line from the bottom (the last line indicates
                # mallet time to convergence, the second last line is empty,
                # the third last line is what we need: log-likelihood at the
                # final iteration)
                tmp <- x[length(x)-2]
                
                # make sure that the decimal separator is "." - otherwise
                # R will fail to convert character to numeric
                tmp <- sub(",",".", tmp)
                
                # split the line by the whitespace and take the last field - 
                # this will be the value of log-likelihood
                tmp <- as.numeric(strsplit(tmp, " ")[[1]][[3]])
              })
  # trasnpose the results, so that the columns correspond to number of topics in the
  # model, and rows - to LL-values for different runs of the sampler
  LL <- t(LL)
  return(data.frame(LL))
}

parse.xml <- function(xml.file){
  
  getWord <- function(wordNode){
    attrs <- xmlAttrs(wordNode)
    w <- xmlValue(wordNode)
    t(data.frame(c(w,attrs)))
  }
  
  xml.contents <- xmlTreeParse(xml.file)
  
  # Get words and their attributes
  words <- xmlApply(xmlRoot(xml.contents),
                    function(topic){
                      xmlApply(topic, getWord)
                    })
  
  # words are a list of lists. First bind all the entries
  # from one topic together
  tmp <- list()
  for (t in 1:length(words)){
    tmp[[t]] <- do.call(rbind, words[[t]])
    tmp[[t]] <- data.frame(tmp[[t]])
    tmp[[t]]$topic.id <- t
  }
  
  # next, bind the topics together
  result <- do.call(rbind, tmp)
  colnames(result)[1] <- "words"
  
  result$prob <- as.numeric(as.character(result$prob))
  result$log.prob <- log(result$prob)
  return(result)
}

plot.topics <- function(words.data, size.multiplier){
  # plots are made for 5 topics per time. figure out how many
  # groups of 5 we need
  n.topics <- length(unique(words.data$topic.id))
  chunks <- split(1:n.topics, ceiling(seq_along(1:n.topics)/5))
  
  result <- list()
  
  
  for (chunk in 1:length(chunks)){
    
    plot.data <- words.data[words.data$topic.id %in% chunks[[chunk]],]
    result[[chunk]] <- ggplot(plot.data, aes(x = factor(topic.id), y = log.prob)) +
      geom_text(aes(label = words),
                size = size.multiplier*sqrt(plot.data$prob), position = "stack")+
      ggtitle(paste("Words for model with", n.topics, "topics. Chunk", chunk,
                    "out of", length(chunks)))+
      ylab("")+
      xlab("Topic") +
      scale_y_continuous(breaks=NULL)
  }
  
  return(result)
}
