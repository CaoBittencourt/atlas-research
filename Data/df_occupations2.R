# -------- SETUP ----------------------------------------------------------
# PACKAGES ----------------------------------------------------------------
pkg <- c(
  'tidyverse' #Data wrangling
  , 'openxlsx' #Export excel
  # , 'blsR' #BLS API
)

# Activate / install packages
lapply(pkg, function(x)
  if(!require(x, character.only = T))
  {install.packages(x); require(x)})

# Package citation
# lapply(pkg, function(x)
#   {citation(package = x)})

# DATA --------------------------------------------------------------------
# Occupations data frame
df_occupations <- readr::read_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vSphzWoCxoNaiaJcQUWKCMqUAT041Q8UqUgM7rSzIwYZb7FhttKJwNgtrFf-r7EgzXHFom4UjLl2ltk/pub?gid=563902602&single=true&output=csv')

# Employment data frame
df_employment <- readr::read_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vRrTsDXdppC3SOiVc_MTWjYTpedHyWJ5kGb1hrWGkcAvOiu9kLLa427WxNnqy3bbQ/pub?gid=1733674948&single=true&output=csv')

# Education data frame
df_education <- readr::read_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vRrTsDXdppC3SOiVc_MTWjYTpedHyWJ5kGb1hrWGkcAvOiu9kLLa427WxNnqy3bbQ/pub?gid=1069252594&single=true&output=csv')

# -------- DATA --------------------------------------------
# OCCUPATIONS DATA FRAME -------------------------------------------------------
# Select only necessary variables
df_occupations %>% 
  mutate(
    code.original = code
    , code = substr(code, 1, 7)
    , .after = code
  ) %>% 
  group_by(code) %>% 
  mutate(
    code.variants = n()
    , .after = code.original
  ) %>% 
  ungroup() %>% 
  select(
    occupation
    , code
    , code.original
    , code.variants
    , entry_level_education
    , annual_wage_2021
    , ends_with('.l') #Using recommended levels
  ) %>% 
  mutate(
    across(
      .cols = ends_with('.l') #Using recommended levels
      , .fns = function(x){x/100}
    )
  ) -> df_occupations

df_occupations %>% 
  select(-ends_with('.l')) -> df_occupations

# EMPLOYMENT DATA FRAME ---------------------------------------------------
df_employment %>%
  group_by(code) %>%
  mutate(
    employment.2021 = max(employment.2021)
  ) %>% 
  ungroup() %>%
  right_join(
    df_occupations
    , by = 'code'
    , suffix = c('.delete','')
  ) %>% 
  select(
    occupation
    , code
    , code.original
    , code.variants
    , everything()
    , -contains('.delete')
  ) %>% 
  unique() -> df_occupations

# EDUCATION DATA FRAME ---------------------------------------------------
df_education %>% 
  right_join(
    df_occupations
    , by = 'code'
    , suffix = c('.delete', '')
  ) %>% 
  select(
    occupation
    , code
    , code.original
    , code.variants
    , everything()
    , -contains('.delete')
  ) %>% 
  unique() -> df_occupations

# # MISSING OCCUPATIONS -----------------------------------------------------
# df_occupations %>%
#   filter(
#     code %in%
#       setdiff(
#         df_occupations$code
#         , df_employment$code
#       )
#   )
# 
# setdiff(
#   df_occupations$code
#   , df_employment$code
# )
# 
# df_employment %>%
#   filter(type == 'Line item') %>%
#   filter(
#     code %in%
#       setdiff(
#         df_employment$code
#         , df_occupations$code
#       )
#   ) %>% 
#   pull(
#     occupation
#   ) %>% view
# 
# setdiff(
#   df_employment$code
#   , df_occupations$code
# )
# 
# # POPULATION-WEIGHTED OCCUPATIONS DATA FRAME -------------------------------------------------------
# df_occupations %>% 
#   drop_na() %>% 
#   mutate(
#     employment2 = employment / code.variants
#     , employment2 = employment2 / min(employment2, na.rm = T)
#     , employment2 = round(employment2)
#     , .after = employment
#   ) %>% 
#   group_by(occupation) %>%
#   slice(rep(1:n(), first(employment2))) %>% 
#   ungroup() -> df_occupations.pop

# -------- EXPORT ----------------------------------------------------
# XLSX --------------------------------------------------------------------
df_occupations %>%
  write.xlsx(
    'df_occupations2.xlsx'
  )
