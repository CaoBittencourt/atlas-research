# PACKAGES -----------------------------------------------------------------
pkg <- c(
  'psych', 'GPArotation' #Factor analysis
  , 'text2vec' #Cosine similarity
  , 'tidyverse' #Data wrangling
)

# Activate / install packages
lapply(pkg, function(x)
  if(!require(x, character.only = T))
  {install.packages(x); require(x)})

# Package citation
# lapply(pkg, function(x)
#   {citation(package = x)})


# WORKING DIRECTORY -------------------------------------------------------
setwd('C:/Users/Cao/Documents/Github/Atlas-Research/Career-Choice-Models')

# KNN MATCHING ---------------------------------------------------------------
source('./KNN_Matching.R')

# SKILLS FACTOR LIST -----------------------------------------------------------------
list_skill.factors <- list(
  'General' = c(
    # Factor 1 is composed of cognitive, non-technical, general skills (general competencies)
    'Judgment_and_Decision.L'
    , 'Complex_Problem_Solving.L'
    , 'Active_Learning.L'
    , 'Critical_Thinking.L'
  )
  , 'Technical' = c(
    # Factor 2 is composed of mechanical, hands-on, specialist skills (technical)
    'Equipment_Selection.L'
    , 'Troubleshooting.L'
    , 'Repairing.L'
    , 'Equipment_Maintenance.L'
  )
  
)

# ABILITIES FACTOR LIST ---------------------------------------------------
list_ablt.factors <- list(
  'Perception' = c(
    # Factor 1 is composed of perceptual abilities (perception):
    'Night_Vision.L'
    , 'Sound_Localization.L'
    , 'Glare_Sensitivity.L'
  )
  , 'Dexterity' = c(
    # Factor 2 is composed of manual abilities (dexterity):
    'Finger_Dexterity.L'
    , 'Arm_Hand_Steadiness.L'
    , 'Manual_Dexterity.L'
  )
  , 'Robustness' = c(
    # Factor 3 is composed of bodily robustness, potency, and coordination (overall body robustness)
    'Stamina.L'
    , 'Gross_Body_Coordination.L'
    , 'Trunk_Strength.L'
  )
  , 'Intelligence' = c(
    # Factor 4 is composed of cognitive abilities (intelligence):
    'Inductive_Reasoning.L'
    , 'Problem_Sensitivity.L'
    , 'Deductive_Reasoning.L'
  )
)

# KNOWLEDGE FACTOR LIST ---------------------------------------------------
list_know.factors <- list(
  'Health' = c(
    # Factor 1 is composed of health-related fields of knowledge (health / help).
    'Therapy_and_Counseling.L'
    , 'Psychology.L'
    , 'Medicine_and_Dentistry.L'
  )
  , 'Building' = c(
    # Factor 2 is composed of engineering / building-related fields of knowledge (build).
    'Physics.L'
    , 'Engineering_and_Technology.L'
    , 'Building_and_Construction.L'
  ) 
  , 'Business' = c(
    # Factor 3 is composed of financial and enterprising fields of knowledge (FGV).
    'Economics_and_Accounting.L'
    , 'Sales_and_Marketing.L'
    , 'Administration_and_Management.L'
  )
  , 'Arts_Humanities' = c(
    # Factor 4 is composed of arts and humanities (communists).
    'History_and_Archeology.L'
    , 'Geography.L'
    , 'Fine_Arts.L'
  ) 
)


# ALL FACTORS LIST -------------------------------------------------------------
list_factors <- list( 
  'Skills' = list_skill.factors
  , 'Abilities' = list_ablt.factors
  , 'Knowledge' = list_know.factors
)

# EFA-REDUCED OCCUPATIONS DATA FRAME -------------------------------------------
# Occupations data frame
df_occupations <- readr::read_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vSphzWoCxoNaiaJcQUWKCMqUAT041Q8UqUgM7rSzIwYZb7FhttKJwNgtrFf-r7EgzXHFom4UjLl2ltk/pub?gid=563902602&single=true&output=csv')

