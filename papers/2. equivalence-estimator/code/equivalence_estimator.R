# [SETUP] -----------------------------------------------------------------
# - Packages ----------------------------------------------------------------
chr_pkg <- c(
  'devtools' #GitHub packages
  , 'readr' #Read and write data
  , 'here' #Path to current file
  , 'tidyr', 'dplyr', 'stringr', 'scales' #Data wrangling
)

# Git packages
chr_git <- c(
  'CaoBittencourt' = 'atlas.match',
  'CaoBittencourt' = 'atlas.intc',
  'CaoBittencourt' = 'atlas.comp',
  'CaoBittencourt' = 'atlas.aeq'
)

# Activate / install CRAN packages
lapply(
  chr_pkg
  , function(pkg){
    
    if(!require(pkg, character.only = T)){
      
      install.packages(pkg, dependencies = T)
      
    }
    
    require(pkg, character.only = T)
    
  }
)

# Activate / install Git packages
Map(
  function(git, profile){
    
    if(!require(git, character.only = T)){
      
      install_github(
        paste0(profile, '/', git)
        , dependencies = T
        , upgrade = F
        , force = T
      )
      
    }
    
    require(git, character.only = T)
    
  }
  , git = chr_git
  , profile = names(chr_git)
)

# - Data ------------------------------------------------------------------
# Occupations data frame
df_occupations <- read_csv(here('data/df_occupations_2022.csv'))

# Attribute names
df_attribute_names <- read_csv('https://docs.google.com/spreadsheets/d/e/2PACX-1vStiX7PF7ltnjqVTCLJchWtaAW_BhVCwUM1hRCXGolCOLCS8mCygyde6FfhcvhZiAvke-tujkTBpXoA/pub?gid=0&single=true&output=csv')

# [DATA] ------------------------------------------------------------------
# - Matching data frame ---------------------------------------------------
# Competencies only
df_occupations %>%
  select(
    occupation,
    starts_with('skl_'),
    starts_with('abl_'),
    starts_with('knw_')
  ) -> df_matching

# - dsds ------------------------------------------------------------------
df_matching %>% 
  filter(
    occupation %in% c(
      'Mechanical Engineers',
      'Physicists',
      'Credit Analysts',
      'Dishwashers'
    )
  ) %>% 
  slice(
    2, 3, 1, 4
  ) -> dsds

fun_match_similarity(
  df_data_rows = dsds
  , df_query_rows = dsds
  # , chr_method = 'euclidean'
  # , chr_method = 'logit'
  , chr_method = 'pearson'
  , chr_weights = 'linear'
  , dbl_scale_ub = 100
  , dbl_scale_lb = 0
  , chr_id_col = 'occupation'
  , lgc_sort = T
  , lgc_overqualification_sub = F
) -> dsds_linear

fun_match_similarity(
  df_data_rows = dsds
  , df_query_rows = dsds
  # , chr_method = 'euclidean'
  # , chr_method = 'logit'
  , chr_method = 'pearson'
  , chr_weights = 'attribute-eqvl'
  , dbl_scale_ub = 100
  , dbl_scale_lb = 0
  , chr_id_col = 'occupation'
  , lgc_sort = T
  , lgc_overqualification_sub = F
) -> dsds_eqvl

dsds_linear$mtx_similarity
dsds_eqvl$mtx_similarity

# [MODEL] --------------------------------------------------------------
# - Equivalence midpoints to showcase ----------------------------------------
# Use skill set generality as midpoint for attribute equivalence
# Use skill set competence as midpoint for interchangeability
df_matching %>% 
  pivot_longer(
    cols = -1,
    names_to = 'item',
    values_to = 'item_score'
  ) %>% 
  group_by(
    occupation
  ) %>% 
  reframe(
    generality = 
      fun_gene_generality(
        item_score
      ),
    competence = 
      fun_comp_competence(
        dbl_profile = item_score,
        dbl_scale_ub = 100,
        dbl_scale_lb = 0,
        dbl_generality = generality
      )
  ) -> df_midpoint

