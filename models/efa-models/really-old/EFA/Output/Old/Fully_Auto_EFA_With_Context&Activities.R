# ----- SETUP -----------------------------------------------------------
# PACKAGES -----------------------------------------------------------------
pkg <- c(
  # 'paletteer', 'ggthemes', 'scales' #Visualization
  'readr', 'readxl','openxlsx' #Read and write utilities
  , 'tidyverse', 'labelled' #Data wrangling
  # , 'caret' #Variance filter
  , 'psych' #Factor analysis
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

# AUTO-EFA FUNCTIONS ----------------------------------------------------------------
source('./Auto_EFA.R')

# DATA --------------------------------------------------------------------
# Occupations data frame
df_occupations <- readr::read_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vSphzWoCxoNaiaJcQUWKCMqUAT041Q8UqUgM7rSzIwYZb7FhttKJwNgtrFf-r7EgzXHFom4UjLl2ltk/pub?gid=563902602&single=true&output=csv')

# Labels character vector
chr_labels <- scan(
  url('https://docs.google.com/spreadsheets/d/e/2PACX-1vSphzWoCxoNaiaJcQUWKCMqUAT041Q8UqUgM7rSzIwYZb7FhttKJwNgtrFf-r7EgzXHFom4UjLl2ltk/pub?gid=1223197022&single=true&output=csv')
  , sep=','
  , what = ''
  , quiet = T
)

# Exploratory analyses
df_occupations %>% glimpse()
df_occupations %>% class()
df_occupations %>% head()

chr_labels %>% glimpse()
chr_labels %>% class()
chr_labels %>% head()

ncol(df_occupations) == length(chr_labels) 

# Apply labels
df_occupations %>%
  labelled::set_variable_labels(
    .labels = chr_labels
  ) -> df_occupations

# Only numeric variables
df_occupations %>%
  select(
    where(function(x){str_detect(attributes(x)$label, '_Skill')}) #All Skills only
    , -ends_with('.I') #Using recommended levels
    # , -ends_with('.L') #Using importance levels
  ) %>% 
  mutate(#0 to 100 => 0 to 1 (helps calculate similarity later on)
    across(
      .fns = function(x){x/100}
    )
  ) -> df_occupations.numeric.skill

# Only numeric variables
df_occupations %>%
  select(
    where(function(x){str_detect(attributes(x)$label, 'Abilities.')}) #Abilities only
    , -ends_with('.I') #Using recommended levels
    # , -ends_with('.L') #Using importance levels
  ) %>% 
  mutate(#0 to 100 => 0 to 1 (helps calculate similarity later on)
    across(
      .fns = function(x){x/100}
    )
  ) -> df_occupations.numeric.ablt

# Only numeric variables
df_occupations %>%
  select(
    where(function(x){str_detect(attributes(x)$label, 'Knowledge.')}) #Knowledge only
    , -ends_with('.I') #Using recommended levels
    # , -ends_with('.L') #Using importance levels
  ) %>% 
  mutate(#0 to 100 => 0 to 1 (helps calculate similarity later on)
    across(
      .fns = function(x){x/100}
    )
  ) -> df_occupations.numeric.know

# Only numeric variables
df_occupations %>%
  select(
    where(function(x){str_detect(attributes(x)$label, 'Work_Context.')}) #Work contexts and
    , where(function(x){str_detect(attributes(x)$label, 'Work_Activities.')}) #Work activities too
    , -ends_with('.I') #Using recommended levels
    # , -ends_with('.L') #Using importance levels
  ) %>% 
  mutate(#0 to 100 => 0 to 1 (helps calculate similarity later on)
    across(
      .fns = function(x){x/100}
    )
  ) -> df_occupations.numeric.context

# ----- PARAMETERS -----------------------------------------------------------
# VARIANCE PROPORTIONALITY ------------------------------------------------
df_occupations %>%
  select(
    colnames(
      df_occupations.numeric.skill
    )
    , colnames(
      df_occupations.numeric.ablt
    )
    , colnames(
      df_occupations.numeric.know
    )
    , colnames(
      df_occupations.numeric.context
    )
  ) %>%
  mutate(#0 to 100 => 0 to 1 (helps calculate similarity later on)
    across(
      .fns = function(x){x/100}
    )
  ) -> df_occupations.numeric

df_occupations.numeric %>%
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_occupations.var.total

df_occupations.numeric.skill %>%
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_skills.var.total

df_occupations.numeric.ablt %>%
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_ablt.var.total

df_occupations.numeric.know %>%
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_know.var.total

df_occupations.numeric.context %>%
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_context.var.total

# Variance proportionality (how much each category contributes to total variance)
dbl_occupations.var.total

sum(
  dbl_skills.var.total
  , dbl_ablt.var.total
  , dbl_know.var.total
  , dbl_context.var.total
)

dbl_skills.var.pct <- dbl_skills.var.total / dbl_occupations.var.total
dbl_ablt.var.pct <- dbl_ablt.var.total / dbl_occupations.var.total
dbl_know.var.pct <- dbl_know.var.total / dbl_occupations.var.total
dbl_context.var.pct <- dbl_context.var.total / dbl_occupations.var.total

# Define number of items in the questionnaire
dbl_items.total <- 60

# Pick N items from each category in proportion to total variability
dbl_skills.items <- dbl_skills.var.pct * dbl_items.total
dbl_ablt.items <- dbl_ablt.var.pct * dbl_items.total
dbl_know.items <- dbl_know.var.pct * dbl_items.total
dbl_context.items <- dbl_context.var.pct * dbl_items.total

dbl_skills.items <- round(dbl_skills.items)
dbl_ablt.items <- round(dbl_ablt.items)
dbl_know.items <- round(dbl_know.items)
dbl_context.items <- round(dbl_context.items)

dbl_skills.items
dbl_ablt.items
dbl_know.items
dbl_context.items

sum(
  dbl_skills.items
  , dbl_ablt.items
  , dbl_know.items
  , dbl_context.items
)


# # ITEMS PER CATEGORY PARAMETERS 1 -------------------------------------------
# # Manually define number of items
# .int_n.items.total.skill <- 6
# .int_n.items.total.ablt <- 12
# .int_n.items.total.know <- 12
# .int_n.items.total.context <- 15

# ITEMS PER CATEGORY PARAMETERS 2 -------------------------------------------
# Manually define number of items
.int_n.items.total.skill <- 6
.int_n.items.total.ablt <- 9
.int_n.items.total.know <- 12
.int_n.items.total.context <- 33

# ITEMS PER CATEGORY PARAMETERS 3 -------------------------------------------
# Manually define number of items
.int_n.items.total.skill <- 8
.int_n.items.total.ablt <- 9
.int_n.items.total.know <- 16
.int_n.items.total.context <- 27

# FACTOR ROTATIONS 1 ---------------------------------------------------------
.chr_rotation.skill <- 'promax'
.chr_rotation.ablt <- 'promax'
.chr_rotation.know <- 'promax'
.chr_rotation.context <- 'promax'

# FACTOR ROTATIONS 2 ---------------------------------------------------------
# .chr_rotation.skill <- 'varimax'
.chr_rotation.skill <- 'promax'
.chr_rotation.ablt <- 'promax'
# .chr_rotation.know <- 'varimax'
.chr_rotation.know <- 'promax'
.chr_rotation.context <- 'varimax'

# # GLOBAL EFA PARAMETERS 1 ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# # int_nfactors.vector <- seq(1,5)
# 
# # Minimum factor size
# .int_min.factor_size.basic <- 2
# .int_min.factor_size <- 3
# 
# # Top items
# .int_n.items.total.basic <- 5
# .int_n.items.total.cross <- 10
# 
# .int_n.items.total.skill <- 15
# .int_n.items.total.ablt <- 20
# .int_n.items.total.know <- 15
# 
# .remove_unacceptable_MSAi.items <- T

# # Underloadings and crossloadings
# .remove_under_loading.items <- F
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.4 #Lesser than 0.4 loading <- under loading
# # .dbl_cross_loading.threshold <- 0.05 #Lesser than 0.05 loading difference <- cross loading
# .dbl_cross_loading.threshold <- 0.25
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T

# # GLOBAL EFA PARAMETERS 2 ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# # int_nfactors.vector <- seq(1,5)
# 
# # Minimum factor size
# .int_min.factor_size.basic <- 2
# .int_min.factor_size <- 3
# 
# # Top items
# .int_n.items.total.basic <- 5
# .int_n.items.total.cross <- 10
# 
# .int_n.items.total.skill <- 15
# .int_n.items.total.ablt <- 20
# .int_n.items.total.know <- 15
# 
# .remove_unacceptable_MSAi.items <- T
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.3 #Lesser than 0.4 loading <- under loading
# # .dbl_cross_loading.threshold <- 0.05 #Lesser than 0.05 loading difference <- cross loading
# .dbl_cross_loading.threshold <- 0.3
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T

# # GLOBAL EFA PARAMETERS 3 ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# # int_nfactors.vector <- seq(1,5)
# 
# # Minimum factor size
# # .int_min.factor_size.basic <- 2
# .int_min.factor_size <- 3
# 
# # Top items
# # .int_n.items.total.basic <- 5
# # .int_n.items.total.cross <- 10
# 
# .int_n.items.total.skill <- 14
# .int_n.items.total.ablt <- 16
# .int_n.items.total.know <- 12
# 
# .remove_unacceptable_MSAi.items <- T
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.3 #Lesser than 0.4 loading <- under loading
# # .dbl_cross_loading.threshold <- 0.05 #Lesser than 0.05 loading difference <- cross loading
# .dbl_cross_loading.threshold <- 0.35
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T

# # *GLOBAL EFA PARAMETERS 4* ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# # int_nfactors.vector <- seq(1,5)
# 
# # Minimum factor size
# # .int_min.factor_size.basic <- 2
# .int_min.factor_size <- 3
# 
# # Top items
# # .int_n.items.total.basic <- 5
# # .int_n.items.total.cross <- 10
# 
# .int_n.items.total.skill <- 6
# .int_n.items.total.ablt <- 12
# .int_n.items.total.know <- 12
# 
# .remove_unacceptable_MSAi.items <- T
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.3 #Lesser than 0.4 loading <- under loading
# # .dbl_cross_loading.threshold <- 0.05 #Lesser than 0.05 loading difference <- cross loading
# .dbl_cross_loading.threshold <- 0.35
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T

# # GLOBAL EFA PARAMETERS 5 ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# # int_nfactors.vector <- seq(1,5)
# 
# # Minimum factor size
# # .int_min.factor_size.basic <- 2
# .int_min.factor_size <- 3
# 
# # Top items
# # .int_n.items.total.basic <- 5
# # .int_n.items.total.cross <- 10
# 
# .int_n.items.total.skill <- 8
# .int_n.items.total.ablt <- 12 #don't edit
# .int_n.items.total.know <- 12
# .int_n.items.total.context <- 12
# 
# .remove_unacceptable_MSAi.items <- T
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.4 #Lesser than 0.4 loading <- under loading
# # .dbl_cross_loading.threshold <- 0.05 #Lesser than 0.05 loading difference <- cross loading
# .dbl_cross_loading.threshold <- 0.35
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T

# # GLOBAL EFA PARAMETERS 6 ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# # int_nfactors.vector <- seq(1,5)
# 
# # Minimum factor size
# # .int_min.factor_size.basic <- 2
# .int_min.factor_size <- 3
# 
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.4 #Lesser than 0.4 loading <- under loading
# # .dbl_cross_loading.threshold <- 0.05 #Lesser than 0.05 loading difference <- cross loading
# .dbl_cross_loading.threshold <- 0.35
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T

# # GLOBAL EFA PARAMETERS 7 ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# 
# # Minimum factor size
# .int_min.factor_size <- 3
# 
# .remove_unacceptable_MSAi.items <- T
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.4
# .dbl_cross_loading.threshold <- 0.2
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T

# # GLOBAL EFA PARAMETERS 8 * ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# 
# # Minimum factor size
# .int_min.factor_size <- 3
# 
# .remove_unacceptable_MSAi.items <- T
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.4
# .dbl_cross_loading.threshold <- 0.3
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T

# # GLOBAL EFA PARAMETERS 9 ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# 
# # Minimum factor size
# .int_min.factor_size <- 3
# 
# .remove_unacceptable_MSAi.items <- T
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.4
# .dbl_cross_loading.threshold <- 0.35
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- T
# 
# # GLOBAL EFA PARAMETERS 10 ---------------------------------------------------
# # Number of factors
# .auto_select.nfactors <- T
# 
# # Minimum factor size
# .int_min.factor_size <- 3
# 
# .remove_unacceptable_MSAi.items <- T
# # Underloadings and crossloadings
# .remove_under_loading.items <- T
# .remove_cross_loading.items <- T
# .dbl_under_loading.threshold <- 0.4
# .dbl_cross_loading.threshold <- 0.4
# 
# # Diagrams and tests
# .show_diagrams <- T
# .show_results <- F
# 
# GLOBAL EFA PARAMETERS 11 ---------------------------------------------------
# Number of factors
.auto_select.nfactors <- T

# Minimum factor size
.int_min.factor_size <- 3

.remove_unacceptable_MSAi.items <- T
# Underloadings and crossloadings
.remove_under_loading.items <- T
.remove_cross_loading.items <- F
.dbl_under_loading.threshold <- 0.4
.dbl_cross_loading.threshold <- 0.3

# Diagrams and tests
.show_diagrams <- T
.show_results <- T

# GLOBAL EFA PARAMETERS 12 ---------------------------------------------------
# Number of factors
.auto_select.nfactors <- T

# Minimum factor size
.int_min.factor_size <- 3

.remove_unacceptable_MSAi.items <- T
# Underloadings and crossloadings
.remove_under_loading.items <- T
.remove_cross_loading.items <- F
.dbl_under_loading.threshold <- 0.5
.dbl_cross_loading.threshold <- 0.3

# Diagrams and tests
.show_diagrams <- T
.show_results <- T

# * GLOBAL EFA PARAMETERS 13 * ---------------------------------------------------
# Number of factors
.auto_select.nfactors <- T

# Minimum factor size
.int_min.factor_size <- 3

.remove_unacceptable_MSAi.items <- T
# Underloadings and crossloadings
.remove_under_loading.items <- T
.remove_cross_loading.items <- T
.dbl_under_loading.threshold <- 0.5
.dbl_cross_loading.threshold <- 0.2

# Diagrams and tests
.show_diagrams <- T
.show_results <- T

# ----- EFA ---------------------------------------------------------------
# FULLY AUTOMATED EFA WORKFLOW (ONLY STAGE ONE) --------------------------------------------
# Skills
fun_best.model.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.skill
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .chr_rotation = .chr_rotation.skill
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Skill.1

# Abilities
fun_best.model.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.ablt
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .chr_rotation = .chr_rotation.ablt
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Ablt.1

# Knowledge
fun_best.model.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.know
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .chr_rotation = .chr_rotation.know
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Know.1

# Work context
fun_best.model.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.context
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .chr_rotation = .chr_rotation.context
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Context.1

# Work activities
fun_best.model.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.activities
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .chr_rotation = .chr_rotation.activities
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Activities.1

# FULLY AUTOMATED EFA WORKFLOW (WITH TOP ITEMS) --------------------------------------------
# Skills
fun_best.model.top.items.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.skill
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .int_n.items.total = .int_n.items.total.skill
  , .chr_rotation = .chr_rotation.skill
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Skill

# Abilities
fun_best.model.top.items.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.ablt
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .int_n.items.total = .int_n.items.total.ablt
  , .chr_rotation = .chr_rotation.ablt
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Ablt

# Knowledge
fun_best.model.top.items.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.know
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .int_n.items.total = .int_n.items.total.know
  , .chr_rotation = .chr_rotation.know
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Know

# Work context
fun_best.model.top.items.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.context
  , .auto_select.nfactors = .auto_select.nfactors
  , .int_min.factor_size = .int_min.factor_size
  , .int_n.items.total = .int_n.items.total.context
  , .chr_rotation = .chr_rotation.context
  , .remove_unacceptable_MSAi.items = .remove_unacceptable_MSAi.items
  # Underloadings and crossloadings
  , .remove_under_loading.items = .remove_under_loading.items
  , .remove_cross_loading.items = .remove_cross_loading.items
  , .dbl_under_loading.threshold = .dbl_under_loading.threshold
  , .dbl_cross_loading.threshold = .dbl_cross_loading.threshold
  # Diagrams and tests
  , .show_diagrams = .show_diagrams
  , .show_results = .show_results
) -> EFA_Context

