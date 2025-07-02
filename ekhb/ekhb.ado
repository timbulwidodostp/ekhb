capture program drop ekhb
program ekhb, eclass properties(mi)
syntax anything [if] [in] [fweight iweight pweight], Decompose(varname numeric) Mediators(varlist numeric min=1) [Adjust(varlist numeric) Controls(varlist fv ts) DISentangle patha pathb RELiability(string asis) CONStraints(passthru) vce(passthru) outmat(string asis) from(passthru) level(cilevel) NOIsily *]

* input
// check if dependent variable is numeric
gettoken model depvar : anything
local depvar=strtrim("`depvar'")
capture confirm numeric variable `depvar'
if _rc!=0 {
	di as error "Dependent variable should be numeric."
	exit
}

// check if variance estimator supported
if "`vce'"!="" {
	local vce_a = subinstr("`vce'","vce(","",.)
	local vce_content = subinstr("`vce_a'",")","",.)
	local nvce_content : word count `vce_content'
	if `nvce_content'==1 & ("`vce_content'"!="oim" & "`vce_content'"!="robust") {
		di as error "Variance estimator should be oim, robust, or cluster clustvar."
		exit
	}
	else if `nvce_content'==2 {
		gettoken cluster clustvar : vce_content
		if "`cluster'"!="cluster" | "`clustvar'"=="" {
			di as error "Variance estimator should be oim, robust, or cluster clustvar."
			exit
		}
		capture confirm numeric variable `clustvar'
		if _rc!=0 {
			capture confirm string variable `clustvar'
			if _rc!=0 {
				di as error "Clustvar should be string or numeric."
				exit
			}
		}
	}
	else if `nvce_content'>2 {
		di as error "Variance estimator should be oim, robust, or cluster clustvar."
		exit
	}
}

// check if reliability variables are a subsample of the mediators
if "`reliability'"!="" {
	local nreliability : word count `reliability'
	local relvars
	local relvalues
	local medcomma=subinstr("`mediators'"," ",`"",""',.)
	local medapos `""`medcomma'""'
	
	forvalues i = 1(2)`nreliability' {
		local x : word `i' of `reliability'
		local relapos `""`x'""'
		if inlist(`relapos', `medapos')==0 {
			di as error "Not all variables specified in reliability() are mediators."
			exit
		}
		
		local j = `i'+1
		local value : word `j' of `reliability'
		capture confirm number `value'
		if _rc!=0 {
			di as error "Not all variables specified in reliability() have a reliability value assigned."
			exit
		}	
		local relvars "`relvars' `x'"	
	}
}

// check content startvalue vector
if "`from'"!="" {
	local from_a = subinstr("`from'","from(","",.)
	local from_b = subinstr("`from_a'",")","",.)
	local from_c = subinstr("`from_b'","skip","",.)
	local from_content = subinstr("`from_c'",",","",.)
	capture confirm matrix `from_content'
	if _rc!=0 {
		local from
	}
	else if colsof(`from_content')==1 & rowsof(`from_content')==1 & (`from_content'[1,1]==0 | `from_content'[1,1]==.) {
		local from
	}
}

// display model estimations or not
local disoutput quietly
if "`noisily'"!="" {
	local disoutput
}

// mark the sample
marksample touse
markout `touse' `depvar' `decompose' `mediators' `adjust' `controls' `relvars' `clustvar'


* set the mediating paths
local nmediators : word count `mediators'
local pathvars `mediators' `adjust'
local npathvars : word count `pathvars'

local firstpaths "( `pathvars' <- `decompose' `controls', regress)"
local lastpath "( `depvar' <- `decompose' `pathvars' `controls', `model')"
local addpaths

tempname startvalues

