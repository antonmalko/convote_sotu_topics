# convote_sotu_topics

## Topic modeling of Convote and SOTU corpora.

This is a collection of scripts exploring topic modelling on two corpora: State of the Union (SOTU) addresses and a corpus of [Congressional speech data](https://www.cs.cornell.edu/home/llee/data/convote.html). Topic modelling is done using [Mallet](http://mallet.cs.umass.edu/), with support scripts in R and Python. A (somewhat impressoinistic) description of the experiments can be found in `Report.pdf`.

## Running the scripts from scratch

1. Set the right directory structure: it is assumed that the working directory contains the following:

    + A directory called "convote_data", which contains files from "data_stage_three" directory of the convote dataset. 
    + A text file called "sotu.txt" with SOTU texts
  
2. Run `import_data.sh`; make sure to put the path to Mallet binary on your system in the first line of the script. This will create `convote_data.mallet` file.

3. Run `convote.R`. Make sure to set `dirs$mallet` (path to Mallet binary) and `dirs$data` (path to the data directory). All the results will be saved in `workdir` folder (created automatically). It will run Mallet multiple times, asking it to discover different number of topics. It will also create several plots: Log-likelihood values for each number of topics and some representative words for each discovered topic. These will be saved into `convote_results.Rdata`.

4. Run `sotu_preproc.py`. It converts the SOTU corpus into the format Mallet understands: a text per line. Additionally, it works in different regimes of preprocessing (to specify them, uncomment some/all blocks of code in the `main()` function). The regimes are:
    
    1. Baseline: no substantial preprocessing, except converting for the format that Mallet takes in (one file with one document per line).
    2. Bigrams: The texts are tokenized, lowercased; stopwords, punctuation and numbers are removed; bigrams are found and sorted by the likelihood ratio statistic (NLTK is used). Top 15 % percent of the bigrams are converted to tokens (the choice of 15 % is arbitrary).
    3. NER: the texts are fed to Spacy, which performs Named Entity Recognition; the entitites are converted to tokens.
    4. NER cleaned: same as above, but before being fed to Spacy, the texts are cleaned from stopwords, puncutation and numbers.
    5. NP: the texts are fed to Spacy, which parses them and discovers NPs, which are converted to tokens.
    6. NP cleaned: same as above, but before being fed to Spacy, the texts are cleaned from stopwords, puncutation and numbers.
    
5. Run `sotu.R`. Again, make sure to set `dirs$mallet` (path to Mallet binary) and `dirs$data` (path to the data directory). All the results will be saved in `workdir_part2` folder. This will run the models on different variants of SOTU corpus (produced by `part2_preproc.py`). To specify, how many topics to model for each variant of the corpus, modify `n.topics` variable. To specify which variants of preprocessing to use modify `input.data` variable. For the output data on each variant of preprocessing, a subfolder will be created within `workdir_part2` folder. As before, plots with Log-likelihood and top words in each topic will be produced; they will be saved to 'sotu_results_Xtopics.RData', where X stands for number of topics chosen.
 

## Scripts info

+ 3 R scripts to control Mallet:

	+ functions.R - contains functions for calling Mallet and collecting its output, as well as for producing plots of top 20 words in each topic
		+ run.mallet function controls Mallet runs. One parameter of interest is "produce.output". If FALSE, Mallet will not create any data, and the script will just collect the LL/token values from Mallet console output. If TRUE, Mallet will produce 4 files, named like "X.number-of-topics", where X can be:
			+ output-state
			+ output-topic-keys
			+ output-doc-topics
			+ diagnostics
			
		The "diagnostics" file is used later to produce word lists per topic. 
    
    The idea of calling Mallet from external scripts and collecting its output from the console is taken from [here](https://gist.github.com/benmarwick/4559589), but I have re-written and expanded the code. 
		
	+ Part1.R and Part2.R. The differences between them are minor:
		+ In the first section of the script it is possible to set parameters (data directory, output directory, path to Mallet binary; Mallet simulation parameters)
		+ The following section of the script runs each model N times (controlled by n.chains parameter), collects the LL/token information and produces a summary plot.
		+ The next section is devoted to running the models which do save output, parsing the diagnostics files to get word information for each topic and produce plots with the words scaled by their frequency in a topic. In Part1.R script only one model is trained in this section; in Part2.R script, several models are trained in a loop.
		
+ part2_preproc.py script - creates preprocessed versions of SOTU corpus to be fed into Mallet. To use different regimes of preprocessing, uncomment the corresponding block in the main() function.

3. The following parameters were specified when importing the data into Mallet:

--remove-stopwords
--keep-sequence
	
		