# FIX FIELDS OF KNOWLEDGE EFA --------------------------------------------
# Knowledge
fun_best.model.top.items.workflow(
  # Basic
  .df_data.numeric = df_occupations.numeric.know
  , .auto_select.nfactors = T
  , .int_min.factor_size = 3
  # , .int_n.items.total = 12
  , .int_n.items.total = 16
  , .chr_rotation = 'promax'
  # , .chr_rotation = 'varimax'
  # promax > varimax
  , .remove_unacceptable_MSAi.items = T
  # Underloadings and crossloadings
  , .remove_under_loading.items = T
  , .remove_cross_loading.items = F
  # , .dbl_under_loading.threshold = 0.4
  , .dbl_under_loading.threshold = 0.5
  , .dbl_cross_loading.threshold = 0.4
  # Diagrams and tests
  , .show_diagrams = T
  , .show_results = T
) -> EFA_Know

# Internal consistency
EFA_Know$best.model$EFA.top.items$reliability.evaluation

EFA_Know$best.models.evaluation %>% view()
EFA_Know$all.models.evaluation %>% view()

EFA_Know$EFA.workflow$EFA.top.items$EFA.2Factors$reliability.evaluation %>% view()
EFA_Know$EFA.workflow$EFA.top.items$EFA.3Factors$reliability.evaluation %>% view()
EFA_Know$EFA.workflow$EFA.top.items$EFA.4Factors$reliability.evaluation %>% view()
EFA_Know$EFA.workflow$EFA.top.items$EFA.5Factors$reliability.evaluation %>% view()