* reliability corrections
if "`reliability'"!="" {
	// obtain constraints
	if "`constraints'"!="" {
		local constraints_a = subinstr("`constraints'","constraints(","",.)
		local constraints_content = subinstr("`constraints_a'",")","",.)
		local nconstraints : word count `constraints_content'
		tokenize `constraints_content'
	}
	
	// include latent variables
	foreach x of varlist `relvars' {
		local upper = strupper("`x'")
		capture drop `upper'_LATENT
		quietly gen `upper'_LATENT = `x'
		
		local addpaths "`addpaths' ( `x' <- `upper'_LATENT@1, regress)"
		local firstpaths=subinword("`firstpaths'","`x'","`upper'_LATENT",.)
		local lastpath=subinword("`lastpath'","`x'","`upper'_LATENT",.)
		
		// adjust the constraints that contain latent variables
		if "`constraints'"!="" {
			forvalues i = 1/`nconstraints' {
				constraint get ``i''
				local cnumber_content = r(contents)
				if strpos("`cnumber_content'","`x'")>0 {
					constraint define ``i'' `=subinstr("`cnumber_content'","`x'","`upper'_LATENT",.)'
				}
			}
		}
	}
		
	// speed up starting values, if none given
	if "`from'"=="" {
		local x_addpaths=subinstr("`addpaths'",", regress"," ",.)
		local x_firstpaths=subinstr("`firstpaths'",", regress"," ",.)
		local x_lastpath=subinstr("`lastpath'",", `model'"," ",.)
	
		di as text "obtain starting values..." _cont
		quietly sem `x_addpaths' `x_firstpaths' `x_lastpath' if `touse' [`weight'`exp'], reliability(`reliability') `constraints' `options'
		matrix define `startvalues' = e(b)

		`disoutput' gsem `addpaths' `lastpath' if `touse' [`weight'`exp'], listwise reliability(`reliability') `constraints' from(`startvalues', skip) `options'
		matrix define `startvalues' = e(b)
		local from "from(`startvalues', skip)"
	}
}


* estimate the model
// speed up starting values, if none given
if "`reliability'"=="" & "`from'"=="" {
	di as text "obtain starting values..." _cont
	quietly gsem `lastpath' if `touse' [`weight'`exp'], listwise `constraints' `options'
	matrix define `startvalues' = e(b)
	local from "from(`startvalues', skip)"
}

// estimate
di as text "estimate structural equation model..." _cont
`disoutput' gsem `firstpaths' `lastpath' `addpaths' if `touse' [`weight'`exp'], listwise noheader nodvheader reliability(`reliability') `vce' `constraints' `from' `options'

// return coefficient vector
if "`outmat'"!="" {
	matrix `outmat' = e(b)
}


* path A
if "`patha'"!="" {
	tempname b_patha V_patha
	matrix define `b_patha' = J(1,`nmediators',0)
	matrix define `V_patha' = J(`nmediators',`nmediators',0)
	
	forvalues i = 1/`nmediators' {
		local x : word `i' of `mediators'
		matrix `b_patha'[1,`i'] 	= _b[`x':`decompose']
		matrix `V_patha'[`i',`i'] 	= (_se[`x':`decompose'])^2
	}
}

* path B
if "`pathb'"!="" {
	tempname b_pathb V_pathb
	matrix define `b_pathb' = J(1,`nmediators',0)
	matrix define `V_pathb' = J(`nmediators',`nmediators',0)
	
	forvalues i = 1/`nmediators' {
		local x : word `i' of `mediators'
		matrix `b_pathb'[1,`i'] 	= _b[`depvar':`x']
		matrix `V_pathb'[`i',`i'] 	= (_se[`depvar':`x'])^2
	}
}


* obtain effects
// direct effect
tempname directcoef directvar
scalar `directcoef' = _b[`depvar':`decompose']
scalar `directvar' = (_se[`depvar':`decompose'])^2

// indirect effects
tempname b_fin V_fin
matrix define `b_fin' = J(1,`npathvars'+4,0)
matrix define `V_fin' = J(`npathvars'+4,`npathvars'+4,0)

