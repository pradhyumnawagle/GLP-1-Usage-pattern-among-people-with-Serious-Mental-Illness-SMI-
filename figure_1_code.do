/**************************************************************************
  Notes:
    - The variables created below are 0/1 GLP-1 use indicators restricted
      to the relevant subgroup.
    - After collapse, the mean of each variable is the GLP-1 prevalence
      within that subgroup and year.
    - After multiplying by 100, the plotted values are percentages.
***************************************************************************/

* Install once if needed
* ssc install grc1leg

clear all
set more off

*=========================================================================*
* 1. LOAD ANALYSIS FILE                                                    *
*=========================================================================*
use "stacked_full.dta", clear

*=========================================================================*
* 2. CREATE SUBGROUP-SPECIFIC GLP-1 PREVALENCE VARIABLES                   *
*-------------------------------------------------------------------------*
* Each generated variable equals any_drug_use_glp1 for observations in    *
* that subgroup, and missing otherwise.                                   *
* Therefore, after collapse (mean), the result is:                        *
*   % GLP-1 users among beneficiaries in that subgroup.                   *
*=========================================================================*

*------------------------------*
* Any indication               *
*------------------------------*
gen any_overallsmi = any_drug_use_glp1 if any==1 & smi_final==1
gen any_schiz      = any_drug_use_glp1 if any==1 & smi_final==1 & schizophrenia==1
gen any_bipolar    = any_drug_use_glp1 if any==1 & smi_final==1 & bipolar_disorder==1
gen any_mdd        = any_drug_use_glp1 if any==1 & smi_final==1 & mdd==1
gen any_nosmi      = any_drug_use_glp1 if any==1 & smi_final==0

*------------------------------*
* Diabetes                     *
*------------------------------*
gen diabetes_overallsmi = any_drug_use_glp1 if diabetes==1 & smi_final==1
gen diabetes_schiz      = any_drug_use_glp1 if diabetes==1 & smi_final==1 & schizophrenia==1
gen diabetes_bipolar    = any_drug_use_glp1 if diabetes==1 & smi_final==1 & bipolar_disorder==1
gen diabetes_mdd        = any_drug_use_glp1 if diabetes==1 & smi_final==1 & mdd==1
gen diabetes_nosmi      = any_drug_use_glp1 if diabetes==1 & smi_final==0

*------------------------------*
* Obesity                      *
*------------------------------*
gen obesity_overallsmi = any_drug_use_glp1 if obesity==1 & smi_final==1
gen obesity_schiz      = any_drug_use_glp1 if obesity==1 & smi_final==1 & schizophrenia==1
gen obesity_bipolar    = any_drug_use_glp1 if obesity==1 & smi_final==1 & bipolar_disorder==1
gen obesity_mdd        = any_drug_use_glp1 if obesity==1 & smi_final==1 & mdd==1
gen obesity_nosmi      = any_drug_use_glp1 if obesity==1 & smi_final==0

*------------------------------*
* Sleep apnea                  *
*------------------------------*
gen sleep_apnea_overallsmi = any_drug_use_glp1 if sleep_apnea==1 & smi_final==1
gen sleep_apnea_schiz      = any_drug_use_glp1 if sleep_apnea==1 & smi_final==1 & schizophrenia==1
gen sleep_apnea_bipolar    = any_drug_use_glp1 if sleep_apnea==1 & smi_final==1 & bipolar_disorder==1
gen sleep_apnea_mdd        = any_drug_use_glp1 if sleep_apnea==1 & smi_final==1 & mdd==1
gen sleep_apnea_nosmi      = any_drug_use_glp1 if sleep_apnea==1 & smi_final==0

*=========================================================================*
* 3. COLLAPSE TO YEAR-LEVEL PLOTTING DATA                                  *
*-------------------------------------------------------------------------*
* The collapsed mean is the subgroup prevalence within each year.         *
preserve

collapse (mean) any_overallsmi any_schiz any_bipolar any_mdd any_nosmi ///
                 diabetes_overallsmi diabetes_schiz diabetes_bipolar diabetes_mdd diabetes_nosmi ///
                 obesity_overallsmi obesity_schiz obesity_bipolar obesity_mdd obesity_nosmi ///
                 sleep_apnea_overallsmi sleep_apnea_schiz sleep_apnea_bipolar sleep_apnea_mdd sleep_apnea_nosmi, ///
                 by(enr_year)

* Convert proportions to percentages for graphing
foreach v of varlist any_* diabetes_* obesity_* sleep_apnea_* {
    replace `v' = 100*`v'
}

* Save the collapsed plotting dataset so the full file does not need to be
* processed again for later graph edits.
save "E:\WorkArea-prw4002\glp1_analytical\glp1_figure1_data.dta", replace

*=========================================================================*
* 4. GRAPH FORMATTING                                                      *
*=========================================================================*
set scheme s2color