df_midpoint %>% 
  filter(
    occupation %in% c(
      'Mechanical Engineers',
      'Physicists',
      'Credit Analysts',
      'Dishwashers'
    )
  ) %>% 
  slice(
    2, 3, 1, 4
  )

# - Estimate similarity model ---------------------------------------------------------
# Run equivalence-weighted Euclidean matching
fun_match_similarity(
  # df_data_rows = df_matching
  # , df_query_rows = df_matching
  df_data_rows = 
    df_matching %>% 
    filter(
      occupation %in% c(
        'Mechanical Engineers',
        'Physicists',
        'Credit Analysts',
        'Dishwashers'
      )
    ) %>% 
    slice(
      2, 3, 1, 4
    )
  , df_query_rows = 
    df_matching %>% 
    filter(
      occupation %in% c(
        'Mechanical Engineers',
        'Physicists',
        'Credit Analysts',
        'Dishwashers'
      )
    ) %>% 
    slice(
      2, 3, 1, 4
    )
  , chr_method = 'euclidean'
  , chr_weights = 'attribute-eqvl'
  , dbl_scale_ub = 100
  , dbl_scale_lb = 0
  , chr_id_col = 'occupation'
  , lgc_sort = T
) -> list_matching_aeq

list_matching_aeq$
  mtx_similarity

# - Estimate interchangeability model -------------------------------------
# Apply interchangeability function to similarity scores
list_matching_aeq$
  mtx_similarity %>%
  as_tibble(
    rownames = 'comparison_occupation'
  ) %>%
  pivot_longer(
    cols = -1
    , names_to = 'occupation'
    , values_to = 'similarity'
  ) %>% 
  left_join(
    df_occupations %>% 
      select(
        occupation,
        education_years
      ) %>% 
      rename(
        years_min = 
          education_years
      )
    , by = c(
      'comparison_occupation' = 
        'occupation'
    )
  ) %>%
  left_join(
    df_occupations %>% 
      select(
        occupation,
        education_years
      ) %>% 
      rename(
        years = 
          education_years
      )
    , by = c(
      'occupation' = 
        'occupation'
    )
  ) %>%
  left_join(
    df_midpoint
  ) %>% 
  mutate(
    ß = fun_intc_ss(
      dbl_similarity = similarity
      , dbl_competence = competence
      , dbl_years = years
      , dbl_years_min = years_min
    )
    # , similarity = round(similarity, 4)
    # , ß = round(ß, 4)
    , hireability = fun_eqvl_bin(ß)
  )

# [RESULTS] ---------------------------------------------------------------
# - Select occupations to showcase matching results -----------------------
# Selected occupations
c(
  'Mechanical Engineers',
  'Physicists',
  'Credit Analysts',
  'Dishwashers'
) -> chr_occupations

# Similarity matrix
list_matching_aeq$
  mtx_similarity[
    chr_occupations,
    chr_occupations
  ] -> mtx_similarity

# Interchangeability matrix
list_interchangeability$
  mtx_interchangeability[
    chr_occupations,
    chr_occupations
  ] -> mtx_interchangeability

# - Top 10 matches --------------------------------------------------------
# Select top 10 matches
list_matching_aeq$
  list_similarity[
    chr_occupations
  ] %>% 
  map(head, 11) %>% 
  map(
    as_tibble
    , rownames =
      'Comparison Occupation'
  ) %>% 
  map(
    rename
    , Similarity = 2
  ) -> list_df_top10

# Arrange by similarity
list_df_top10 %>% 
  map(
    arrange
    , -Similarity
  ) -> list_df_top10

# - General descriptive statistics ----------------------------------------
# Descriptive statistics for all clusters
df_occupations %>% 
  mutate(
    market_value = 
      sum(
        employment_variants * 
          wage 
      )
  ) %>% 
  group_by(
    career_cluster
  ) %>% 
  reframe(
    N = n()
    , Employment = sum(
      employment_variants
    )
    , Wage = weighted.mean(
      wage
      , employment_variants
    )
    , `Market Share` = sum(
      wage * employment_variants
    ) / first(market_value)
  ) %>% 
  arrange(desc(
    `Market Share`
  )) -> df_clusters