# Rotation
EFA_Know$best.model$EFA.top.items$suggested.rotation

EFA_Know$EFA.workflow$EFA.top.items$EFA.2Factors$suggested.rotation
EFA_Know$EFA.workflow$EFA.top.items$EFA.3Factors$suggested.rotation
EFA_Know$EFA.workflow$EFA.top.items$EFA.4Factors$suggested.rotation

# Top items 
EFA_Know$EFA.workflow$top.items$EFA.2Factors %>% view()
EFA_Know$EFA.workflow$top.items$EFA.3Factors %>% view()
EFA_Know$EFA.workflow$top.items$EFA.4Factors %>% view()
EFA_Know$EFA.workflow$top.items$EFA.5Factors %>% view()


# ----- EVALUATION --------------------------------------------------------
# COMPARING ONE STAGE WITH TWO STAGE EFA --------------------------------
# Skills
EFA_Skill$best.model$EFA.top.items$reliability.evaluation
EFA_Skill.1$best.model$reliability.evaluation

EFA_Skill$best.models.evaluation %>% view()
EFA_Skill.1$best.models.evaluation %>% view()
EFA_Skill$all.models.evaluation %>% view()

EFA_Skill$EFA.workflow$EFA.top.items$EFA.2Factors$reliability.evaluation %>% view()

