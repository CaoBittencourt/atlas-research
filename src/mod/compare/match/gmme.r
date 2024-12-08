gmme <- function(skill_set, skill_mtx, weights = NULL, zeros = 1 / 100) {
  # assert args in main function
  # skill_set: a skill set in the unit interval to compare with skill_mtx
  # skill_mtx: a skill set matrix in the unit interval to compare with skill_set
  # weights: a vector of attribute weights for each skill set in skill_mtx
  # zeros: a number to substitute zeros so that the whole expression is not null when an attribute is zero

  # estimate similarity as geometric mean of relative attribute scores
  (skill_set |> pmax(zeros) / skill_mtx) |> pmin(1) -> mtx_prod
  (mtx_prod^weights) |> apply(2, prod) -> mtx_prod
  mtx_prod^(1 / length(skill_set)) -> mtx_prod
  return(mtx_prod)
}

# runif(120) -> ss

# replicate(
#   n = 873,
#   runif(120)
# ) -> mtx_ss

# library(atlas.aeq)
# mtx_ss |> apply(2, fun_aeq_aequivalence) -> mtx_aeq

# mtx_ss |> dim()
# mtx_aeq |> dim()
# (mtx_ss^mtx_aeq) |> dim()
# ss |> length()

# gmme(ss, mtx_ss, mtx_aeq)
