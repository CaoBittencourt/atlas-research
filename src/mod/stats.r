# install box if not installed
if (!any(utils::installed.packages()[, 1] == "box")) {
  install.packages("box", dependencies = T)
}

# # install modular if not installed
# if (!any(utils::installed.packages()[, 1] == "modular")) {
#   devtools::install_github("CaoBittencourt/modular")
# }

# # objective project root
# modular::project.root(root.name = ".atlas")

# # box module search path
# options(box.path = getwd())

#' @export
box::use(
  gn = stats / gene,
  eq = stats / eqvl,
  cp = stats / comp
)
