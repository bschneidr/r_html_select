#' Create a dynamic image object containing plots
#'
#' @param sel_id The id of the selector used to choose options
#' @param options A named list of plot objects, with the number of options and names of options matching those used in the selector object.
#' @param fig_output_dir Filepath of the directory where plots should be saved. If unspecified, the default output directory for the current knitr chunk will be used.
#' @param dev The device to be used for saving the plots ('png', 'jpg', 'pdf', etc.)
#' @param fig.width Plot width in inches. This can be a single number or a numeric vector matching the number of options.
#' @param fig.height Plot length in inches.  This can be a single number or a numeric vector matching the number of options.
#' @param dpi The resolution of the image.
#' @param embed A logical vector for whether images should be embedded directly into the HTML code as base64 strings. If FALSE, image files are referred to via links in the HTML code.
#'
#' @return Raw HTML representing the image object. If `embed = FALSE`, image files are created and saved in a directory determined by `fig_output_dir`.
#' @export
#'
#' @examples
#' 
#' \dontrun{
#' ```{r add_js, results='asis'}
#' library(selr)
#' add_javascript()
#' ```
#' 
#' ```{r add_selector, results='asis'}
#' add_selector(
#' sel_id = "Dataset",
#' options = list("Option_1" = "iris",
#'                "Option_2" = "mtcars")
#' )
#' ```
#' 
#' ```{r create_plots}
#' iris_plot <- ggplot(iris, aes(x = Sepal.Length, y = Petal.Length,
#'                     color = Species)) + 
#'              geom_point()
#'              
#' mtcars_plot <- ggplot(mtcars, aes(x = wt, y = mpg,
#'                       color = factor(gear))) +
#'                geom_point()
#' 
#' ```
#' 
#' ```{r image_selector, results='asis'}
#' sel_image(
#' sel_id = "Dataset",
#' options = list("Option_1" = iris_plot,
#'                "Option_2" = mtcars_plot),
#' fig.width = 6, fig.height = 3.25, dpi = 450,
#' embed = TRUE
#' )
#' ```
#' }
#' 
sel_plot <- function(sel_id = "ts_1",
                     options = NULL,
                     fig_output_dir = NULL,
                     dev = 'png', fig.width = NULL, fig.height = NULL, dpi = NULL,
                     embed = TRUE) {
  if (!is.null(dev)) {
    if (length(dev) > 1 & length(dev) != length(options)) {
      stop("If the `dev` argument is used, it must either be length 1 or equal length to the number of options.")
    }
  }
  
  # For the R code chunk where this function is called
  # find out what directory is listed as the place for image files to be saved.
  # Use this directory if the user doesn't specify a directory to be used instead.
  if (is.null(fig_output_dir)) {
    fig_output_dir <- knitr::opts_chunk$get()$fig.path
    # Ensure that the fig_output_dir path uses forward slashes
    fig_output_dir <- gsub(x = fig_output_dir,
                           pattern = "\\\\+", replacement = "/")
    # Ensure that the fig_output_dir doesn't end in a slash
    if (grepl(x = fig_output_dir, pattern = "(/+)|(\\\\+)$")) {
      fig_output_dir <- gsub(pattern = "(/+)|(\\\\+)$", replacement = "",
                             x = fig_output_dir,
                             fixed = FALSE)
    }
  }
  
  # If the user hasn't specified options for figure appearance,
  # use the current R code chunk's options
  
  # Get some of the current R code chunk's options for fig appearance (i.e. width, height, dpi, etc.)
  rel_chunk_fig_params <- knitr::opts_chunk$get()[c("fig.width", "fig.height", "dpi", "dev")]
  
  # Use the R code chunk's options to set unspecified options
  if (is.null(dev)) {
    dev <- rep(rel_chunk_fig_params$dev, 
               length(options))
  }
  if (is.null(dpi)) {
    dpi <- rep(rel_chunk_fig_params$dpi, 
               length(options))
  }
  if (is.null(fig.width)) {
    fig.width <- rep(rel_chunk_fig_params$fig.width, 
                     length(options))
  }
  if (is.null(fig.height)) {
    fig.height <- rep(rel_chunk_fig_params$fig.height, 
                      length(options))
  }
  
  # For the options for figure appearance,
  # make sure that the length of each option matches the number of the plot options
  if (length(dev) == 1) {
    dev <- rep(dev, length(options))
  }
  if (length(dpi) == 1) {
    dpi <- rep(dpi, length(options))
  }
  if (length(fig.width) == 1) {
    fig.width <- rep(fig.width, length(options))
  }
  if (length(fig.height) == 1) {
    fig.height <- rep(fig.height, length(options))
  }
  
  # Create an image file for each plot,
  # saving each image file into the fig_output_dir.
  filepaths <- paste0(fig_output_dir, "/",
                      names(options),
                      ".", 
                      dev)
  
  # Create the necessary `fig_output_dir' if it doesn't exist
  if (!dir.exists(fig_output_dir)) {
    dir.create(fig_output_dir)
  }
  
  for (option_index in seq_len(length(options))) {
    ggplot2::ggsave(plot = options[[option_index]],
                    filename = filepaths[option_index],
                    device = dev[option_index],
                    dpi = dpi[option_index],
                    width = fig.width[option_index], height = fig.height[option_index],
                    units = 'in')
  }
  
  # If the embed option is chosen, then the links to the image files
  # are used to convert the image files to base64 strings so that the images
  # are embedded directly into the HTML document rather than referenced.
  # Otherwise, the newly-created image files are referenced.
  
  if (embed) {
    option_images <- lapply(X = filepaths,
                            FUN = knitr::image_uri)
    names(option_images) <- names(options)
  } else {
    option_images <- stats::setNames(as.list(filepaths),
                                     names(options))
  }
  
  # Convert the options to JSON
  result_list_data <- jsonlite::toJSON(x = option_images)
  
  # Create list of select ids
  sel_id_list <- paste0("<sel_id>", 
                        sel_id,
                        "</sel_id>",
                        collapse = "")
  
  span_class <- "SelrImageSelection"
  
  # Display the first option
  htmltools::img(src = option_images[1],
                 class = span_class,
                 r_sel_id = sel_id,
                 resultlistdata = result_list_data,
                 width = "100%",
                 height = "100%")
}
