# PACKAGES -----------------------------------------------------------------
pkg <- c(
  'tidyverse' #Data wrangling
  , 'FNN' #Fast K-NN Algorithm (faster than the 'class' package)
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

# FUNCTIONS ---------------------------------------------------------------
source('./Simulated_Data.R')
source('./KNN_Matching.R')

# EFA-REDUCED OCCUPATIONS DATA FRAME -------------------------------------------
# Occupations data frame
df_occupations <- readr::read_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vSphzWoCxoNaiaJcQUWKCMqUAT041Q8UqUgM7rSzIwYZb7FhttKJwNgtrFf-r7EgzXHFom4UjLl2ltk/pub?gid=563902602&single=true&output=csv')

# Selected skills, abilities and knowledge
c(
  # Factor 1 is composed of cognitive, non-technical, general skills (general competencies)
  'Judgment_and_Decision.L'
  , 'Complex_Problem_Solving.L'
  , 'Active_Learning.L'
  , 'Critical_Thinking.L'
  # Factor 2 is composed of mechanical, hands-on, specialist skills (technical)
  , 'Equipment_Selection.L'
  , 'Troubleshooting.L'
  , 'Repairing.L'
  , 'Equipment_Maintenance.L'
) -> chr_Skill.Items 

c(
  # Factor 1 is composed of perceptual abilities (perception):
  'Night_Vision.L'
  , 'Sound_Localization.L'
  , 'Glare_Sensitivity.L'
  # Factor 2 is composed of manual abilities (dexterity):
  , 'Finger_Dexterity.L'
  , 'Arm_Hand_Steadiness.L'
  , 'Manual_Dexterity.L'
  # Factor 3 is composed of bodily robustness, potency, and coordination (overall body robustness)
  , 'Stamina.L'
  , 'Gross_Body_Coordination.L'
  , 'Trunk_Strength.L'
  # Factor 4 is composed of cognitive abilities (intelligence):
  , 'Inductive_Reasoning.L'
  , 'Problem_Sensitivity.L'
  , 'Deductive_Reasoning.L'
) -> chr_Ablt.Items

c(
  # Factor 1 is composed of health-related fields of knowledge (health / help).
  'Therapy_and_Counseling.L'
  , 'Psychology.L'
  , 'Medicine_and_Dentistry.L'
  # Factor 2 is composed of engineering / building-related fields of knowledge (build).
  , 'Physics.L'
  , 'Engineering_and_Technology.L'
  , 'Building_and_Construction.L'
  # Factor 3 is composed of financial and enterprising fields of knowledge (FGV).
  , 'Economics_and_Accounting.L'
  , 'Sales_and_Marketing.L'
  , 'Administration_and_Management.L'
  # Factor 4 is composed of arts and humanities (communists).
  , 'History_and_Archeology.L'
  , 'Geography.L'
  , 'Fine_Arts.L'
) -> chr_Know.Items

# Matching data frame
df_occupations %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(c(
      chr_Skill.Items
      , chr_Ablt.Items
      , chr_Know.Items
    ))
  ) %>% 
  mutate(
    across(
      .cols = all_of(c(
        chr_Skill.Items
        , chr_Ablt.Items
        , chr_Know.Items
      ))
      , .fns = function(x){x/100}
    )
  ) -> df_occupations

df_occupations %>% 
  # Select only highly qualified professions
  filter(
    Entry_level_Education %in% c(
      "Bachelor's degree"
      , "Doctoral or professional degree"
      , "Associate's degree"
      , "Master's degree"
      )
  ) -> df_occupations


# EFA-REDUCED QUERY VECTOR (USER INPUT) -----------------------------------------------
# User questionnaires data frame
df_input <- read_csv(url('https://docs.google.com/spreadsheets/d/e/2PACX-1vSphzWoCxoNaiaJcQUWKCMqUAT041Q8UqUgM7rSzIwYZb7FhttKJwNgtrFf-r7EgzXHFom4UjLl2ltk/pub?gid=725827850&single=true&output=csv'))

df_input %>% 
  select(
    Name
    , all_of(c(
      chr_Skill.Items
      , chr_Ablt.Items
      , chr_Know.Items
    ))
  ) %>%  
  mutate(
    across(
      .cols = all_of(c(
        chr_Skill.Items
        , chr_Ablt.Items
        , chr_Know.Items
      ))
      , .fns = function(x){
        recode(x
          , '1' = .0
          , '2' = .25
          , '3' = .5
          , '4' = .75
          , '5' = 1
        )}
      # , .fns = function(x){
      #   recode(x 
      #          , '1' = .0 
      #          , '2' = .27
      #          , '3' = .54
      #          , '4' = .85
      #          , '5' = 1
      #   )}
    )
  ) -> df_input

# Keep only completed questionnaires
df_input %>% 
  drop_na() -> df_input