# Format table
df_clusters %>%
  rename(
    Cluster = career_cluster
  ) %>% 
  mutate(
    Employment = 
      Employment %>% 
      ceiling() %>%
      number(
        big.mark = ','
        , accuracy = 1
      )
    , Wage = dollar(
      Wage
    )
    , `Market Share` = 
      percent(
        `Market Share`
        , .01
      )
  ) -> df_clusters

# - Selected occupations table -----------------------------------------------------
# Descriptive table data
df_occupations %>% 
  filter(
    occupation %in% 
      chr_occupations
  ) %>% 
  select(
    id_soc_code,
    occupation,
    career_cluster,
    employment,
    wage
  ) -> df_desc

# Format descriptive table
df_desc %>% 
  arrange(desc(
    wage
  )) %>% 
  mutate(
    employment = 
      number(employment)
    , wage = dollar(wage, .01)
  ) -> df_desc

c(
  'SOC',
  'Occupation',
  'Cluster',
  'Employment',
  'Wage (2021)'
) -> names(df_desc)

# - Attributes table -----------------------------------------------------
# Descriptive table data 
df_matching %>% 
  filter(
    occupation %in% 
      chr_occupations
  ) %>% 
  left_join(
    chr_occupations %>% 
      as_tibble() %>% 
      rename(
        occupation = 1
      )
  ) %>% 
  pivot_longer(
    cols = -1,
    names_to = 'attribute'
  ) %>% 
  pivot_wider(
    values_from = 'value',
    names_from = 'occupation'
  ) %>% 
  arrange(desc(across(
    .cols = chr_occupations
  ))) -> df_attributes

# Competency names
df_attributes %>% 
  right_join(
    df_attribute_names
  ) %>% 
  select(
    Competency,
    any_of(
      chr_occupations
    )
  ) -> df_attributes

# [EXPORT] ----------------------------------------------------------------
# - Save rds object to save time -----------------------------------------
# Matching results
write_rds(
  x = list_matching_aeq,
  file = here('data/list_matching_aeq.rds')
)

# # - LaTeX tables ----------------------------------------------------------
# # Export general descriptive statistics
# df_clusters %>%
#   xtable::xtable(
#     caption = 'General Occupational Statistics'
#     , align = 'cccccc'
#     , digits = 2
#   ) %>%
#   print(
#     tabular.environment = 'talltblr'
#     , include.rownames = F
#   )
# 
# # Export selected occupations table
# df_desc %>%
#   xtable::xtable(
#     caption = 'Summary of Occupations'
#     , align = 'cccccc'
#     , digits = 2
#   ) %>%
#   print(
#     tabular.environment = 'tabular*'
#     , include.rownames = F
#   )
# 
# # Export top 10 matches
# map2(
#   .x = list_df_top10
#   , .y = names(list_df_top10)
#   , ~ .x %>%
#     xtable::xtable(
#       caption = paste0(
#         'Best Career Matches -- '
#         , .y
#       )
#       , align = 'ccc'
#       , digits = 2
#     ) %>%
#     print(
#       tabular.environment = 'talltblr'
#       , include.rownames = F
#     )
# )
# 
# # Export similarity matrix
# mtx_similarity %>%
#   xtable::xtable(
#     caption = 'Compatibility Matrix'
#     , align = 'ccccc'
#     , digits = 2
#   ) %>%
#   print(
#     tabular.environment = 'tabular*'
#     , include.rownames = F
#   )
# 
# # Export detailed skill sets
# df_attributes %>%
#   xtable::xtable(
#     caption = 'Detailed Skill Sets'
#     , align = 'cccccc'
#     , digits = 0
#   ) %>%
#   print(
#     tabular.environment = 'tabular*'
#     , include.rownames = F
#   )
# 
