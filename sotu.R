##########################
## Script params    ######
##########################

# dirs
dirs <- list()
# technically not a dir, but for convenience: mallet binary
dirs$mallet <- # path to Mallet binary (the binary itself, not just the folder containing it)
dirs$data <- # path to the working directory containing data
dirs$output <- file.path(dirs$data, "workdir_part2")

if (!dir.exists(dirs$output)){
  dir.create(dirs$output)
}

# mallet

# also not a dir, but the input data file for mallet
dirs$topic.trainer.input <- "sotu_baseline.mallet"

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
  run.mallet(n.topics = n, n.chains, n.iters, mallet.seed)
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
# Compare different models

n.topics <- 25
n.chains <- 10
n.iters <- 500
mallet.seed <- c(1,20,67,89,45,980,567,340,267,109)

input.data <- c("sotu_ner", "sotu_np", "sotu_bigrams","sotu_ner_cleaned", "sotu_np_cleaned")
models <- list()

for (d in input.data){
  
  dirs[["topic.trainer.input"]] <- paste0(d,".mallet")
  dirs[["output"]] <- file.path(dirs$data, "workdir_part2", d)
  if (!dir.exists(dirs$output)){
    dir.create(dirs$output)
  }
  setwd(dirs$output)
  
  models[[d]] <- run.mallet(dirs, n.topics, n.chains, n.iters, mallet.seed)
}

models$sotu_baseline <- results[results$n.topics == n.topics,]
models.results <- ldply(models)
models.results$n.topics <- NULL
colnames(models.results)[1] <- "model"

models.plot.data <- models.results %>% 
  tidyr::gather(key = chain, value = LL, -model) %>% # convert to long format
  group_by(model) %>% # for each model...
  summarize(meanLL = mean(LL), # calculate mean LL
            se_min = meanLL - sd(LL),
            se_max = meanLL + sd(LL)) # and standard deviation

models.LL.plot <- ggplot(models.plot.data) + # plot the values
  geom_bar(aes(x = model, y = meanLL), stat = "identity", position = dodge) +
  geom_errorbar(aes(x = model, ymin = se_min, ymax = se_max), position = dodge)+
  ggtitle(paste("Mean Log-likelihood values for models with 
                different preprocessing")) +
  coord_cartesian(ylim = c(-8.5, -11)) + 
  scale_y_reverse()


# ===========================
# Look at the topic composition for different models


# Figure out which run gave us the best log likelihood and then
# use the seed from that run
best.seeds <- models.results %>%
  tidyr::gather(key = iter, value = LL, -model) %>%
  group_by(model) %>%
  filter(LL == max(LL))
best.seeds$seed <- mallet.seed[as.numeric(best.seeds$iter)]

# convert factor to numeric
best.seeds$iter <- as.numeric(best.seeds$iter)


for (m in best.seeds$model){
  dirs[["output"]] <- file.path(dirs$data, "workdir_part2", m)
  dirs[["topic.trainer.input"]] <- paste0(m,".mallet")
  setwd(dirs$output)
  run.mallet(dirs = dirs,
             n.topics = n.topics,
             n.chains = 1,
             n.iters = n.iters,
             mallet.seed = best.seeds[best.seeds$model == m,"seed"][[1]],
             produce.output = TRUE) 
}

models.words.plots <- list()
for (m in best.seeds$model){
  setwd(file.path(dirs$data, "workdir_part2", m))
  models.words.data <- parse.xml(paste("diagnostics", n.topics,"xml", sep = "."))
  models.words.plots[[m]] <- plot.topics(models.words.data, size.multiplier = 45)
}

## Save results of the runs
setwd(filepath(dirs$data), "workdir_part2")
save(results, LL.plot,
     models, models.results, models.LL.plot,
     models.words.plots,
     file = paste0("sotu_results_", n.topics, "topics.Rdata"))