*=========================================================================*
* 5. PANEL 1: ANY INDICATION                                              *
*-------------------------------------------------------------------------*
* Legend is kept only in g1 because grc1leg will use the first graph's    *
* legend as the shared legend in the combined panel.                      *
*=========================================================================*
twoway ///
(line any_overallsmi enr_year, lpattern(dash)  msymbol(x)      msize(small)) ///
(line any_schiz      enr_year, lpattern(solid) msymbol(O)      msize(small)) ///
(line any_bipolar    enr_year, lpattern(solid) msymbol(D)      msize(small)) ///
(line any_mdd        enr_year, lpattern(solid) msymbol(circle) msize(small)) ///
(line any_nosmi      enr_year, lpattern(dot)   lcolor(black) lwidth(medthick) msymbol(T) msize(small)), ///
title("{bf:Any Indication}", size(small)) ///
xtitle("", size(small)) ytitle("%", size(vsmall)) ///
xscale(range(1 7.05)) ///
xlabel(1 "2018" 2 "2019" 3 "2020" 4 "2021" 5 "2022" 6 "2023" 7 "2024", labsize(small)) ///
ylabel(0(3)15, labsize(small) angle(horizontal)) ///
plotregion(margin(r+6 vsmall) lstyle(solid) lcolor(gs10) lwidth(vthin)) ///
graphregion(color(white) margin(tiny) lstyle(solid) lwidth(vthin)) ///
legend(order(1 "Overall SMI" 2 "Schizophrenia" 3 "Bipolar Disorder" 4 "MDD" 5 "No SMI") ///
       cols(1) size(vsmall) keygap(*0.35) rowgap(*0.25) symxsize(*0.7) symysize(*0.7) region(lstyle(none))) ///
name(g1, replace)

*=========================================================================*
* 6. PANEL 2: DIABETES                                                     *
*=========================================================================*
twoway ///
(line diabetes_overallsmi enr_year, lpattern(dash)  msymbol(x)) ///
(line diabetes_schiz      enr_year, lpattern(solid) msymbol(O)) ///
(line diabetes_bipolar    enr_year, lpattern(solid) msymbol(o)) ///
(line diabetes_mdd        enr_year, lpattern(solid) msymbol(o)) ///
(line diabetes_nosmi      enr_year, lpattern(dot)   lcolor(black) lwidth(medthick) msymbol(plus)), ///
title("{bf:Diabetes}", size(small)) ///
xtitle("", size(small)) ytitle("", size(vsmall)) ///
xlabel(1 "2018" 2 "2019" 3 "2020" 4 "2021" 5 "2022" 6 "2023" 7 "2024", labsize(small)) ///
ylabel(0(5)30, labsize(small) angle(horizontal)) ///
plotregion(margin(r+6 vsmall) lstyle(solid) lcolor(gs10) lwidth(vthin)) ///
graphregion(color(white) margin(tiny) lstyle(solid) lwidth(vthin)) ///
legend(off) ///
name(g2, replace)

*=========================================================================*
* 7. PANEL 3: OBESITY                                                      *
*=========================================================================*
twoway ///
(line obesity_overallsmi enr_year, lpattern(dash)  msymbol(x)) ///
(line obesity_schiz      enr_year, lpattern(solid) msymbol(O)) ///
(line obesity_bipolar    enr_year, lpattern(solid) msymbol(o)) ///
(line obesity_mdd        enr_year, lpattern(solid) msymbol(o)) ///
(line obesity_nosmi      enr_year, lpattern(dot)   lcolor(black) lwidth(medthick) msymbol(plus)), ///
title("{bf:Obesity}", size(small)) ///
xtitle("Year", size(small)) ytitle("%", size(vsmall)) ///
xlabel(1 "2018" 2 "2019" 3 "2020" 4 "2021" 5 "2022" 6 "2023" 7 "2024", labsize(small)) ///
ylabel(0(3)16, labsize(small) angle(horizontal)) ///
plotregion(margin(r+6 vsmall) lstyle(solid) lcolor(gs10) lwidth(vthin)) ///
graphregion(color(white) margin(tiny) lstyle(solid) lwidth(vthin)) ///
legend(off) ///
name(g3, replace)

*=========================================================================*
* 8. PANEL 4: SLEEP APNEA                                                  *
*=========================================================================*
twoway ///
(line sleep_apnea_overallsmi enr_year, lpattern(dash)  msymbol(x)) ///
(line sleep_apnea_schiz      enr_year, lpattern(solid) msymbol(O)) ///
(line sleep_apnea_bipolar    enr_year, lpattern(solid) msymbol(o)) ///
(line sleep_apnea_mdd        enr_year, lpattern(solid) msymbol(o)) ///
(line sleep_apnea_nosmi      enr_year, lpattern(dot)   lcolor(black) lwidth(medthick) msymbol(plus)), ///
title("{bf:Sleep Apnea}", size(small)) ///
xtitle("Year", size(small)) ytitle("", size(vsmall)) ///
xlabel(1 "2018" 2 "2019" 3 "2020" 4 "2021" 5 "2022" 6 "2023" 7 "2024", labsize(small)) ///
ylabel(0(4)20, labsize(small) angle(horizontal)) ///
plotregion(margin(r+6 vsmall) lstyle(solid) lcolor(gs10) lwidth(vthin)) ///
graphregion(color(white) margin(tiny) lstyle(solid) lwidth(vthin)) ///
legend(off) ///
name(g4, replace)

*=========================================================================*
* 9. COMBINE THE FOUR PANELS                                               *
*-------------------------------------------------------------------------*
* grc1leg combines the four stored graphs and uses the legend from g1     *
* as the shared legend.                                                   *
*=========================================================================*
grc1leg g1 g2 g3 g4, ///
    rows(2) cols(2) ///
    position(6) ring(1) ///
    imargin(tiny) ///
    graphregion(color(white) margin(b+4)) ///
    xsize(10) ysize(7.5)

* Optional: export figure
* graph export "glp1_figure1_panel.png", replace width(2400)

restore
