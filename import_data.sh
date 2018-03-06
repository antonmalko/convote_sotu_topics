#!/bin/bash
M= #path to the folder containing Mallet binary

$M/mallet import-dir \
	--input "convote_data"\
       	--output convote_data.mallet\
	--gram-sizes 1\
	--remove-stopwords\
	--keep-sequence