# Abilities
EFA_Ablt$best.model$EFA.top.items$reliability.evaluation
EFA_Ablt.1$best.model$reliability.evaluation

EFA_Ablt$best.models.evaluation %>% view()
EFA_Ablt.1$best.models.evaluation %>% view()
EFA_Ablt$all.models.evaluation %>% view()

EFA_Ablt$best.model$EFA.top.items$reliability.evaluation %>% view()
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.2Factors$reliability.evaluation %>% view()
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.3Factors$reliability.evaluation %>% view()
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.4Factors$reliability.evaluation %>% view()

# Fields of Knowledge
EFA_Know$best.model$EFA.top.items$reliability.evaluation
EFA_Know.1$best.model$reliability.evaluation

EFA_Know$best.models.evaluation %>% view()
EFA_Know.1$best.models.evaluation %>% view()
EFA_Know$all.models.evaluation %>% view()

EFA_Know$EFA.workflow$EFA.top.items$EFA.2Factors$reliability.evaluation %>% view()
EFA_Know$EFA.workflow$EFA.top.items$EFA.3Factors$reliability.evaluation %>% view()
EFA_Know$EFA.workflow$EFA.top.items$EFA.4Factors$reliability.evaluation %>% view()
EFA_Know$EFA.workflow$EFA.top.items$EFA.5Factors$reliability.evaluation %>% view()

