# Global Air Quality EDA

Exploratory analysis of air-pollution measurements from the [Global Air Quality Dataset](https://www.kaggle.com/datasets/waqi786/global-air-quality-dataset) on Kaggle. The project is a small, reproducible R script for inspecting pollutant distributions, data quality, and pairwise relationships.

## What it does

- Summarizes PM2.5, NO2, SO2, CO, and O3; PM10 is included when present.
- Reports missing values and exact duplicate rows.
- Saves distribution and boxplot figures.
- Calculates pairwise-complete pollutant correlations when the data supports them.
- Writes summary tables and figures to `outputs/`.

The analysis is descriptive. Correlations do not establish causes, and this project does not estimate health impacts or predict air quality.

## Dataset

Download the CSV from the [Kaggle dataset page](https://www.kaggle.com/datasets/waqi786/global-air-quality-dataset) and place it at `data/global_air_quality.csv`, or pass another CSV path to the script. The dataset is intentionally not included in this repository. Check the dataset page for its current terms and attribution requirements before use or redistribution.

The analysis requires numeric columns named `PM2.5`, `NO2`, `SO2`, `CO`, and `O3`. `PM10` is optional. Other columns are retained for data-quality counts but are not used in pollutant summaries.

## Run

Requires R; no add-on packages are needed.

```sh
Rscript analysis.R
```

Or provide the CSV path:

```sh
Rscript analysis.R path/to/air_quality.csv
```

The script prints the dataset dimensions and descriptive statistics, then writes:

- `outputs/pollutant-summary.csv`
- `outputs/missing-values.csv`
- `outputs/pollutant-distributions.png`
- `outputs/pollutant-boxplots.png`
- `outputs/pollutant-correlations.csv` when at least two usable pollutant columns are available

Missing values are reported, not imputed. The input file is never modified. Generated outputs and local data files are excluded from Git.

## Repository contents

- `analysis.R` — self-contained analysis script.
- `.gitignore` — excludes downloaded data, generated output, and local R state.

## Limitations

This repository does not include the dataset or a saved analysis run. Results depend on the downloaded dataset version and its column values. The script does not check measurement units, sampling methodology, or whether observations are comparable across locations and dates.
