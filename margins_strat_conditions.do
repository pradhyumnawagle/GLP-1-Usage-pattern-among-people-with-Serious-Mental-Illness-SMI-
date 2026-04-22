* Load full analysis file
use "stacked_full.dta"

* Keep only variables needed for modeling and output
keep any_drug_use_glp1 smi_final ageatendyear gendercode payergroupcode eci_new enr_year diabetes obesity sleep_apnea overweight_and_others any statecode

* Define local macros for commonly used variable names
local outcome any_drug_use_glp1
local smi smi_final 
local agevar ageatendyear
local sexvar gendercode
local payervar payergroupcode
local ecivar eci_new
local yearvar enr_year 

* List of condition indicators for stratified models
local allconds diabetes obesity sleep_apnea overweight_and_others any

* Convert state code from string to numeric labeled variable for factor-variable use
encode statecode, gen(statenum) 
local statevar statenum

**********************
*RESULTS FILE
**********************
* Close postfile if it is already open from a prior run
capture postclose RES

* Create temporary results dataset
tempfile results

* Define the structure of the posted results
postfile RES ///
	str40 model_group ///
	double smi_adj_prob smi_ll smi_ul ///
	double nosmi_adj_prob nosmi_ll nosmi_ul ///
	double p_value ///
	double odds_ratio ///
	using `results', replace
		

*****************
*95% critical value
*****************
* z critical value for 95% confidence intervals
local zcrit = invnormal(0.975)

*****************
*Build case covariate list
*****************
local basecovars c.`agevar' i.`sexvar' i.`payervar' c.`ecivar' i.`yearvar' i.`statevar'

*****************
*FULL sample model
*****************
* Run adjusted logistic regression in the full sample
quietly logit `outcome' i.`smi' ///
	i.diabetes i.obesity i.sleep_apnea i.overweight_and_others ///
	`basecovars'
	
* Convert SMI coefficient from log-odds to odds ratio
local or = exp(_b[1.`smi'])
	
* Get adjusted predicted probabilities for SMI=0 and SMI=1
* post option makes margins results available in e(b) and e(V)
quietly margins `smi',predict(pr) post

* Extract margins estimates and variance-covariance matrix
matrix b = e(b)
matrix V = e(V)

* Adjusted predicted probabilities:
* column 1 = no SMI
* column 2 = SMI
local nosmi_p = b[1,1]
local smi_p = b[1,2]

* Standard errors of the adjusted predicted probabilities
local nosmi_se = sqrt(V[1,1])
local smi_se = sqrt(V[2,2])

* 95% CI for no SMI predicted probability
* bounded to [0,1]
local nosmi_ll = max(0,`nosmi_p' - `zcrit'*`nosmi_se')
local nosmi_ul = min(1,`nosmi_p' + `zcrit'*`nosmi_se')

* 95% CI for SMI predicted probability
* bounded to [0,1]
local smi_ll = max(0,`smi_p' - `zcrit'*`smi_se')
local smi_ul = min(1,`smi_p' + `zcrit'*`smi_se')

* Compute difference in adjusted probabilities and its SE
* Uses variance formula for difference of two correlated estimates
local diff = `smi_p' - `nosmi_p'
local diff_se = sqrt(V[1,1] + V[2,2] - 2*V[1,2])

* Two-sided p-value for difference in adjusted probabilities
local pv = 2*normal(-abs(`diff'/`diff_se'))

* Post full-sample results into results file
post RES ///
	("Full sample") ///	
	(`smi_p') (`smi_ll') (`smi_ul') ///
	(`nosmi_p') (`nosmi_ll') (`nosmi_ul') ///
	(`pv') (`or')
	
*****************
*STRATIFIED model
*****************
* Loop over each indication condition
foreach c of local allconds {
	preserve 

	 * Restrict dataset to beneficiaries with the current condition = 1
	keep if `c' == 1
	di "================================================="
	di "Processing `c'"
	di "================================================="
	
	* Build RHS condition list excluding the condition currently being stratified on
    * Example:
    * if c = diabetes, then otherconds = obesity sleep_apnea overweight_and_others any
	local otherconds : list allconds - c
	
	* Add the remaining condition indicators to the model as covariates
	local rhsconds 
	foreach x of local otherconds {
		local rhsconds `rhsconds' i.`x'
	}
	
	* Run adjusted logistic regression within current condition stratum
    * Main exposure remains SMI
    * Adjust for the other condition indicators plus base covariates
	quietly logit `outcome' i.`smi' ///
		`rhsconds' ///
		`basecovars'

	 * Odds ratio for SMI coefficient
	local or = exp(_b[1.`smi'])
	
	* Adjusted predicted probabilities for no SMI and SMI within this stratum
	quietly margins `smi', predict(pr) post

	* Extract estimates and covariance matrix from margins
	matrix b = e(b)
	matrix V = e(V)

	* Adjusted predicted probabilities
	local nosmi_p = b[1,1]
	local smi_p = b[1,2]

	* Standard errors
	local nosmi_se = sqrt(V[1,1])
	local smi_se = sqrt(V[2,2])

	* 95% CI for no SMI adjusted probability
	local nosmi_ll = max(0,`nosmi_p' - `zcrit'*`nosmi_se')
	local nosmi_ul = min(1,`nosmi_p' + `zcrit'*`nosmi_se')

	* 95% CI for SMI adjusted probability
	local smi_ll = max(0,`smi_p' - `zcrit'*`smi_se')
	local smi_ul = min(1,`smi_p' + `zcrit'*`smi_se')

	* Difference in adjusted probabilities and p-value
	local diff = `smi_p' - `nosmi_p'
	local diff_se = sqrt(V[1,1] + V[2,2] - 2*V[1,2])
	local pv = 2*normal(-abs(`diff'/`diff_se'))
	
	* Row label for this stratum
	local rowlabel "`c' == 1"

	* Post stratified results
	post RES ///
		("`rowlabel'") ///	
		(`smi_p') (`smi_ll') (`smi_ul') ///
		(`nosmi_p') (`nosmi_ll') (`nosmi_ul') ///
		(`pv') (`or')
		
		restore	
}

* Close postfile so results dataset is written to disk
postclose RES

* Open the temporary results dataset
use `results', clear

* Format numeric columns for cleaner display
format smi_adj_prob smi_ll smi_ul nosmi_adj_prob nosmi_ll nosmi_ul %6.3f
format odds_ratio %6.3f
format p_value %9.4f

* Build CI strings for export
gen smi_ci   = "[" + string(smi_ll, "%5.3f") + ", " + string(smi_ul, "%5.3f") + "]"
gen nosmi_ci = "[" + string(nosmi_ll, "%5.3f") + ", " + string(nosmi_ul, "%5.3f") + "]"

* Reorder variables for final output table
order model_group smi_adj_prob smi_ci nosmi_adj_prob nosmi_ci p_value odds_ratio
list, noobs clean 

* Export final table to Excel
export excel using "smi_stratified_margins_table.xlsx", firstrow(variables) replace