di as text "mediator effects..." _cont
local indirecteffect=0
forvalues i = 1/`nmediators' {
	local x : word `i' of `mediators'
	local nlcomline "_b[`x':`decompose']*_b[`depvar':`x']"
	local indirecteffect "`indirecteffect' + _b[`x':`decompose']*_b[`depvar':`x']"
	
	if "`reliability'"!="" {
		local relcomma=subinstr("`relvars'"," ",`"",""',.)
		local relapos `""`relcomma'""'
		local medapos `""`x'""'
		if inlist(`medapos', `relapos')==1 {
			local upper = strupper("`x'")
			local indirecteffect=subinstr("`indirecteffect'","`x'","`upper'_LATENT",.)
			local nlcomline=subinstr("`nlcomline'","`x'","`upper'_LATENT",.)
		}
	}
	quietly nlcom `nlcomline'
	
	matrix `b_fin'[1,`i'] = r(b)
	matrix `V_fin'[`i',`i'] = r(V)
}

di as text "indirect effect..." _cont
quietly nlcom `indirecteffect'
tempname indirectcoef indirectvar
matrix define `indirectcoef' = r(b)
matrix define `indirectvar' = r(V)

// adjustment effects
local adjusteffect=0
tempname adjustcoef adjustvar

if "`adjust'"!="" {
	di as text "adjustment effect..." _cont
	local nadjust : word count `adjust'

	forvalues i = 1/`nadjust' {
		local x : word `i' of `adjust'
		local adjusteffect "`adjusteffect' + _b[`x':`decompose']*_b[`depvar':`x']"
		
		local j=`nmediators'+`i'
		if "`disentangle'"!="" {
			quietly nlcom _b[`x':`decompose']*_b[`depvar':`x']
			matrix `b_fin'[1,`j'] 	= r(b)
			matrix `V_fin'[`j',`j'] = r(V)
		}
		else {
			matrix `b_fin'[1,`j'] 	= 0
			matrix `V_fin'[`j',`j'] = 0
		}
	}
	quietly nlcom `adjusteffect'
	matrix define `adjustcoef' = r(b)
	matrix define `adjustvar' = r(V)
}
else {
	matrix define `adjustcoef' = 0
	matrix define `adjustvar' = 0
}

* total effect
// prepare posting results
local N = r(N)
tempvar samp_var
gen byte `samp_var' = e(sample)
local N_clust = e(N_clust)

// post previous lincoms for faster execution
di as text "total effect..." _cont
tempname b V
matrix define `b' = (`directcoef',`indirectcoef',`adjustcoef')
matrix define `V' = (`directvar',0,0 \ 0,`indirectvar',0 \ 0,0,`adjustvar')
matrix colnames `b' = temp_direct temp_indirect temp_adjust
matrix colnames `V' = temp_direct temp_indirect temp_adjust
matrix rownames `V' = temp_direct temp_indirect temp_adjust
ereturn post `b' `V', obs(`N')
quietly lincom temp_direct + temp_indirect + temp_adjust
tempname totalcoef totalvar
scalar `totalcoef' = r(estimate)
scalar `totalvar' = r(se)^2


* prepare matrices
// total, indirect, adjustment, direct effect
matrix `b_fin'[1,`npathvars'+1] 			= `totalcoef'
matrix `V_fin'[`npathvars'+1,`npathvars'+1] = `totalvar'
matrix `b_fin'[1,`npathvars'+2] 			= `indirectcoef'
matrix `V_fin'[`npathvars'+2,`npathvars'+2] = `indirectvar'
matrix `b_fin'[1,`npathvars'+3] 			= `adjustcoef'
matrix `V_fin'[`npathvars'+3,`npathvars'+3] = `adjustvar'
matrix `b_fin'[1,`npathvars'+4] 			= `directcoef'
matrix `V_fin'[`npathvars'+4,`npathvars'+4] = `directvar'

// coefficients and variance
matrix define `b' = J(1,`npathvars'+4+`nmediators'+`nmediators',0)
matrix define `V' = J(`npathvars'+4+`nmediators'+`nmediators',`npathvars'+4+`nmediators'+`nmediators',0)
matrix `b'[1,1] = `b_fin'
matrix `V'[1,1] = `V_fin'

