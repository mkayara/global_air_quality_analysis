args <- commandArgs(trailingOnly = TRUE)
data_file <- if (length(args) > 0) args[[1]] else file.path("data", "global_air_quality.csv")

if (!file.exists(data_file)) {
  stop(
    "CSV not found: ", data_file,
    "\nDownload the dataset from https://www.kaggle.com/datasets/waqi786/global-air-quality-dataset ",
    "and pass its path as the first argument."
  )
}

air <- read.csv(
  data_file,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  na.strings = c("", "NA", "N/A")
)

if (nrow(air) == 0) {
  stop("The CSV contains no observations.")
}

required_pollutants <- c("PM2.5", "NO2", "SO2", "CO", "O3")
missing_columns <- setdiff(required_pollutants, names(air))
if (length(missing_columns) > 0) {
  stop("Required pollutant columns are missing: ", paste(missing_columns, collapse = ", "))
}

pollutants <- c(required_pollutants, intersect("PM10", names(air)))
for (column in pollutants) {
  if (!is.numeric(air[[column]])) {
    original <- air[[column]]
    converted <- suppressWarnings(as.numeric(as.character(original)))
    parse_failures <- sum(is.na(converted) & !is.na(original) & nzchar(trimws(as.character(original))))
    if (parse_failures > 0) {
      warning("Could not parse ", parse_failures, " value(s) in ", column, "; they will be counted as missing.")
    }
    air[[column]] <- converted
  }
}

describe <- function(values) {
  missing_count <- sum(is.na(values))
  values <- values[is.finite(values)]

  if (length(values) == 0) {
    return(data.frame(
      observations = 0L,
      missing = missing_count,
      mean = NA_real_,
      standard_deviation = NA_real_,
      median = NA_real_,
      minimum = NA_real_,
      maximum = NA_real_,
      iqr = NA_real_
    ))
  }

  data.frame(
    observations = length(values),
    missing = missing_count,
    mean = mean(values),
    standard_deviation = if (length(values) > 1) sd(values) else NA_real_,
    median = median(values),
    minimum = min(values),
    maximum = max(values),
    iqr = IQR(values)
  )
}

summary_table <- do.call(rbind, lapply(pollutants, function(column) {
  data.frame(variable = column, describe(air[[column]]), row.names = NULL)
}))
missing_table <- data.frame(
  column = names(air),
  missing = vapply(air, function(column) sum(is.na(column)), integer(1)),
  row.names = NULL
)

cat("Rows:", nrow(air), "\n")
cat("Columns:", ncol(air), "\n")
cat("Exact duplicate rows:", sum(duplicated(air)), "\n\n")
cat("Pollutant summary:\n")
print(summary_table, row.names = FALSE)
cat("\nMissing values by column:\n")
print(missing_table, row.names = FALSE)

output_dir <- "outputs"
if (!dir.exists(output_dir) && !dir.create(output_dir, recursive = TRUE)) {
  stop("Could not create output directory: ", output_dir)
}

write.csv(summary_table, file.path(output_dir, "pollutant-summary.csv"), row.names = FALSE)
write.csv(missing_table, file.path(output_dir, "missing-values.csv"), row.names = FALSE)

png(file.path(output_dir, "pollutant-distributions.png"), width = 1400, height = 900, res = 140)
par(mfrow = c(ceiling(length(pollutants) / 2), 2), mar = c(4, 4, 3, 1))
for (column in pollutants) {
  values <- air[[column]]
  values <- values[is.finite(values)]
  if (length(values) > 0) {
    hist(values, main = column, xlab = column, col = "steelblue2", border = "white")
  } else {
    plot.new()
    title(main = paste(column, "(no finite values)"))
  }
}
dev.off()

png(file.path(output_dir, "pollutant-boxplots.png"), width = 1400, height = 800, res = 140)
box_values <- lapply(air[pollutants], function(values) values[is.finite(values)])
box_values <- box_values[lengths(box_values) > 0]
if (length(box_values) > 0) {
  boxplot(
    box_values,
    main = "Pollutant distributions",
    ylab = "Recorded value",
    col = "lightblue",
    outline = TRUE
  )
} else {
  plot.new()
  title(main = "Pollutant distributions (no finite values)")
}
dev.off()

usable_pollutants <- pollutants[vapply(pollutants, function(column) {
  values <- air[[column]]
  values <- values[is.finite(values)]
  length(values) > 1 && is.finite(sd(values)) && sd(values) > 0
}, logical(1))]

if (length(usable_pollutants) >= 2) {
  correlation_matrix <- cor(air[usable_pollutants], use = "pairwise.complete.obs")
  write.csv(correlation_matrix, file.path(output_dir, "pollutant-correlations.csv"))
  cat("\nPairwise-complete pollutant correlations:\n")
  print(correlation_matrix)
} else {
  message("Correlation matrix skipped: fewer than two pollutants have usable variation.")
}

cat("\nAnalysis complete. Outputs are in ", output_dir, "/\n", sep = "")
