# [SETUP] -----------------------------------------------------------------
# - Packages ----------------------------------------------------------------
pkg <- c(
  'bvls'
  , 'fastglm'
  , 'weights'
  # 'atlas.ftools' #Factor analysis tools
  , 'dplyr', 'tidyr', 'purrr' #Data wrangling
  # , 'vctrs' #Data wrangling
  # , 'modeest' #Mode
)

# Activate / install packages
lapply(pkg, function(x)
  if(!require(x, character.only = T))
  {install.packages(x); require(x)})

# Package citation
# lapply(pkg, function(x)
#   {citation(package = x)})

# [EQUIVALENCE FUNCTIONS] ------------------------------------------
# - Equivalence function ------------------------------------
fun_match_equivalence <- function(
    dbl_var
    , dbl_scale_ub = NULL
    , dbl_scaling = 1
){
  
  # Argument validation
  stopifnot(
    "'dbl_var' must be a numeric vector or matrix." =
      is.numeric(dbl_var)
  )
  
  stopifnot(
    "'dbl_scale_ub' must be either NULL or numeric." =
      any(
        is.numeric(dbl_scale_ub)
        , is.null(dbl_scale_ub)
      )
  )
  
  stopifnot(
    "'dbl_scaling' must be numeric." =
      is.numeric(dbl_scaling)
  )
  
  # Normalize data to percentage scale
  if(!all(
    max(dbl_var, na.rm = T) <= 1,
    min(dbl_var, na.rm = T) >= 0
  )){
    
    # Normalize by upper bound, if any
    if(length(dbl_scale_ub)){
      
      dbl_var / 
        dbl_scale_ub -> 
        dbl_var
      
    } else { 
      
      # Normalize by maxima
      dbl_var / 
        max(
          dbl_var
          , na.rm = T
        ) -> dbl_var
      
    }
    
  }
  
  # Calculate equivalence
  dbl_var ^ 
    (
      (1 / dbl_var) ^ 
        (dbl_scaling / dbl_var)
    ) -> dbl_equivalence
  
  # Output
  return(dbl_equivalence)
  
}

# [MATCHING FUNCTIONS] -------------------------------------------------------------
# - Regression weights --------------------------------------------
fun_match_weights <- function(
    dbl_var
    , dbl_scaling = 0.25
){
  
  # Argument validation
  stopifnot(
    "'dbl_var' must be a numeric vector or matrix." =
      is.numeric(dbl_var)
  )
  
  # Apply equivalence function to regression weights
  fun_match_equivalence(
    dbl_var = dbl_var
    , dbl_scaling =
      dbl_scaling
  ) -> dbl_weights
  
  # Output
  return(dbl_weights)
  
}

# - Vectorized regression weights -----------------------------------------
fun_match_vweights <- function(
    df_data_cols
    , dbl_scaling = 0.25 
){
  
  # Arguments validation
  stopifnot(
    "'df_data_cols' must be a data frame." =
      is.data.frame(df_data_cols)
  )
  
  # Data wrangling
  df_data_cols %>% 
    select(where(
      is.numeric
    )) -> df_data_cols
  
  # Map weights function
  map_df(
    .x = df_data_cols
    , ~ fun_match_weights(
      dbl_var = .x
      , dbl_scaling = 
        dbl_scaling
    )
  ) -> df_data_cols
  
  # Output
  return(df_data_cols)
  
}