# Matching data frame
# Only highly qualified professions
df_occupations %>%
  filter(
    Entry_level_Education %in% c(
      "Bachelor's degree"
      , "Doctoral or professional degree"
      # , "Associate's degree"
      , "Master's degree"
    )
  ) -> df_occupations

# Select only necessary variables
df_occupations %>%
  select(
    Occupation
    , Career_Cluster
    , all_of(
      list_factors %>%
        flatten() %>% 
        flatten_chr()
    )
  ) %>%
  mutate(
    across(
      .cols = all_of(
        list_factors %>%
          flatten() %>% 
          flatten_chr()
      )
      , .fns = function(x){x/100}
    )
  ) -> df_occupations

# EFA-REDUCED QUERY VECTOR -----------------------------------------------
# User questionnaires data frame
df_input.all <- read_csv(url('https://docs.google.com/spreadsheets/d/e/2PACX-1vSphzWoCxoNaiaJcQUWKCMqUAT041Q8UqUgM7rSzIwYZb7FhttKJwNgtrFf-r7EgzXHFom4UjLl2ltk/pub?gid=725827850&single=true&output=csv'))

df_input.all %>% 
  select(
    Name
    , all_of(
      list_factors %>%
        flatten() %>% 
        flatten_chr()
    )
  ) %>%  
  mutate(
    across(
      .cols = all_of(
        list_factors %>%
          flatten() %>% 
          flatten_chr()
      )
      , .fns = function(x){
        recode(x
               , '1' = .0
               , '2' = .25
               , '3' = .5
               , '4' = .75
               , '5' = 1
        )}
    )
  ) -> df_input.all

# For this example, use Martijn' questionnaire 
df_input.all %>% 
  # filter(Name == 'Acilio') %>%
  # filter(Name == 'Alexandre') %>%
  # filter(Name == 'Cao') %>%
  # filter(Name == 'Felipe') %>%
  # filter(Name == 'Gabriel') %>%
  filter(Name == 'Martijn') %>%
  # filter(Name == 'Maurício') %>%
  # filter(Name == 'Milena') %>%
  # filter(Name == 'Tatiana') %>%
  # filter(Name == 'Uelinton') %>%
  select(-Name) -> df_input


# # TEST --------------------------------------------------------------------
# # Cosine => Pearson (normalize by subtracting the mean of the vector)
# df_occupations %>% 
#   select(
#     ends_with('.L')
#   ) %>% 
#   as.matrix() -> mtx_occupations
# 
# df_input %>% 
#   as.matrix() -> mtx_input
# 
# sim2(
#   x = mtx_occupations
#   , y = mtx_input
#   , method = 'cosine'
#   # , norm = 'l2'
#   # , norm = 'none'
# ) %>% 
#   # diag() %>%
#   as_tibble() -> lalala
# 
# names(lalala) <- 'Similarity.Cosine'
# 
# lalala
# 
# df_occupations %>% 
#   bind_cols(lalala) %>% 
#   select(
#     Occupation
#     , Career_Cluster
#     , Similarity.Cosine
#   ) %>% 
#   arrange(desc(Similarity.Cosine)) -> lalala
# 
# # Angular similarity
# lalala %>% 
#   mutate(
#     Similarity.Angular = 1 - (acos(Similarity.Cosine)/pi)
#   ) -> lalala
# 

# OVERQUALIFICATION IMPUTATION TEST ---------------------------------------
# [VERY LOW REQUIREMENTS] OVERQUALIFICATION INPUT (ONLY IF SCORE <= 0.05) -------------------------------------------------
df_input %>%
  rename_with(
    .fn = function(x){paste0(x,'.input')}
  ) %>%
  bind_cols(
    df_occupations
  ) %>%
  # group_by(Occupation) %>%
  mutate(
    across(
      .cols = c(
        !ends_with('.input')
        , -Occupation
        , -Career_Cluster
      )
      ,.fns = function(x){
        
        ifelse(
          # Overqualified if > .05 and requirement <= .05
          x <= 0.05 & eval(sym(paste0(cur_column(),'.input'))) > x
          , yes = x
          , no = eval(sym(paste0(cur_column(),'.input')))
        )
        
      }
      , .names = '{col}.sub'
    )
  ) %>%
  # ungroup() %>%
  select(
    ends_with('.sub')
  ) %>%
  rename_with(
    function(x){str_remove(x,'.sub')}
  ) -> df_input.sub





