# GLP-1 Usage Patterns Among People with Serious Mental Illness (SMI)

This repository contains the Stata code used for analyses in the study of GLP-1 use among people with serious mental illness (SMI). The scripts generate adjusted marginal predicted probabilities from logistic regression models and produce the study’s trend figure. The repository currently includes four analysis scripts: one for the multi-panel figure and three for stratified regression outputs. The project is entirely written in Stata. 

## Repository contents

### `figure_1_code.do`
Creates the multi-panel trend figure for GLP-1 use over time. The script constructs subgroup-specific GLP-1 prevalence variables, collapses the analytic file to year level, and generates a four-panel figure covering:
- any indication,
- diabetes,
- obesity, and
- sleep apnea.

It is the main script for producing the descriptive yearly trends shown in the figure 1.

### `margins_strat_conditions.do`
Runs adjusted logistic regression models and computes marginal predicted probabilities stratified by indication-related conditions. It produces adjusted probabilities, confidence intervals, p-values, and odds ratios for the full sample and for condition-specific strata. This file is intended for the main condition-stratified regression.

### `margins_strat_insurance.do`
Runs adjusted logistic regression models stratified by insurance type (payer group). It loops across payer categories and estimates adjusted probabilities for the SMI and non-SMI groups within each insurance group, along with confidence intervals and p-values. This file is used for the insurance-stratified results.

### `margins_strat_smi_diag.do`
Runs adjusted logistic regression models stratified by SMI diagnosis subtype. It compares each diagnosis subtype with the non-SMI reference group and outputs adjusted probabilities, confidence intervals, and p-values for those comparisons. This file is used for the diagnosis-stratified results.

## Data inputs

The scripts are written to work from a stacked analytic dataset referenced in the code as variants of a full analytic file, such as `stacked_full.dta`. You may need to update file paths before running the code locally.

## Outputs

Depending on the script, outputs include:
- Excel tables of adjusted predicted probabilities and confidence intervals
- stratified regression summary tables
- the multi-panel GLP-1 trend figure
- collapsed year-level datasets used for plotting

## Suggested usage order

1. Run the regression scripts to generate the condition-, insurance-, and diagnosis-stratified tables.
2. Run `figure_1_code.do` to generate the descriptive trend figure.
3. Export final tables and figures.

## Notes
- File paths in the scripts appear to be written for a local Windows environment, so they may need to be edited before use on another system.
- The repository currently appears to focus on analysis code rather than raw data storage.
- If you expand the repository later, you may want to add sections for data provenance, required packages, and variable definitions.