# - BVLS regression matching ----------------------------------------------
fun_match_bvls <- function(
    df_data_cols
    , dbl_query
    , df_weights = NULL
){
  
  # Arguments validation
  stopifnot(
    "'df_data_cols' must be a data frame." = 
      is.data.frame(df_data_cols)
  )
  
  stopifnot(
    "'dbl_query' must be numeric." =
      all(
        is.numeric(dbl_query)
        , length(dbl_query) ==
          nrow(df_data_cols)
      )
  )
  
  stopifnot(
    "'df_weights' must be either NULL or a numeric data frame." = 
      any(
        all(map_lgl(df_weights, is.numeric))
        , is.null(df_weights)
      )
  )
  
  # BVLS regression
  if(!length(df_weights)){
    
    # Run BVLS regression matching without weights
    map_dbl(
      .x = df_data_cols
      , ~ 
        coef(bvls(
          as.matrix(.x)
          , dbl_query[,]
          , bl = 0
          , bu = 1
        ))
    ) -> dbl_similarity
    
  } else {
    
    # Add weights to regression 
    sqrt(df_weights) ->
      df_weights
    
    df_data_cols *
      df_weights ->
      df_data_cols
    
    # BVLS regression matching with weights
    map2_dbl(
      .x = df_data_cols
      , .y = df_weights
      , ~
        coef(bvls(
          as.matrix(.x)
          , dbl_query[,] * .y
          , bl = 0
          , bu = 1
        ))
    ) -> dbl_similarity
    
  }
  
  # Output
  return(dbl_similarity)
  
}

# - Pearson correlation matching ----------------------------------------------
fun_match_pearson <- function(
    df_data_cols
    , dbl_query
    , df_weights = NULL
){
  
  # Arguments validation
  stopifnot(
    "'df_data_cols' must be a data frame." = 
      is.data.frame(df_data_cols)
  )
  
  stopifnot(
    "'dbl_query' must be numeric." = 
      all(
        is.numeric(dbl_query)
        , length(dbl_query) ==
          nrow(df_data_cols)
      )
  )
  
  stopifnot(
    "'df_weights' must be either NULL or a numeric data frame." = 
      any(
        all(map_lgl(df_weights, is.numeric))
        , is.null(df_weights)
      )
  )
  
  # Pearson correlation
  if(!length(df_weights)){
    
    # Pearson correlation matching without weights
    map_dbl(
      .x = df_data_cols
      , ~ (
        1 +
          wtd.cors(
            dbl_query[,]
            , .x
          )[,]
      ) / 2
    ) -> dbl_similarity
    
  } else {
    
    # Pearson correlation matching with weights
    map2_dbl(
      .x = df_data_cols
      , .y = df_weights
      , ~ (
        1 +
          wtd.cors(
            dbl_query[,]
            , .x
            , weight = .y
          )[,]
      ) / 2
    ) -> dbl_similarity
    
  }
  
  # Output
  return(dbl_similarity)
  
}