# [REALLY BAD] [INPUT NOTHING] -------------------------------------------------
df_input %>%
  rename_with(
    .fn = function(x){paste0(x,'.input')}
  ) %>%
  bind_cols(
    df_occupations
  ) %>%
  # group_by(Occupation) %>%
  # mutate(
  #   across(
  #     .cols = c(
  #       !ends_with('.input')
  #       , -Occupation
  #       , -Career_Cluster
  #     )
  #     ,.fns = function(x){
  #
  #       ifelse(
#         x == 0
#         , yes = 0
#         , no = eval(sym(paste0(cur_column(),'.input')))
#       )
#
#     }
#     , .names = '{col}.sub'
#   )
# ) %>%
# ungroup() %>%
select(
  ends_with('.input')
) %>%
  rename_with(
    function(x){str_remove(x,'.input')}
  ) -> df_input.sub


# KNN MATCHING WITHOUT ITEM SCORES ----------------------------------------
lapply(
  1:nrow(df_input.sub)
  , function(x){
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations[x,]
      , .vec_query.numeric = df_input.sub[x,]
      , .int_k = 1
    )
    
  }) %>%
  bind_rows() %>%
  arrange(Euclidean_Distance) -> df_KNN.output.sub

# SCORE ITEMS (OCCUPATIONS) -----------------------------------------------
psych::scoreVeryFast(
  keys = flatten(list_factors)
  
  , items = df_occupations %>%
    select(
      all_of(
        list_factors %>%
          flatten() %>% 
          flatten_chr()
      )
    )
  , totals = F #Average scores
) %>% 
  as_tibble() %>% 
  bind_cols(
    df_occupations
  ) %>% 
  select(
    where(
      negate(is.numeric)
    )
    , list_factors %>%
      flatten() %>% 
      names()
  ) -> df_occupations.scores

# SCORE ITEMS (JSON INPUT) -----------------------------------------------
lapply(
  list_factors
  , function(scales){
    
    psych::scoreVeryFast(
      keys = scales
      , items = df_input.sub 
      , totals = F #Average scores
    ) %>% 
      as_tibble()
    
  } 
) %>% flatten_df() -> df_factor.scores

# KNN MATCHING WITH ITEM SCORES -------------------------------------------
lapply(
  1:nrow(df_factor.scores)
  , function(x){
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations.scores[x,]
      , .vec_query.numeric = df_factor.scores[x,]
      , .int_k = 1
    ) 
    
  }) %>%
  bind_rows() %>% 
  arrange(Euclidean_Distance) -> df_KNN.output.sub.scores

# OUTPUT ------------------------------------------------------------------
df_KNN.output.sub %>%
  select(
    Occupation
    , Career_Cluster
    , Euclidean_Distance
    , starts_with('Similarity')
  ) %>%
  view()

df_KNN.output.sub.scores %>% 
  select(
    Occupation
    , Career_Cluster
    , Euclidean_Distance
    , starts_with('Similarity')
  ) %>% 
  view()

# HISTOGRAMS ------------------------------------------------------------------
df_KNN.output.sub %>%
  pivot_longer(
    cols = starts_with('Similarity.')
    , names_to = 'Similarity'
    , values_to = 'Value'
  ) -> df_KNN.output.sub.long

df_KNN.output.sub.long %>%
  mutate(
    Similarity2 = Similarity
    , Similarity2 = fct_reorder(
      Similarity2, Value
      , .fun = max, .desc = T
    )
    , Similarity = fct_reorder(
      Similarity, Value
      , .fun = max, .desc = T
    )
  ) -> tmp

tmp %>%
  ggplot(aes(
    x = Value
    # , color = Similarity
  )) + 
  geom_histogram(
    data = tmp %>% 
      select(-Similarity)
    , aes(group = Similarity2)
    # , color = 'grey'
    , binwidth = .1
    # , color = 'grey'
    , fill = 'grey'
    , alpha = 0.5
  ) +
  geom_histogram(
    # aes(color = Similarity)
    aes(fill = Similarity)
    , binwidth = .1
    # , color = viridis::plasma(1)
    , fill = viridis::plasma(1)
  )+
  facet_wrap(
    facets = vars(Similarity)
    , nrow = 3) + 
  ggthemes::theme_hc()
  
