import spacy

import nltk
import re

def preprocess_text(speech_text, keep_stopwords, keep_punctuation, keep_numbers):
    header, text = extract_header(speech_text)
    info = parse_header(header)

    text = text.replace("\n\n", "\n").replace("\n", " ")
    text = text.encode("UTF-8")
    # text = clean_text(text, keep_stopwords, keep_punctuation, keep_numbers)
    return(tuple([info, text]))

def extract_header(speech_text):
    header = re.match("(.*?\\n\\n)", speech_text, re.DOTALL).groups(1)[0]
    speech_text = speech_text[len(header):]
    return(header, speech_text)

def parse_header(header):
    # get information about the year and the author of the speech
    header = header.split("\n")
    president = header[1].strip()
    date = header[2]
    year = date[-4:]
    return (tuple([president,year]))

import string
def clean_text(text, keep_stopwords, keep_punctuation, keep_numbers):
    # tokenize and lowercase
    words = nltk.tokenize.word_tokenize(text)
    # words = [w.lower() for w in words]

    # list of stopwords
    stopwords = set(nltk.corpus.stopwords.words("english") + [""])  # remove empty strings too
    if not keep_punctuation:
        stopwords.update(set(string.punctuation))
    # filter stopwords, which will include punctuation if
    # the corresponding option is specified
    if not keep_stopwords:
        words = [w for w in words if not w in stopwords]
    # filter all the strings containing numbers, if the corresponding option is set
    if not keep_numbers:
        words = [w for w in words if re.search("\d+", w) == None]
    return(words)


def read_texts(file_name, keep_stopwords = False, keep_punctuation = False, keep_numbers = True):
    with open(file_name, "r") as f:
        texts = f.read().split("\n\n***\n\n")
        texts = texts[1:] # remove the preamble
        proc_texts = [preprocess_text(t, keep_stopwords, keep_punctuation, keep_numbers) for t in texts]
        texts_dict = {k:v for k,v in proc_texts}
        return (texts_dict)


def mark_entities(text, lang_model, clean = False):

    president = text[0][0].replace(" ","_")
    year = text[0][1]

    if clean:
        tmp = clean_text(text[1], False, False, False)
        tmp = " ".join(tmp)
        model = lang_model(unicode(tmp))
    else:
        model = lang_model(unicode(text[1]))

    text_string = [str(t) for t in model]

    ent_vocab = {ent.start:ent.end for ent in model.ents if ent.end - ent.start != 1}

    for ent_s, ent_e in ent_vocab.iteritems():
        text_string[ent_s] = "_".join([w for w in text_string[ent_s:ent_e]])
        text_string[(ent_s+1):ent_e] = [""]*len(text_string[(ent_s+1):ent_e])

    output = [year, president] + text_string
    output = " ".join([t for t in output if t!= ""])
    return(output)

def mark_nps(text, lang_model, clean = False):

    president = text[0][0].replace(" ","_")
    year = text[0][1]

    if clean:
        tmp = clean_text(text[1], False, False, False)
        tmp = " ".join(tmp)
        model = lang_model(unicode(tmp))
    else:
        model = lang_model(unicode(text[1]))

    text_string = [str(t) for t in model]

    np_vocab = {np.start:np.end for np in model.noun_chunks if np.end - np.start != 1}

    for np_s, np_e in np_vocab.iteritems():
        text_string[np_s] = "_".join([w for w in text_string[np_s:np_e]])
        text_string[(np_s+1):np_e] = [""]*len(text_string[(np_s+1):np_e])

    output = [year, president] + text_string
    output = " ".join([t for t in output if t!= ""])
    return(output)

import nltk
import math

def find_bigrams(text):
    finder = nltk.collocations.BigramCollocationFinder.from_words(text)
    return(finder)

def find_top_bigrams(finder, top_proportion):

    scored_bigrams = finder.score_ngrams(nltk.collocations.BigramAssocMeasures.likelihood_ratio)
    n_bigrams = len(scored_bigrams)
    top_n = int(math.ceil(n_bigrams * top_proportion))
    top_bigrams = finder.score_ngrams(nltk.collocations.BigramAssocMeasures.likelihood_ratio)[0:top_n]
    return(top_bigrams)

def mark_bigrams(text, top_proportion):
    president = text[0][0].replace(" ","_")
    year = text[0][1]
    text_string = clean_text(text[1], False, False, False)

    bigrams = find_bigrams(text_string)
    top_bigrams = find_top_bigrams(bigrams, top_proportion)

    text_string = " ".join(text_string)
    for b in top_bigrams:
        text_string = text_string.replace(" " + " ".join(b[0])+" ", " " + "_".join(b[0])+ " ")

    output = " ".join([year, president]) + " " + text_string

    return(output)

def minimal_processing(text):
    president = text[0][0].replace(" ", "_")
    year = text[0][1]
    text_string = text[1]
    output = " ".join([year, president]) + " " + text_string
    return(output)

def main():

    print ("started...")
    raw_texts = read_texts("sotu.txt")

    print ("read texts")
    nlp = spacy.load("en")
    print("loaded model")
    # unchanged_texts = [minimal_processing(v) for v in raw_texts.iteritems()]
    # with open("sotu_baseline.txt", "w+") as f:
    #   f.write("\n".join(unchanged_texts))

    # ner_texts = [mark_entities(v, nlp) for v in raw_texts.iteritems()]
    # with open("sotu_ner.txt", "w+") as f:
    #    f.write("\n".join(ner_texts))

    # ner_texts_cleaned = [mark_entities(v, nlp, True) for v in raw_texts.iteritems()]
    # with open("sotu_ner_cleaned.txt", "w+") as f:
    #    f.write("\n".join(ner_texts_cleaned))

    # np_texts = [mark_nps(v, nlp) for v in raw_texts.iteritems()]
    # with open("sotu_np.txt", "w+") as f:
    #    f.write("\n".join(np_texts))

    # np_texts_cleaned = [mark_nps(v, nlp, True) for v in raw_texts.iteritems()]
    # with open("sotu_np_cleaned.txt", "w+") as f:
    #    f.write("\n".join(np_texts_cleaned))

    # bigram_texts = [mark_bigrams(v, 0.15) for v in raw_texts.iteritems()]
    # with open("sotu_bigrams.txt", "w+") as f:
    #   f.write("\n".join(bigram_texts))



    print("marked entities")




if __name__ == '__main__':
    main()