** Load analysis dataset
use "stacked_full.dta"

* If a postfile named RES is already open from an earlier run, close it
capture postclose RES

* Create a temporary file to store posted results
tempfile results 
* Define the structure of the results dataset that will be built using post
postfile RES ///
		str20 payer ///
		str40 condition ///
		double smi_adj_prob smi_ll smi_ul ///
		double nosmi_adj_prob nosmi_ll nosmi_ul ///
		double p_value ///
		using `results', replace
		
* Get all unique payergroupcode values and store them in local macro `payers'
levelsof payergroupcode, local(payers)

* Loop over each payer type
foreach p of local payers {	
	
	* Preserve the full dataset so this payer-specific subset can be undone later
	preserve
	* Keep only observations for the current payergroupcode
	keep if payergroupcode==`p'
	
	* Convert numeric payer code to its value label for readable output
	local payer_label : label(payergroupcode) `p'
	di "====================================="
	di "Running payergroupcode = `payer_label' (code `p')"
	di "====================================="
	
	************************
	* Overall SMI
	************************
	* Fit adjusted logistic regression model within the current payer subgroup
	quietly logit any_drug_use_glp1 i.smi_final i.diabetes i.obesity i.sleep_apnea i.overweight_and_others c.ageatendyear i.gendercode c.eci_new i.enr_year	
	
	* Compute Wald z-statistic and two-sided p-value for the SMI indicator
    * _b[1.smi_final] = coefficient for SMI=1 relative to reference SMI=0
    * _se[1.smi_final] = standard error of that coefficient
	local z = _b[1.smi_final]/_se[1.smi_final]
	local pv = 2*normal(-abs(`z'))
	
	* Obtain adjusted predicted probabilities for smi_final = 0 and 1
	* Store margins table in matrix T
	quietly margins smi_final, predict(pr)
	matrix T = r(table)
	
	* Extract adjusted probability and CI for No SMI group
    * Column 1 corresponds to smi_final = 0 (No SMI)
    * Row 1 = margin, row 5 = CI lower, row 6 = CI upper
	local nosmi_p = T[1,1]
	local nosmi_ll = T[5,1]
	local nosmi_ul = T[6,1]
	
	* Extract adjusted probability and CI for No SMI group
    * Column 1 corresponds to smi_final = 0 (No SMI)
    * Row 1 = margin, row 5 = CI lower, row 6 = CI upper
	local smi_p = T[1,2]
	local smi_ll = T[5,2]
	local smi_ul = T[6,2]
	
	* Post one result row for this payer:
	post RES ///
		("`payer_label'") ///
		("SMI") ///
		(`smi_p') (`smi_ll') (`smi_ul') ///
		(`nosmi_p') (`nosmi_ll') (`nosmi_ul') ///
		(`pv')
	
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
order payer condition smi_adj_prob smi_ci nosmi_adj_prob nosmi_ci p_value
list, sepby(payer) noobs