# - Logistic regression matching ------------------------------------------
fun_match_logit <- function(
    df_data_cols
    , dbl_query
    , dbl_scale_ub
    , dbl_scale_lb
    , chr_method = c('logit', 'probit')
    , df_weights = NULL
){
  
  # Arguments validation
  stopifnot(
    "'df_data_cols' must be a data frame." = 
      is.data.frame(df_data_cols)
  )
  
  stopifnot(
    "'dbl_query' must be numeric." = 
      all(
        is.numeric(dbl_query)
        , length(dbl_query) ==
          nrow(df_data_cols)
      )
  )
  
  stopifnot(
    "'dbl_scale_ub' must be numeric." =
      is.numeric(dbl_scale_ub)
  )
  
  stopifnot(
    "'dbl_scale_lb' must be numeric." =
      is.numeric(dbl_scale_lb)
  )
  
  stopifnot(
    "'chr_method' must be either 'logit' or 'probit'." =
      any(
        chr_method == 'logit',
        chr_method == 'probit'
      )
  )
  
  stopifnot(
    "'df_weights' must be either NULL or a numeric data frame." = 
      any(
        all(map_lgl(df_weights, is.numeric))
        , is.null(df_weights)
      )
  )
  
  # Data wrangling
  dbl_scale_ub[[1]] -> dbl_scale_ub
  
  dbl_scale_lb[[1]] -> dbl_scale_lb
  
  as.integer(dbl_scale_ub) -> dbl_scale_ub
  
  as.integer(dbl_scale_lb) -> dbl_scale_lb
  
  chr_method[[1]] -> chr_method
  
  # Convert query to a Bernoulli variable
  list_c(map(
    .x = as.integer(dbl_query[,])
    , ~ rep(
      c(1,0), times = c(
        .x, (dbl_scale_ub - dbl_scale_lb) - .x
      )
    )
  )) -> int_query_bernoulli
  
  rm(dbl_query)
  
  # Convert data to a Bernoulli variable
  map(
    .x = df_data_cols
    , ~
      as.matrix(list_c(map(
        .x = as.integer(.x)
        , ~ rep(
          c(1,0), times = c(
            .x, (dbl_scale_ub - dbl_scale_lb) - .x
          )
        )
      )))
  ) -> list_data_bernoulli
  
  rm(df_data_cols)
  
  # Logistic regression
  if(!length(df_weights)){
    
    # Run logistic regression matching without weights
    map_dbl(
      .x = list_data_bernoulli
      , ~
        coef(fastglmPure(
          x = .x
          , y = int_query_bernoulli
          , family = binomial(
            link = 'logit'
          )
        ))
    ) -> dbl_similarity
    
    exp(dbl_similarity) /
      (1 + exp(dbl_similarity)) ->
      dbl_similarity
    
  } else {
    
    # Repeat df_weights' rows
    df_weights[rep(
      1:nrow(df_weights)
      , each = 
        dbl_scale_ub - 
        dbl_scale_lb
    ), ] -> df_weights
    
    # Run logistic regression matching with weights
    map2_dbl(
      .x = list_data_bernoulli
      , .y = df_weights
      , ~
        coef(fastglmPure(
          x = .x
          , y = int_query_bernoulli
          , family = binomial(
            link = 'logit'
          ), weights = .y
        ))
    ) -> dbl_similarity
    
    exp(dbl_similarity) /
      (1 + exp(dbl_similarity)) ->
      dbl_similarity
    
  }
  
  # Output
  return(dbl_similarity)
  
}

# - Similarity function (col vectors) ---------------------------------------------------
fun_match_similarity_cols <- function(
    df_data_cols
    , dbl_query
    , chr_method = c('bvls', 'logit', 'probit', 'pearson')
    , dbl_scale_ub = 100
    , dbl_scale_lb = 0
    , df_weights = NULL
    , dbl_scaling = 0.25
    , lgc_sort = F
){
  
  # Argument validation
  stopifnot(
    "'df_data_cols' must be a data frame." =
      is.data.frame(df_data_cols)
  )
  
  stopifnot(
    "'dbl_query' must be numeric." =
      is.numeric(dbl_query)
  )
  
  stopifnot(
    "'chr_method' must be one of the following methods: 'bvls', 'logit', 'probit', or 'pearson'." =
      any(
        chr_method == 'bvls',
        chr_method == 'logit',
        chr_method == 'probit',
        chr_method == 'pearson'
      )
  )
  
  stopifnot(
    "'dbl_scale_ub' must be numeric." =
      is.numeric(dbl_scale_ub)
  )
  
  stopifnot(
    "'dbl_scale_lb' must be numeric." =
      is.numeric(dbl_scale_lb)
  )
  
  stopifnot(
    "'df_weights' must be either NULL or a numeric data frame." = 
      any(
        all(map_lgl(df_weights, is.numeric))
        , is.null(df_weights)
      )
  )
  
  # Data wrangling
  dbl_scale_ub[[1]] -> dbl_scale_ub
  
  dbl_scale_lb[[1]] -> dbl_scale_lb
  
  chr_method[[1]] -> chr_method
  
  # Weights
  if(!length(df_weights)){
    
    fun_match_vweights(
      df_data_cols = 
        df_data_cols
      , dbl_scaling = 
        dbl_scaling
    ) -> df_weights
    
  }
  
  # Apply matching method
  if(chr_method == 'bvls'){
    
    # Apply BVLS regression matching
    fun_match_bvls(
      df_data_cols =
        df_data_cols
      , dbl_query = 
        dbl_query
      , df_weights = 
        df_weights
    ) -> dbl_similarity
    
  } else if(chr_method == 'pearson') {
    
    # Apply Pearson correlation matching
    fun_match_pearson(
      df_data_cols = 
        df_data_cols
      , dbl_query = 
        dbl_query
      , df_weights = 
        df_weights
    ) -> dbl_similarity
    
  } else {
    
    # Apply logistic regression matching
    fun_match_logit(
      df_data_cols = 
        df_data_cols
      , dbl_query = 
        dbl_query
      , dbl_scale_ub = 
        dbl_scale_ub
      , dbl_scale_lb = 
        dbl_scale_lb
      , chr_method = 
        chr_method
      , df_weights = 
        df_weights
    ) -> dbl_similarity
    
  }
  
  # Output
  return(dbl_similarity)
  
}