# Work context
EFA_Context$best.model$EFA.top.items$reliability.evaluation
EFA_Context.1$best.model$reliability.evaluation

EFA_Context$best.models.evaluation %>% view()
EFA_Context.1$best.models.evaluation %>% view()
EFA_Context$all.models.evaluation %>% view()

EFA_Context$EFA.workflow$EFA.top.items$EFA.2Factors$reliability.evaluation %>% view()
EFA_Context$EFA.workflow$EFA.top.items$EFA.3Factors$reliability.evaluation %>% view()

# FACTOR ADEQUACY TESTS --------------------------------
# Skills
EFA_Skill$best.model$EFA.top.items$adequacy.tests
EFA_Skill.1$best.model$adequacy.tests

EFA_Skill$EFA.workflow$EFA.top.items$EFA.2Factors$adequacy.tests

# Abilities
EFA_Ablt$best.model$EFA.top.items$adequacy.tests
EFA_Ablt.1$best.model$adequacy.tests

EFA_Ablt$best.model$EFA.top.items$adequacy.tests
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.2Factors$adequacy.tests
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.3Factors$adequacy.tests
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.4Factors$adequacy.tests

# Fields of Knowledge
EFA_Know$best.model$EFA.top.items$adequacy.tests
EFA_Know.1$best.model$adequacy.tests

