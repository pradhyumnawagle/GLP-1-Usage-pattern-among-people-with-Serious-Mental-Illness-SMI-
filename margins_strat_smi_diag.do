 use "stacked_full.dta"

* Define variables to use in the model below
local outcome any_drug_use_glp1
local agevar ageatendyear
local sexvar gendercode
local payervar payergroupcode
local ecivar eci_new 
local yearvar enr_year

* Define SMI diagnosis subtypes
local subtype_vars schizophrenia bipolar_disorder mdd

* Define GLP-1 indicating condition variables
local cond_vars any diabetes obesity sleep_apnea overweight_and_others 
local cond_covars i.diabetes i.obesity i.sleep_apnea i.overweight_and_others 

* Generate NO SMI
capture drop no_smi 
gen byte no_smi = (smi_final==0)

* Initiatlize base covariates
local basecovars c.`agevar' i.`sexvar' i.`payervar' c.`ecivar' i.`yearvar'

* Create a temporary file to store posted results
tempfile results 
* Define the structure of the results dataset that will be built using post
postfile RES ///
		str20 subtype ///
		str40 condition ///
		double smi_adj_prob smi_ll smi_ul ///
		double nosmi_adj_prob nosmi_ll nosmi_ul ///
		double p_value ///
		using `results', replace

* Loop through all diagnosis subtypes
local nsub: word count `subtype_vars'

forvalues s=1/`nsub' {
	
	* Get the diagnosis subtype and label
	local subtype_var : word `s' of `subtype_vars'
	
	if "`subtype_var'" == "schizophrenia" {
		local subtype_label = "Schizophrenia"
	}
	else if "`subtype_var'" == "bipolar_disorder" {
		local subtype_label = "Bipolar Disorder"
	}
	else if "`subtype_var'" == "mdd" {
		local subtype_label = "MDD"
	}
	
	preserve
	
	di "================================================"
	di "Running subtype `subtype_label'"
	di "================================================"
	
	* Keep only observations in either:
	*   1) the subtype of interest (`subtype_var'==1), or
	*   2) the reference group with no SMI (no_smi==1).
	* Example for schizophrenia:
	*   keep if schizophrenia==1 | no_smi==1
	keep if `subtype_var'==1 | no_smi==1
	
	****************************************************
	* ROW 1: OVERALL SUBTYPE VS NO SMI
	****************************************************
	* Logistic regression.
	* This model would only compare subtype(schizophrenia/bipolar/mdd) vs no smi.
	quietly logit `outcome' i.`subtype_var' `cond_covars' `basecovars'
	
	* Compute Wald z-statistic and two-sided p-value for the subtype indicator.
	* _b[1.`subtype_var']  = coefficient for subtype_var==1
	* _se[1.`subtype_var'] = standard error of that coefficient
	local z = _b[1.`subtype_var']/_se[1.`subtype_var']
	local p = 2*normal(-abs(`z'))
	
	* Use the margins command to get the predicted probabilities and store the results.
	* Get adjusted predicted probabilities from the fitted model
	* for subtype_var = 0 and subtype_var = 1.
	quietly margins `subtype_var', predict(pr)
	matrix T = r(table)

	* In margins output:
	*   col 1 = subtype_var = 0  -> reference group (NO SMI)
	*   col 2 = subtype_var = 1  -> subtype group
	*
	* Row meanings in r(table):
	*   row 1 = adjusted predicted probability (margin)
	*   row 5 = lower bound of confidence interval
	*   row 6 = upper bound of confidence interval

	* Extract adjusted probability and 95% CI for NO SMI group	
	local nosmi_p = T[1,1]
	local nosmi_ll = T[5,1]
	local nosmi_ul = T[6,1]
	* Extract adjusted probability and 95% CI for subtype group
	local smi_p = T[1,2]
	local smi_ll = T[5,2]
	local smi_ul = T[6,2]
	
	* Post the results into the subtype
	post RES ///
		("`subtype_label'") ///
		("Overall") ///
		(`smi_p') (`smi_ll') (`smi_ul') ///
		(`nosmi_p') (`nosmi_ll') (`nosmi_ul') ///
		(`p')

	* Restore the full dataset before moving on to the next subtype loop
	restore 
}


postclose RES
use `results', clear

* Format decimal places
format smi_adj_prob nosmi_adj_prob smi_ll smi_ul nosmi_ll nosmi_ul %6.3f
format p_value %9.4f

* Get confidence intervals
gen smi_ci   = "[" + string(smi_ll, "%5.3f") + ", " + string(smi_ul, "%5.3f") + "]"
gen nosmi_ci = "[" + string(nosmi_ll, "%5.3f") + ", " + string(nosmi_ul, "%5.3f") + "]"

* Order in the display table
order subtype condition smi_adj_prob smi_ci nosmi_adj_prob nosmi_ci p_value
list, sepby(subtype) noobs

