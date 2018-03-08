## Building dataset with opinion switch columns

library(tidyverse)

## getting the columns: id, wave, euRefVote
dat <-read.csv("/Users/apple/Desktop/DAT/BriExit/data/wt_age_origin.csv")
col_wave <- grep("^wave\\d+",names(dat))
col_vote <- grep("^euRefVoteW\\d+",names(dat))

opinion_dat <- dat %>% 
  select(c(id,col_wave,col_vote))

# 6301 cases who DID participated in the study but has an NA response
temp <- c() ## all responses
for(i in 1:13){
  
  if(i!= 5){
    wave_name <- paste0("^wave",i,"$")
    wave_col <- grep(wave_name, colnames(opinion_dat))
    
    vote_name <- paste0("^euRefVoteW",i,"$")
    vote_col<-grep(vote_name,colnames(opinion_dat))
    
    wave_i <- opinion_dat %>% 
      mutate(wave = i) %>%
      select(id, wave,vote_col, wave_col)
    
    names(wave_i) <- sub(wave_name, "present", names(wave_i))
    names(wave_i) <- sub(vote_name, "vote", names(wave_i))
  
  } else {
    wave_name <- paste0("^wave",i,"$")
    wave_col <- grep(wave_name, colnames(opinion_dat))

    wave_i <- opinion_dat %>%
      select(id,wave_col) %>%
      mutate(vote = NA,
             wave = 5)
    names(wave_i) <- sub(wave_name, "present", names(wave_i))
  }
  temp <- rbind2(temp,wave_i)
}

temp <- temp %>% arrange(id)

# Citation:
# http://www.cookbook-r.com/Manipulating_data/Filling_in_NAs_with_last_non-NA_value/
fillNAgaps <- function(x, firstBack=FALSE) {
  ## NA's in a vector or factor are replaced with last non-NA values
  ## If firstBack is TRUE, it will fill in leading NA's with the first
  ## non-NA value. If FALSE, it will not change leading NA's.
  
  # If it's a factor, store the level labels and convert to integer
  lvls <- NULL
  if (is.factor(x)) {
    lvls <- levels(x)
    x    <- as.integer(x)
  }
  
  goodIdx <- !is.na(x)
  
  # These are the non-NA values from x only
  # Add a leading NA or take the first good value, depending on firstBack   
  if (firstBack)   goodVals <- c(x[goodIdx][1], x[goodIdx])
  else             goodVals <- c(NA,            x[goodIdx])
  
  # Fill the indices of the output vector with the indices pulled from
  # these offsets of goodVals. Add 1 to avoid indexing to zero.
  fillIdx <- cumsum(goodIdx)+1
  
  x <- goodVals[fillIdx]
  
  # If it was originally a factor, convert it back
  if (!is.null(lvls)) {
    x <- factor(x, levels=seq_along(lvls), labels=lvls)
  }
  x
}

## Extend NA values
temp_full <- temp %>%
  group_by(id) %>%
  mutate(full_vote = fillNAgaps(vote)) %>%
  mutate(pre_vote = lag(full_vote,1)) %>%
  mutate(switch = ifelse(wave==1, 0, 
                         ifelse(full_vote!=pre_vote, 1, 0))) 

## Compute switch
switch_dat <- temp_full %>%
  summarise(num_wave_present = sum(present),
            num_switch = sum(switch,na.rm = TRUE)) %>% 
  mutate(switch_ratio = num_switch/num_wave_present,
         ifswitch = ifelse(num_switch>0, 1,0))

dataset_static <- inner_join(switch_dat,static)
write.csv(dataset_static, "data/dataset_static_factors.csv")