EFA_Know$EFA.workflow$EFA.top.items$EFA.2Factors$adequacy.tests
EFA_Know$EFA.workflow$EFA.top.items$EFA.3Factors$adequacy.tests
EFA_Know$EFA.workflow$EFA.top.items$EFA.4Factors$adequacy.tests

# Work context
EFA_Context$best.model$EFA.top.items$adequacy.tests
EFA_Context.1$best.model$adequacy.tests

EFA_Context$EFA.workflow$EFA.top.items$EFA.2Factors$adequacy.tests
EFA_Context$EFA.workflow$EFA.top.items$EFA.3Factors$adequacy.tests

# FACTOR CORRELATION AND REDUNDANCY --------------------------------
# Skills
EFA_Skill$best.model$EFA.top.items$factor.correlation
EFA_Skill.1$best.model$factor.correlation

EFA_Skill$EFA.workflow$EFA.top.items$EFA.2Factors$factor.correlation

# Abilities
EFA_Ablt$best.model$EFA.top.items$factor.correlation
EFA_Ablt.1$best.model$factor.correlation

EFA_Ablt$best.model$EFA.top.items$factor.correlation
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.2Factors$factor.correlation
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.3Factors$factor.correlation
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.4Factors$factor.correlation

# Fields of Knowledge
EFA_Know$best.model$EFA.top.items$factor.correlation
EFA_Know.1$best.model$factor.correlation