# - Similarity function (row vectors) ---------------------------------------------------
fun_match_similarity <- function(
    df_data_rows
    , df_query_rows
    , chr_method = c('bvls', 'logit', 'probit', 'pearson')
    , dbl_scale_ub = 100
    , dbl_scale_lb = 0
    , df_weights = NULL
    , dbl_scaling = 0.25
    , chr_id_col = NULL
    , lgc_sort = F
){
  
  # Argument validation
  stopifnot(
    "'df_data_rows' must be a data frame." =
      is.data.frame(df_data_rows)
  )
  
  stopifnot(
    "'df_query_rows' must be a data frame." =
      is.data.frame(df_query_rows)
  )
  
  stopifnot(
    "'chr_method' must be one of the following methods: 'bvls', 'logit', 'probit', or 'pearson'." =
      any(
        chr_method == 'bvls',
        chr_method == 'logit',
        chr_method == 'probit',
        chr_method == 'pearson'
      )
  )
  
  stopifnot(
    "'dbl_scale_ub' must be numeric." =
      is.numeric(dbl_scale_ub)
  )
  
  stopifnot(
    "'dbl_scale_lb' must be numeric." =
      is.numeric(dbl_scale_lb)
  )
  
  stopifnot(
    "'df_weights' must be either NULL or a numeric data frame." = 
      any(
        all(map_lgl(df_weights, is.numeric))
        , is.null(df_weights)
      )
  )
  
  stopifnot(
    "'lgc_sort' must be either TRUE or FALSE." =
      all(
        is.logical(lgc_sort)
        , !is.na(lgc_sort)
      )
  )
  
  stopifnot(
    "'chr_id_col' must be either NULL or a character string." = 
      any(
        is.null(chr_id_col)
        , is.character(chr_id_col)
      )
  )
  
  # Data wrangling
  Filter(
    function(x){all(is.numeric(x))}
    , df_query_rows
  ) -> dbl_query
  
  rm(df_query_rows)
  
  df_data_rows[names(
    dbl_query
  )] -> df_data_cols
  
  # Pivot data
  t(dbl_query) -> 
    dbl_query
  
  as_tibble(t(
    df_data_cols
  )) -> df_data_cols
  
  # Apply similarity function
  if(ncol(dbl_query) == 1){
    
    fun_match_similarity_cols(
      df_data_cols = df_data_cols
      , dbl_query = dbl_query
      , chr_method = chr_method
      , dbl_scale_ub = dbl_scale_ub
      , dbl_scale_lb = dbl_scale_lb
      , df_weights = df_weights
    ) -> df_data_rows$similarity
    
    rm(dbl_query)
    rm(df_weights)
    rm(chr_method)
    rm(dbl_scale_ub)
    rm(dbl_scale_lb)
    rm(df_data_cols)
    
    # Sort data frame
    if(lgc_sort){
      
      df_data_rows %>%
        arrange(desc(
          similarity
        )) -> df_data_rows
      
    }
    
    list_similarity <- NULL
    dbl_similarity <- NULL
    
  } else {
    
    dbl_query %>%
      as_tibble() -> 
      df_query_cols
    
    rm(dbl_query)
    
    df_query_cols %>% 
      map(
        ~ fun_match_similarity_cols(
          df_data_cols = df_data_cols
          # , dbl_query = as.numeric(.x)
          , dbl_query = as.matrix(.x)
          , chr_method = chr_method
          , dbl_scale_ub = dbl_scale_ub
          , dbl_scale_lb = dbl_scale_lb
          , df_weights = df_weights
        )
      ) -> list_similarity
    
    rm(df_weights)
    rm(chr_method)
    rm(dbl_scale_ub)
    rm(dbl_scale_lb)
    
    # Similarity matrix
    if(
      all(
        df_query_cols ==
        df_data_cols
      )
    ){
      
      rm(df_query_cols)
      rm(df_data_cols)
      
      list_similarity %>%
        bind_cols() %>%
        as.matrix() ->
        dbl_similarity
      
      if(length(chr_id_col)){
        
        chr_id_col[[1]] -> chr_id_col
        
        df_data_rows %>%
          pull(!!sym(chr_id_col)) ->
          colnames(
            dbl_similarity
          )
        
        colnames(
          dbl_similarity
        ) -> rownames(
          dbl_similarity
        )
        
        colnames(
          dbl_similarity
        ) -> names(
          list_similarity
        )
        
      }
      
    }
    
    df_data_rows <- NULL
    
  }
  
  # Output
  return(compact(list(
    'df_similarity' = df_data_rows
    , 'list_similarity' = list_similarity
    , 'dbl_similarity' = dbl_similarity
  )))
  
}

