# region: imports
box::use()

# endregion
# region: method 1 name
function1.method1 <- function() {
  # assert args in main function
  # description
  return("method1")
}

# endregion
# region: method 2 name
function1.method2 <- function() {
  # assert args in main function
  # description
  return("method2")
}

# endregion
# region: generic function
function1 <- function(function1_method = c("method1", "method2")[[1]], ...) {
  # assert args
  stopifnot(
    "'function1_method' must be one of the following methods: 'method1', 'method2'." = any(
      function1_method == c("method1", "method2")
    )
  )

  # multiple dispatch
  function1_method[[1]] |>
    as.character() |>
    switch(
      "method1" = return(function1.method1()),
      "method2" = return(function1.method2())
    )
}

# endregion
# region: exports
box::export(function1)

# endregion