EFA_Know$EFA.workflow$EFA.top.items$EFA.2Factors$factor.correlation
EFA_Know$EFA.workflow$EFA.top.items$EFA.3Factors$factor.correlation
EFA_Know$EFA.workflow$EFA.top.items$EFA.4Factors$factor.correlation

# Work context
EFA_Context$best.model$EFA.top.items$factor.correlation
EFA_Context.1$best.model$factor.correlation

EFA_Context$EFA.workflow$EFA.top.items$EFA.2Factors$factor.correlation
EFA_Context$EFA.workflow$EFA.top.items$EFA.3Factors$factor.correlation

# SUGGESTED ROTATION --------------------------------
# Skills
EFA_Skill$best.model$EFA.top.items$suggested.rotation
EFA_Skill.1$best.model$suggested.rotation

EFA_Skill$EFA.workflow$EFA.top.items$EFA.2Factors$suggested.rotation

# Abilities
EFA_Ablt$best.model$EFA.top.items$suggested.rotation
EFA_Ablt.1$best.model$suggested.rotation

EFA_Ablt$best.model$EFA.top.items$suggested.rotation
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.2Factors$suggested.rotation
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.3Factors$suggested.rotation
EFA_Ablt$EFA.workflow$EFA.top.items$EFA.4Factors$suggested.rotation

# Fields of Knowledge
EFA_Know$best.model$EFA.top.items$suggested.rotation
EFA_Know.1$best.model$suggested.rotation

EFA_Know$EFA.workflow$EFA.top.items$EFA.2Factors$suggested.rotation
EFA_Know$EFA.workflow$EFA.top.items$EFA.3Factors$suggested.rotation
EFA_Know$EFA.workflow$EFA.top.items$EFA.4Factors$suggested.rotation

# Work context
EFA_Context$best.model$EFA.top.items$suggested.rotation
EFA_Context.1$best.model$suggested.rotation

EFA_Context$EFA.workflow$EFA.top.items$EFA.2Factors$suggested.rotation
EFA_Context$EFA.workflow$EFA.top.items$EFA.3Factors$suggested.rotation

# TOP ITEMS ---------------------------------------------------------------
# Skills
# EFA_Skill$best.model$top.items %>% view()
EFA_Skill$EFA.workflow$top.items$EFA.2Factors %>% view()
# EFA_Skill$EFA.workflow$top.items$EFA.3Factors %>% view()

# The two factors model is most reliable and most interpretable.

# Abilities
# EFA_Ablt$best.model$top.items %>% view()
# EFA_Ablt$EFA.workflow$top.items$EFA.2Factors %>% view()
EFA_Ablt$EFA.workflow$top.items$EFA.3Factors %>% view()
EFA_Ablt$EFA.workflow$top.items$EFA.4Factors %>% view()

# All models are highly reliable. However, the four factors is most interpretable.

# Knowledge
# EFA_Know$best.model$top.items %>% view()

EFA_Know$EFA.workflow$top.items$EFA.2Factors %>% view()
EFA_Know$EFA.workflow$top.items$EFA.3Factors %>% view()
EFA_Know$EFA.workflow$top.items$EFA.4Factors %>% view()
EFA_Know$EFA.workflow$top.items$EFA.5Factors %>% view()

# Work context
# EFA_Context$best.model$top.items %>% view()
EFA_Context$EFA.workflow$top.items$EFA.3Factors %>% view()

# Both the two and three factors models are internally consistent.
# However, the three factors model is more interpretable and has the correct amount of items (15).

# ----- CHOOSE MODELS AND EXPORT ------------------------------------------------
# CHOSEN MODELS ------------------------------------------------------------------
# Revised and selected models
# Skills => 2 factors
chr_Skill.Model <- 'EFA.2Factors'
# Abilities => 3 factors
chr_Ablt.Model <- 'EFA.3Factors'
# Fields of Knowledge => 4 factors
chr_Know.Model <- 'EFA.4Factors'
# Work Contexts => 3 factors
chr_Context.Model <- 'EFA.3Factors'