df_KNN.output.sub.scores %>%
  pivot_longer(
    cols = starts_with('Similarity.')
    , names_to = 'Similarity'
    , values_to = 'Value'
  ) -> df_KNN.output.sub.scores.long

df_KNN.output.sub.scores.long %>%
  mutate(
    Similarity2 = Similarity
    , Similarity2 = fct_reorder(
      Similarity2, Value
      , .fun = max, .desc = T
    )
    , Similarity = fct_reorder(
      Similarity, Value
      , .fun = max, .desc = T
    )
  ) -> tmp.scores

tmp.scores %>%
  ggplot(aes(
    x = Value
    # , color = Similarity
  )) + 
  geom_histogram(
    data = tmp %>% 
      select(-Similarity)
    , aes(group = Similarity2)
    # , color = 'grey'
    , binwidth = .1
    # , color = 'grey'
    , fill = 'grey'
    , alpha = 0.5
  ) +
  geom_histogram(
    # aes(color = Similarity)
    aes(fill = Similarity)
    , binwidth = .1
    # , color = viridis::plasma(1)
    , fill = viridis::plasma(1)
  )+
  facet_wrap(
    facets = vars(Similarity)
    , nrow = 3) + 
  ggthemes::theme_hc()
  
# BAR PLOTS (MAX / MIN MATCHING %) ------------------------------------------------------------------
df_KNN.output.sub %>%
  pivot_longer(
    cols = starts_with('Similarity.')
    , names_to = 'Similarity'
    , values_to = 'Value'
  ) -> df_KNN.output.sub.long

df_KNN.output.sub.long %>%
  mutate(
    Similarity2 = Similarity
    , Similarity2 = fct_reorder(
      Similarity2, Value
      , .fun = max, .desc = T
    )
    , Similarity = fct_reorder(
      Similarity, Value
      , .fun = max, .desc = T
    )
  ) -> tmp

tmp %>%
  ggplot(aes(
    x = Value
    # , color = Similarity
  )) + 
  geom_histogram(
    data = tmp %>% 
      select(-Similarity)
    , aes(group = Similarity2)
    # , color = 'grey'
    , binwidth = .1
    # , color = 'grey'
    , fill = 'grey'
    , alpha = 0.5
  ) +
  geom_histogram(
    # aes(color = Similarity)
    aes(fill = Similarity)
    , binwidth = .1
    # , color = viridis::plasma(1)
    , fill = viridis::plasma(1)
  )+
  facet_wrap(
    facets = vars(Similarity)
    , nrow = 3) + 
  ggthemes::theme_hc()
  
df_KNN.output.sub.scores %>%
  pivot_longer(
    cols = starts_with('Similarity.')
    , names_to = 'Similarity'
    , values_to = 'Value'
  ) -> df_KNN.output.sub.scores.long

df_KNN.output.sub.scores.long %>%
  mutate(
    Similarity2 = Similarity
    , Similarity2 = fct_reorder(
      Similarity2, Value
      , .fun = max, .desc = T
    )
    , Similarity = fct_reorder(
      Similarity, Value
      , .fun = max, .desc = T
    )
  ) -> tmp.scores

tmp.scores %>%
  ggplot(aes(
    x = Value
    # , color = Similarity
  )) + 
  geom_histogram(
    data = tmp %>% 
      select(-Similarity)
    , aes(group = Similarity2)
    # , color = 'grey'
    , binwidth = .1
    # , color = 'grey'
    , fill = 'grey'
    , alpha = 0.5
  ) +
  geom_histogram(
    # aes(color = Similarity)
    aes(fill = Similarity)
    , binwidth = .1
    # , color = viridis::plasma(1)
    , fill = viridis::plasma(1)
  )+
  facet_wrap(
    facets = vars(Similarity)
    , nrow = 3) + 
  ggthemes::theme_hc()
  