# [ATLAS PROFESSIONAL TYPE INDICATOR FUNCTIONS] ---------------------------

# - ACTI estimator helper function --------------------------------------------------------

# - ACTI estimator --------------------------------------------------------

# - ACTI matching ---------------------------------------------------------
# fun_match_equivalence_acti

# [INTERCHANGEABILITY FUNCTIONS] ------------------------------------------
# - Educational equivalence function -------------------------------
fun_match_equivalence_education <- function(
    dbl_years_education
    , dbl_years_education_min
){
  
  # Arguments validation
  stopifnot(
    "'dbl_years_education' must be numeric." = 
      is.numeric(dbl_years_education)
  )
  
  stopifnot(
    "'dbl_years_education_min' must be numeric." = 
      is.numeric(dbl_years_education_min)
  )
  
  # Data wrangling
  rep(
    dbl_years_education
    , each = length(
      dbl_years_education_min
    )) -> dbl_years_education
  
  # Apply equivalence function to years of education
  fun_match_equivalence(
    dbl_var = dbl_years_education
    , dbl_scale_ub = dbl_years_education_min
    , dbl_scaling = dbl_years_education_min
  ) -> dbl_eq_education
  
  rm(dbl_years_education)
  rm(dbl_years_education_min)
  
  # Truncate educational equivalence to [0,1]
  pmin(dbl_eq_education, 1) -> dbl_eq_education
  pmax(dbl_eq_education, 0) -> dbl_eq_education
  
  # Output
  return(dbl_eq_education)
  
}

# - Interchangeability function -------------------------------------------
fun_match_interchangeability <- function(
    dbl_similarity
    , dbl_scaling = 1
    , dbl_years_education = NULL
    , dbl_years_education_min = NULL
){
  
  # Other arguments validation within helper functions
  stopifnot(
    "'dbl_similarity' must be a percentage." = 
      all(
        dbl_similarity >= 0,
        dbl_similarity <= 1
      )
  )
  
  # Data wrangling
  dbl_scaling[[1]] -> dbl_scaling
  
  # Apply equivalence function to similarity scores
  # fun_match_equivalence_similarity
  fun_match_equivalence(
    dbl_var = dbl_similarity
    , dbl_scaling = dbl_scaling
  ) -> dbl_interchangeability
  
  rm(dbl_similarity)
  
  # Apply equivalence function to years of education
  if(all(
    length(dbl_years_education),
    length(dbl_years_education_min)
  )){
    
    fun_match_equivalence_education(
      dbl_years_education = 
        dbl_years_education
      , dbl_years_education_min = 
        dbl_years_education_min
    ) * 
      dbl_interchangeability -> 
      dbl_interchangeability
    
  }
  
  rm(dbl_years_education)
  rm(dbl_years_education_min)
  
  # Apply equivalence function to Atlas Career Type
  # fun_match_equivalence_acti
  
  # Data wrangling
  
  # Output
  return(dbl_interchangeability)
  
}