# OUTPUT ------------------------------------------------------------------
# Revised and selected models
# Skills
chr_Skill.Items <- EFA_Skill$EFA.workflow$top.items[[chr_Skill.Model]]$Item
# Abilities
chr_Ablt.Items <- EFA_Ablt$EFA.workflow$top.items[[chr_Ablt.Model]]$Item 
# Fields of Knowledge
chr_Know.Items <- EFA_Know$EFA.workflow$top.items[[chr_Know.Model]]$Item
# Work Contexts
chr_Context.Items <- EFA_Context$EFA.workflow$top.items[[chr_Context.Model]]$Item

# ----- RETAINED VARIANCE VS DIMENSIONALITY REDUCTION ---------------------
# RETAINED VARIANCE ------------------------------------------------
df_occupations.numeric %>%
  select(all_of(c(
    chr_Skill.Items
    , chr_Ablt.Items
    , chr_Know.Items
    , chr_Context.Items
  ))
  ) -> df_occupations.numeric.items

df_occupations.numeric.items %>% 
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_occupations.var.items

df_occupations.numeric.skill %>%
  select(all_of(c(
    chr_Skill.Items
  ))
  ) %>% 
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_skills.var.items

df_occupations.numeric.ablt %>%
  select(all_of(c(
    chr_Ablt.Items
  ))
  ) %>%
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_ablt.var.items

df_occupations.numeric.know %>%
  select(all_of(c(
    chr_Know.Items
  ))
  ) %>%
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_know.var.items

df_occupations.numeric.context %>%
  select(all_of(c(
    chr_Context.Items
  ))
  ) %>%
  summarise(
    across(
      .cols = everything()
      ,.fns = var
    )
  ) %>%
  rowSums() -> dbl_context.var.items

# Retained variance vs. Dimensionality (Overall)
dbl_occupations.var.total
dbl_occupations.var.items

ncol(df_occupations.numeric)
ncol(df_occupations.numeric.items)

dbl_occupations.var.items / dbl_occupations.var.total
ncol(df_occupations.numeric.items) / ncol(df_occupations.numeric)

dbl_occupations.var.total / dbl_occupations.var.items
ncol(df_occupations.numeric) / ncol(df_occupations.numeric.items)

# Retained variance vs. Dimensionality (Skills)
dbl_skills.var.total
dbl_skills.var.items

ncol(df_occupations.numeric.skill)
length(chr_Skill.Items)

dbl_skills.var.items / dbl_skills.var.total
length(chr_Skill.Items) / ncol(df_occupations.numeric.skill)

dbl_skills.var.total / dbl_skills.var.items
ncol(df_occupations.numeric.skill) / length(chr_Skill.Items)

# Retained variance vs. Dimensionality (Abilities)
dbl_ablt.var.total
dbl_ablt.var.items

ncol(df_occupations.numeric.ablt)
length(chr_Ablt.Items)

dbl_ablt.var.items / dbl_ablt.var.total
length(chr_Ablt.Items) / ncol(df_occupations.numeric.ablt)

dbl_ablt.var.total / dbl_ablt.var.items
ncol(df_occupations.numeric.ablt) / length(chr_Ablt.Items)

# Retained variance vs. Dimensionality (Knowledge)
dbl_know.var.total
dbl_know.var.items

ncol(df_occupations.numeric.know)
length(chr_Know.Items)

dbl_know.var.items / dbl_know.var.total
length(chr_Know.Items) / ncol(df_occupations.numeric.know)

dbl_know.var.total / dbl_know.var.items
ncol(df_occupations.numeric.know) / length(chr_Know.Items)

# Retained variance vs. Dimensionality (Work contexts)
dbl_context.var.total
dbl_context.var.items

ncol(df_occupations.numeric.context)
length(chr_Context.Items)

dbl_context.var.items / dbl_context.var.total
length(chr_Context.Items) / ncol(df_occupations.numeric.context)

dbl_context.var.total / dbl_context.var.items
ncol(df_occupations.numeric.context) / length(chr_Context.Items)
