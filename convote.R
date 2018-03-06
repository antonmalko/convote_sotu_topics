##########################
## Script params    ######
##########################

# dirs
dirs <- list()
# technically not a dir, but for convenience: mallet binary
dirs$mallet <- # path to Mallet binary (the binary itself, not just the folder containing it)
dirs$data <- # path to the working directory containing data
dirs$output <- file.path(dirs$data, "workdir")

if (!dir.exists(dirs$output)){
  dir.create(dirs$output)
}

# mallet

dirs$topic.trainer.input <- "convote_data.mallet"

# set list of topic numbers to iterate over
n.topics <- c(3, 5, 10, 25, 50, 100, 200, 300)

# number of chains for each topic
n.chains <- 10

# number of Gibbs sampler iterations for each chain
n.iters <- 500

# Seeds to replicate mallet.results. Should be a vector with length = n.chains,
# each element specifying the seed for a chain. 0 will correspond to
# random (mallet will use the clock)
mallet.seed <- c(1,20,67,89,45,980,567,340,267,109)

#######################
## Main       #########
#######################

setwd(dirs$data)
source("functions.R") # load functions to control Mallet and plot results

setwd(dirs$output)
results <- ldply(n.topics, function(n){
  run.mallet(dirs, n.topics = n, n.chains, n.iters, mallet.seed)
})

results$n.topics <- as.factor(results$n.topics)

# set position for error bars in the plot
dodge <- position_dodge(0.2)

plot.data <- results %>% 
  tidyr::gather(key = chain, value = LL, -n.topics) %>% # convert to long format
  group_by(n.topics) %>% # for each number of topics...
  summarize(meanLL = mean(LL), # calculate mean LL
            se_min = meanLL - sd(LL),
            se_max = meanLL + sd(LL)) # and standard deviation

LL.plot <- ggplot(plot.data) + # plot the values
  geom_bar(aes(x = n.topics, y = meanLL), stat = "identity", position = dodge) +
  geom_errorbar(aes(x = n.topics, ymin = se_min, ymax = se_max), position = dodge)+
  ggtitle(paste("Mean Log-likelihood values averaged over
                ",
                n.chains, "iterations of each model")) +
  coord_cartesian(ylim = c(-8, -9)) + 
  scale_y_reverse()

# ============================
# Look at specific models

# Figure out which run gave us the best log likelihood and then
# use the seed from that run
best.seeds <- results %>%
tidyr::gather(key = iter, value = LL, -n.topics) %>%
group_by(n.topics) %>%
filter(LL == max(LL))
best.seeds$seed <- mallet.seed[as.numeric(best.seeds$iter)]

# convert factor to numeric
best.seeds$n.topics <- as.numeric(as.character(best.seeds$n.topics))
best.seeds$iter <- as.numeric(best.seeds$iter)

# run mallet and save output
for (i in n.topics){
run.mallet(dirs = dirs,
           n.topics = best.seeds[best.seeds$n.topics == i,"n.topics"][[1]],
           n.chains = 1,
           n.iters = n.iters,
           mallet.seed = best.seeds[best.seeds$n.topics == i,"seed"][[1]],
           produce.output = TRUE) # now we need to actually save some mallet output
}

# Make topic composition plots

words.plots <- list()
for (i in n.topics){
  words.data <- parse.xml(paste("diagnostics", i, "xml", sep = "."))
  words.plots[[as.character(i)]] <- plot.topics(words.data, size.multiplier = 45)
}

##### Make selection of topics for report

## Some topics from model with 25 topics
words.data.25 <- parse.xml(paste("diagnostics", 25, "xml", sep = "."))
plot.data <- words.data.25[words.data.25$topic.id %in%
                             c(9, 17, 8, 15, 16),]
out.plots.25 <- ggplot(plot.data, aes(x = factor(topic.id), y = log.prob)) +
  geom_text(aes(label = words),
            size = 45*sqrt(plot.data$prob), position = "stack")+ 
  ylab("")+
  xlab("Topic") +
  scale_y_continuous(breaks=NULL)

## Some topics from model with 200 topics
words.data.200 <- parse.xml(paste("diagnostics", 200, "xml", sep = "."))
plot.data <- words.data.200[words.data.200$topic.id %in%
                             c(200, 189, 187, 181, 173),]
out.plots.200 <- ggplot(plot.data, aes(x = factor(topic.id), y = log.prob)) +
  geom_text(aes(label = words),
            size = 45*sqrt(plot.data$prob), position = "stack")+ 
  ylab("")+
  xlab("Topic") +
  scale_y_continuous(breaks=NULL)

## Save results of the runs
save(results, LL.plot,
     words.plots, 
     out.plots.25, out.plots.200,
     file = paste0("convote_results.Rdata"))