# [EMPLOYABILITY FUNCTIONS] -----------------------------------------------
# - Employability function -----------------------------------------
fun_match_employability <- function(
    int_employment
    , dbl_interchangeability
){
  
  # Arguments validation
  stopifnot(
    "'int_employment' must be a numeric vector the same length as 'dbl_interchangeability'." =
      all(
        is.numeric(int_employment)
        , length(int_employment) == 
          nrow(cbind(dbl_interchangeability))
      )
  )
  
  stopifnot(
    "'dbl_interchangeability' must be a percentage." = 
      all(
        dbl_interchangeability >= 0,
        dbl_interchangeability <= 1
      )
  )
  
  # Data wrangling
  round(int_employment) -> int_employment
  
  # Percentage of interchangeable job posts
  sum(
    int_employment * 
      dbl_interchangeability
  ) / sum(int_employment) ->
    dbl_employability
  
  # Output
  return(dbl_employability)
  
}

# # [TEST] ------------------------------------------------------------------
# # - Data ------------------------------------------------------------------
# library(readr)
# library(tictoc)
# 
# read_rds(
#   'C:/Users/Cao/Documents/Github/atlas-research/data/efa_model_equamax_15_factors.rds'
# ) -> efa_model
# 
# read_csv(
#   'C:/Users/Cao/Documents/Github/Atlas-Research/Data/df_atlas_complete_equamax_15_factors.csv'
# ) -> df_occupations
# 
# read_csv(
#   'https://docs.google.com/spreadsheets/d/e/2PACX-1vSVdXvQMe4DrKS0LKhY0CZRlVuCCkEMHVJHQb_U-GKF21CjcchJ5jjclGSlQGYa5Q/pub?gid=1515296378&single=true&output=csv'
# ) -> df_input
# 
# # - Equivalence test 1 ------------------------------------------------------
# tic()
# fun_match_equivalence(
#   dbl_var = 1:10
#   , dbl_scale_ub = 19
#   , dbl_scaling = 1
# )
# toc()
# 
# # - Equivalence test 2 ------------------------------------------------------
# tic()
# fun_match_equivalence(
#   dbl_var = 
#     df_occupations %>% 
#     select(ends_with('.l')) %>% 
#     as.matrix() %>%
#     `rownames<-`(
#       df_occupations$
#         occupation
#     )
#   , dbl_scale_ub = NULL
#   , dbl_scaling = 1
# )
# toc()
# 
# # - Regression weights 1 ----------------------------------------------------
# tic()
# fun_match_weights(
#   dbl_var = runif(50, 0, 100)
# )
# toc()
# 
# # - Regression weights 2 --------------------------------------------------
# tic()
# fun_match_vweights(
#   df_data = 
#     df_occupations %>% 
#     select(ends_with('.l')) %>% 
#     t() %>% 
#     as_tibble()
# )
# toc()
# 
# # - BVLS similarity test ------------------------------------------------------------------
# rm(dsds)
# 
# tic()
# fun_match_similarity(
#   df_data_rows = 
#     df_occupations %>% 
#     select(
#       occupation
#       , ends_with('.l')
#     )
#   , chr_method = 'bvls'
#   , df_query_rows = 
#     df_input
#   , dbl_scale_ub = 100
#   , dbl_scale_lb = 0
# ) -> dsds
# toc()
# 
# dsds$
#   df_similarity %>% 
#   select(!ends_with('.l')) %>% 
#   arrange(desc(similarity)) %>% 
#   print(n = nrow(.))
# 
# # - Pearson similarity test ------------------------------------------------------------------
# rm(dsds)
# 
# tic()
# fun_match_similarity(
#   df_data_rows = 
#     df_occupations %>% 
#     select(
#       occupation
#       , ends_with('.l')
#     )
#   , chr_method = 'pearson'
#   , df_query_rows = 
#     df_input
#   , dbl_scale_ub = 100
#   , dbl_scale_lb = 0
# ) -> dsds
# toc()
# 
# dsds$
#   df_similarity %>% 
#   select(!ends_with('.l')) %>% 
#   arrange(desc(similarity)) %>% 
#   print(n = nrow(.))
# 
# # - Logit similarity test ------------------------------------------------------------------
# rm(dsds)
# 
# tic()
# fun_match_similarity(
#   df_data_rows = 
#     df_occupations %>% 
#     select(
#       occupation
#       , ends_with('.l')
#     )
#   , chr_method = 'logit'
#   , df_query_rows = 
#     df_input
#   , dbl_scale_ub = 100
#   , dbl_scale_lb = 0
# ) -> dsds
# toc()
# 
# dsds$
#   df_similarity %>% 
#   select(!ends_with('.l')) %>% 
#   arrange(desc(similarity)) %>% 
#   print(n = nrow(.))
# 
# # - Similarity matrix test ------------------------------------------------
# rm(dsds)
# 
# tic()
# fun_match_similarity(
#   df_data_rows = 
#     df_occupations %>% 
#     slice(1:10) %>%
#     select(
#       occupation
#       , ends_with('.l')
#     )
#   , df_query_rows = 
#     df_occupations %>% 
#     slice(1:10) %>%
#     select(
#       occupation
#       , ends_with('.l')
#     )
#   , chr_method = 'bvls'
#   , dbl_scale_ub = 100
#   , dbl_scale_lb = 0
#   , chr_id_col = 
#     'occupation'
# ) -> dsds
# toc()
# 
# dsds
# 
# # - Educational equivalence -----------------------------------------------
# tic()
# fun_match_equivalence_education(
#   dbl_years_education = c(14, 17, 20, 22)
#   , dbl_years_education_min = c(17, 21, 25)
# ) %>% round(4)
# toc()
# 
# # - Atlas Career Type Indicator test --------------------------------------
# 
# # - Interchangeability test 1 -----------------------------------------------
# fun_match_similarity(
#   df_data_rows = 
#     df_occupations %>% 
#     select(
#       occupation
#       , ends_with('.l')
#     )
#   , df_query_rows = 
#     df_input
#   , chr_method = 'bvls'
#   , dbl_scale_ub = 100
#   , dbl_scale_lb = 0
# ) -> df_similarity
# 
# df_similarity$
#   df_similarity -> 
#   df_similarity
# 
# tic()
# fun_match_interchangeability(
#   dbl_similarity = 
#     df_similarity$
#     similarity
#   , dbl_scaling = 1
# ) %>% round(4)
# toc()
# 
# # - Interchangeability test 2 -----------------------------------------------
# fun_match_similarity(
#   df_data_rows = 
#     df_occupations %>% 
#     select(
#       occupation
#       , ends_with('.l')
#     )
#   , df_query_rows = 
#     df_input
#   , chr_method = 'bvls'
#   , dbl_scale_ub = 100
#   , dbl_scale_lb = 0
# ) -> df_similarity
# 
# df_similarity$
#   df_similarity -> 
#   df_similarity
# 
# tic()
# fun_match_interchangeability(
#   dbl_similarity = 
#     df_similarity$
#     similarity
#   , dbl_scaling = 1
#   , dbl_years_education = 22
#   , dbl_years_education_min = 
#     rep(25, nrow(df_similarity))
# ) %>% round(4)
# toc()
# 
# # - Employability test ----------------------------------------------------
# tic()
# 
# fun_match_employability(
#   int_employment = 
#     df_occupations$
#     employment2
#   , dbl_interchangeability = 
#     df_similarity$
#     similarity %>% 
#     fun_match_interchangeability()
# )
# 
# toc()