// incorporate path a and b coefficients (if specified)
if "`patha'"!="" {
	matrix `b'[1,`npathvars'+5] 										= `b_patha'
	matrix `V'[`npathvars'+5,`npathvars'+5] 							= `V_patha'
}
if "`pathb'"!="" {
	matrix `b'[1,`npathvars'+5+`nmediators'] 							= `b_pathb'
	matrix `V'[`npathvars'+5+`nmediators',`npathvars'+5+`nmediators'] 	= `V_pathb'	
}

// name rows and columns
local names_patha
local names_pathb
foreach x of varlist `mediators' {
	local names_patha "`names_patha' Path_A_`x'"
	local names_pathb "`names_pathb' Path_B_`x'"
}
local addnames "`names_patha' `names_pathb'"
matrix rownames `b' = y1
matrix colnames `b' = `mediators' `adjust' "Total_effect" "Indirect_effect" "Adjustment_effect" "Direct_effect" `addnames'
matrix rownames `V' = `mediators' `adjust' "Total_effect" "Indirect_effect" "Adjustment_effect" "Direct_effect" `addnames'
matrix colnames `V' = `mediators' `adjust' "Total_effect" "Indirect_effect" "Adjustment_effect" "Direct_effect" `addnames'

// additional output matrix with mediation percentages
tempname percexpl
matrix define `percexpl' = (100*`b'[1,1]/`totalcoef')
forvalues i = 2/`nmediators' {
	local x : word `i' of `nmediators'
	matrix `percexpl' = (`percexpl' \ 100*`b'[1,`i']/`totalcoef')
}
matrix `percexpl' = (`percexpl' \ 100*`b'[1,`npathvars'+2]/`totalcoef')
matrix rownames `percexpl' = `mediators' "Indirect_effect"
matrix colnames `percexpl' = "Mediation"


* post results
// set the variance estimator
local vce
local vcetype
if "`vce_content'"=="oim" | "`vce'"=="" {
	local vce "oim"
}
if "`vce_content'"=="robust" {
	local vce "robust"
	local vcetype "Robust"
}
if "`cluster'"=="cluster" {
	local vce "cluster"
	local vcetype "Robust"
}

// post results
ereturn post `b' `V', depname(`depvar') obs(`N') esample(`samp_var')
ereturn scalar N_clust = `N_clust'
ereturn local controlvars `controls'
ereturn local adjustvars `adjust'
ereturn local mediatorvars `mediators'
ereturn local decomposevar `decompose'
ereturn local clustvar `cluster'
ereturn local vcetype `vcetype'
ereturn local model `model'
ereturn local vce `vce'
ereturn local title "KHB decomposition"
ereturn local cmd "ekhb"

// display results
di _newline(2)	as text "Outcome: " 	_column(13) as result "`depvar'"
di 				as text "Decompose: "	_column(13) as result "`decompose'"
di 				as text "Mediators: "	_column(13) as result "`mediators'"
di 				as text "Adjust: "		_column(13) as result "`adjust'"
di 				as text "Controls: "	_column(13) as result "`controls'"
di  _column(58) as text "Number of obs = " as result _column(74) %7.0fc e(N)
ereturn display, noomitted vsquish level(`level')
if "`reliability'"!="" {
	di as text "After correcting for measurement error in" as result "`relvars'." _newline(2)
}
matlist `percexpl', title("Percentage explained") rowtitle(`decompose') twidth(20)

// drop latent variables
capture drop *_LATENT
end
