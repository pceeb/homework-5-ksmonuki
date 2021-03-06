#R Script for C177 Project
#ideal flow of code for desired flexibility
#Basically, I want the user to be able to specify any field and concatenate all the data for each species into one final table (.txt, .csv, etc.)
#current thought: user looks at a master list of all possible fields from all (?) possible functions
#user edits a default command argument variables script
library(devtools)
library(dplyr)
library(tidyverse)
library(rfishbase)
library(plyr)
#load table
#Ask Zack for truly raw table (he edits some part of the table in Excel before inputing the table into R)
#set the working directory to specify where you want the output file to go
setwd("/Users/keiramonuki/Documents/Barber_Lab")
#input Anacapa dataset
input_biom_path <- "/Users/keiramonuki/Documents/Barber_Lab/Taxonomy_Tables/12S_ASV_raw_taxonomy_60_edited_new.txt"
#read the .txt file as a tab-delimited table
ASV.table <- read.table(input_biom_path, header = 1, sep = "\t", stringsAsFactors = F)
ASV.table$X12S_seq_number <- factor(ASV.table$X12S_seq_number)
gathercols <-colnames(ASV.table)[2:(length(ASV.table)-1)]
#converts the data to wide format
ASV.table <- gather(ASV.table, sample, reads, gathercols, factor_key=TRUE)
#
#remove ASVs with only one read, as you cannot make any conclusions about ASVs with only one read
ASV.table %>%
  dplyr::group_by(X12S_seq_number) %>%
  mutate (TotalReadsperSample = sum(reads)) %>%
  filter(., TotalReadsperSample > 1) %>%
  select(-TotalReadsperSample) -> ASV.table
#
#make ASV table a tibble to ensure data is in a tidyverse-compatible format
ASV.table <- as_tibble(ASV.table)
#
#remove zero reads to improve speed of code (is this necessary with the previous code?)
ASV.table %>%
  filter(reads != 0)  -> ASV.table
#
#Select only unique ASVs
ASV.table %>%
  select(sum.taxonomy) %>%
  unique() -> ASV.table
#
#Separate the ASVs in taxonomic groups and select the species column for use with rfishbase
ASV.table %>%
  separate(sum.taxonomy, into = c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"), sep=";", remove=F) %>%
  select(Species) -> ASV.table
#
#convert the species table into a character string
species_list <- ASV.table$Species
#
#create a table using the estimate data from rfishbase
species_list %>%
  estimate(fields = c("Species", "MaxLengthTL", "Troph", "seTroph", "TrophObserved")) -> estimate_table
#
#create a table using the predators data from rfishbase
species_list %>%
  predators(fields = c("Species", "PredatorGroup", "PredatorName")) -> predator_table
#
#create a table using the stocks data from rfishbase
species_list %>%
  stocks(fields = c("Species", "StockDefsGeneral", "IUCN_Code", "EnvTemp", "Resilience", "GenBankID", "IUCN_ID")) -> stocks_table
#
#combine the tables together by species
joined_table <- join_all(list(estimate_table, predator_table, stocks_table), type = "left")
#
#remove NAs from species column
final_table<- joined_table[!is.na(joined_table$Species), ]
#
#save output ASV
write_csv(final_table, "fishbase_output")