# Vector of names
chr_names <- df_input$Name
names(chr_names) <- df_input$Name

# Simulate one user input
# fun_simulate.tmvnorm(
#   .df_data.numeric = df_occupations
#   , .int_n.simulations = 1
# ) -> vec_user.input

# APPLY KNN ---------------------------------------------------------------
lapply(
  chr_names
  , function(name){
    
    df_input %>% 
      filter(Name == name) -> vec_user.input
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations
      , .vec_query.numeric = vec_user.input
      , .int_k = nrow(df_occupations)
    ) %>% 
      return(.)
    
  }) -> list_KNN.output

# fun_KNN.matching(
#   .df_data.numeric = df_occupations
#   , .vec_query.numeric = vec_user.input
#   , .int_k = nrow(df_occupations)
# ) -> df_KNN.output

# INDIVIDUAL MATCHING (SKILLS ONLY) ---------------------------------------
df_occupations %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(chr_Skill.Items)
  ) -> df_occupations.skill

df_input %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(chr_Skill.Items)
  ) -> df_input.skill

lapply(
  chr_names
  , function(name){
    
    df_input.skill %>% 
      filter(Name == name) -> vec_user.input
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations.skill
      , .vec_query.numeric = vec_user.input
      , .int_k = nrow(df_occupations.skill)
    ) %>% 
      return(.)
    
  }) -> list_KNN.output.skill


# INDIVIDUAL MATCHING (ABILITIES ONLY) ---------------------------------------
df_occupations %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(chr_Ablt.Items)
  ) -> df_occupations.ablt

df_input %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(chr_Ablt.Items)
  ) -> df_input.ablt

lapply(
  chr_names
  , function(name){
    
    df_input.ablt %>% 
      filter(Name == name) -> vec_user.input
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations.ablt
      , .vec_query.numeric = vec_user.input
      , .int_k = nrow(df_occupations.ablt)
    ) %>% 
      return(.)
    
  }) -> list_KNN.output.ablt


# INDIVIDUAL MATCHING (KNOWLEDGE ONLY) ---------------------------------------
df_occupations %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(chr_Know.Items)
  ) -> df_occupations.know

df_input %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(chr_Know.Items)
  ) -> df_input.know

lapply(
  chr_names
  , function(name){
    
    df_input.know %>% 
      filter(Name == name) -> vec_user.input
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations.know
      , .vec_query.numeric = vec_user.input
      , .int_k = nrow(df_occupations.know)
    ) %>% 
      return(.)
    
  }) -> list_KNN.output.know


# INDIVIDUAL MATCHING (SKILLS AND KNOWLEDGE) ---------------------------------------
df_occupations %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(c(
      chr_Skill.Items
      , chr_Know.Items
    ))
  ) -> df_occupations.skill.know

df_input %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(c(
      chr_Skill.Items
      , chr_Know.Items
    ))
  ) -> df_input.skill.know

lapply(
  chr_names
  , function(name){
    
    df_input.skill.know %>% 
      filter(Name == name) -> vec_user.input
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations.skill.know
      , .vec_query.numeric = vec_user.input
      , .int_k = nrow(df_occupations.skill.know)
    ) %>% 
      return(.)
    
  }) -> list_KNN.output.skill.know


# INDIVIDUAL MATCHING (SKILLS AND ABILITIES) ---------------------------------------
df_occupations %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(c(
      chr_Skill.Items
      , chr_Ablt.Items
    ))
  ) -> df_occupations.skill.ablt

df_input %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(c(
      chr_Skill.Items
      , chr_Ablt.Items
    ))
  ) -> df_input.skill.ablt

lapply(
  chr_names
  , function(name){
    
    df_input.skill.ablt %>% 
      filter(Name == name) -> vec_user.input
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations.skill.ablt
      , .vec_query.numeric = vec_user.input
      , .int_k = nrow(df_occupations.skill.ablt)
    ) %>% 
      return(.)
    
  }) -> list_KNN.output.skill.ablt


# INDIVIDUAL MATCHING (ABILITIES AND KNOWLEDGE) ---------------------------------------
df_occupations %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(c(
      chr_Ablt.Items
      , chr_Know.Items
    ))
  ) -> df_occupations.ablt.know

df_input %>% 
  select(
    where(
      negate(is.numeric)
    )
    , all_of(c(
      chr_Ablt.Items
      , chr_Know.Items
    ))
  ) -> df_input.ablt.know

lapply(
  chr_names
  , function(name){
    
    df_input.ablt.know %>% 
      filter(Name == name) -> vec_user.input
    
    fun_KNN.matching(
      .df_data.numeric = df_occupations.ablt.know
      , .vec_query.numeric = vec_user.input
      , .int_k = nrow(df_occupations.ablt.know)
    ) %>% 
      return(.)
    
  }) -> list_KNN.output.ablt.know

