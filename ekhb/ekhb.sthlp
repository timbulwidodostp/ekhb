{smcl}
{title:Title}

{phang} {cmd:ekhb} Extended decomposition of effects in non-linear probability models using the KHB-method {p_end}

{title:Syntax}

{p 8 17 2}
   {cmd: ekhb}
   {it:model-type}
   {it:depvar}
   {ifin}
{cmd:, } {opt d:ecompose(varname)} {opt m:ediators(varlist)} [ {it: options} ]
{p_end}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt:{opt d:ecompose(varname)}}key variable to be decomposed{p_end}
{synopt:{opt m:ediators(varlist)}}mediators of interest{p_end}
{synopt:{opt c:ontrols(varlist)}}control variables{p_end}
{synopt:{opt a:djust(varlist)}}mediators-as-controls{p_end}
{synopt:{opt dis:entangle}}disentangle mediators-as-controls{p_end}
{synopt:{opt patha}}show path A coefficients{p_end}
{synopt:{opt pathb}}show path B coefficients{p_end}
{synopt:{opt rel:iability(varname # [...])}}reliability of measurement variables{p_end}
{synopt:{opth cons:traints(numlist)}}apply specified linear constraints{p_end}
{synopt:{opt vce(vcetype)}}vcetype may be {cmd:robust}, {cmd:cluster} {it:clustvar}{p_end}
{synopt:{opt from(matname)}}initial values for the internal regression coefficients{p_end}
{synopt:{opt outmat(matname)}}output matrix from the internal regression coefficients; seldom used{p_end}
{synopt:{opt noi:sily}}show restricted and full model{p_end}
{synopt:{it:other}}other options allowed by {help gsem_model_options:gsem}{p_end}
{synoptline}
{p2colreset}{...}
{pstd} {it:model-type} can be {help regress}, {help logit}, {help probit}, {help cloglog}, or {help poisson}. Other models allowed by {help gsem family and link options:gsem} may also produce valid output, 
but check this by specifying option {it:noisily}.{p_end}
{pstd}{cmd:mi estimate} is allowed; see {help prefix}.{p_end}
{pstd}{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see {help weight}.{p_end}


{title:Description}

{pstd}{cmd:ekhb} applies the KHB method to compare the estimated coefficients between two nested non-linear probability models (Karlson/Holm/Breen 2011).
An important use of the technique is to decompose the total effect of a variable into a direct and an indirect component. The method is developed for models with binary outcomes.
It is a modification of and a partial extension to the original command. For more information, see {help khb}.{p_end}

{pstd}In linear regression models, decomposing the total effect into direct and indirect effects is straightforward. The decomposition is done by comparing the estimated coefficient of a key
variable of interest between a reduced model without mediator variables and a full model with one or more mediator variables added. The difference between the estimated coefficients of
the key variable of interest in the two models expresses the amount of mediation, that is, the size of the indirect effect.{p_end}

{pstd}The strategy for linear models does not hold in the context of nonlinear probability models such as logit, 
because the estimated coefficients of these models are not comparable between different models. The reason is a rescaling of the model induced by a property of these models: the coefficients and the error
variance are not separately identified. The KHB-method solves this problem. It allows the comparison of effects of nested models for many models of the Generalized SEM framework, including logit, probit, cloglog, and Poisson.
The original {cmd:khb} command compares the full model with a reduced model that substitutes some mediator variables by the residuals of the mediator variables obtained from a regression of the mediator variables on the key variables.
The {cmd:ekhb} command estimates the total, direct, and indirect effect using the products of the different terms obtained from simultaneous equations.{p_end}

{pstd}The main benefits of {cmd:ekhb} over {cmd:khb} lie in its options. The option {it:reliability}, borrowed from {help sem}, conveniently implements corrections to classical measurement error
in the mediator variables. The option {it:constraints} allows for constraints to be passed on to the internal regression coefficients.
In addition, the estimation can be combined with multiple imputation using the {it:mi estimate} prefix.{p_end}

{pstd}{cmd:ekhb} is faster than {cmd:khb} in small to medium-sized datasets,
but can be much slower in larger datasets. This may be a relevant consideration when choosing between the two commands.{p_end}


{title:Options}

{phang}{opt m:ediators(varlist)} specifies which variables mediate between the {it:decompose-var} and the {it:depvar}.
For these variables, the disentangled coefficients are returned and a table is shown with the percentage of mediation.{p_end}

{phang}{opt c:ontrols(varlist)} specifies which variables must be held constant in estimating both the total effect and the direct and indirect effect.
These variables are best though of as confounders of the {it:decompose-var} and the {it:depvar}.{p_end}

{phang}{opt a:djust(varlist)} specifies which variables must be held constant in estimating the direct and indirect effect. Thus, they are additional mediators whose effects we are not interested in.
These variables are best though of as confounders of the {it:mediators} and the {it:depvar}. Formally speaking, adjustment variables are part of the indirect effect.
However, if you specify this option, the adjustment variables are not included in the indirect effect and an "adjustment effect" is reported separately.{p_end}

{phang}{opt dis:entangle} requests that the disentangled coefficients of the {it:adjust} variables are returned. This slows down the estimation in large datasets.
By default, all disentangled coefficients of the {it:mediator} variables are returned. If you do not want this, specify them as {it:adjust} variables.{p_end}

{phang}{opt patha} and {opt pathb} request that the estimates of path A and path B are returned.
Path A appends the coefficients and standard errors from the {it:decompose-var} to the {it:mediators} to the estimation results.
Path B appends the coefficients and standard errors from the {it:mediators} to the {it:depvar} to the estimation results.
The product of path A and path B equals the indirect effect.
There is no {it:pathc} option, since path C is returned by default as the direct effect.{p_end}

{phang}{opt rel:iability(varname # [varname # [...]])} allows you to specify the fraction of variance not due to measurement error for measurement variables. It follows the syntax of {help sem and gsem option reliability:sem}.
It is intended for the correction of classical measurement error in {it:mediator} variables.
Because mediator variables are endogenous variables in the system of equations, this option corrects the estimates via latent variables, which substantially slows down the estimation.
It is not advisable to correct for measurement error in the {it:decompose-var} or {it:depvar}. If you want to do so nonetheless, you have to modify the sourcecode.{p_end}

{phang}{opth cons:traints(numlist)} applies linear constraints that are predefined by the user to the internal regressions.
Because the internal regressions are conducted using simultaneous equations, the constraints must refer to the particular equation name.
See {help sem and gsem option constraints:constraints} for examples or use option {it:noisily} to show the equation names.

{phang}{opt from(matname)} is used to pass on a coefficient matrix (vector) to the internal regressions.
If the provided matrix does not exist, contains a single missing value, or contains a single zero value, the option is ignored. 

{phang}{opt outmat(matname)} is a rarely used option to obtain the coefficient matrix (vector) from the internal regressions.
This can be useful when estimating sequential regressions and access to these estimations is restricted.
In those cases, specify the same name in {it:outmat} and {it:from} to make outmat pass on the regression coefficients from one estimation to the next.
If you simply want to check the internal regressions, it is more informative to use {it:noisily}.{p_end}

{phang}{opt noi:sily} is used to show the complete output of the simultaneous equations that are used to estimate the decomposition.
This is especially useful to detect problems that occur in the internal regressions.{p_end}

{phang}{it:other options} from {help gsem_model_options:gsem} are also allowed and are applied to the estimation of the internal regressions.{p_end}


{title:Example 1: decomposing age differences in the prevalence of diabetes}

{pstd}{cmd: webuse nhanes2d}{p_end}
{pstd}{cmd: logit diabetes age race}{p_end}
{pstd}{cmd: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race)}{p_end}
{pstd}{cmd: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race) vce(cluster location)}{p_end}
{pstd}{cmd: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race) vce(cluster location) adjust(sizplace) disentangle}{p_end}


{title:Example 2: constraints and corrections for measurement error}

{pstd}{cmd: constraint define 1 [diabetes]copper=[diabetes]iron}{p_end}
{pstd}{cmd: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race) constraints(1) noisily}{p_end}
{pstd}{cmd: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race) reliability(copper 0.82)}{p_end}


{title:Example 3: multiple imputation}

{pstd}{cmd: drop if diabetes==.}{p_end}
{pstd}{cmd: mi set wide}{p_end}
{pstd}{cmd: mi register regular diabetes age race iron}{p_end}
{pstd}{cmd: mi register impute zinc copper}{p_end}
{pstd}{cmd: mi impute chained (pmm, knn(5) include(diabetes age race iron)) zinc copper, add(10) chaindots}{p_end}
{pstd}{cmd: mi estimate: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race)}{p_end}
{pstd}{cmd: mi estimate: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race) patha pathb}{p_end}


{title:Example 4: parallel processing (advanced)}

{pstd}{cmd: parallel initialize 3}{p_end}
{pstd}{cmd: mipllest, replace: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race)}{p_end}
{pstd}{cmd: mirubin, stub(_mipllest_)}{p_end}

{pstd}{cmd: ! erase _mipllest_*.ster}{p_end}
{pstd}{cmd: capture estimates drop _mipllest_*}{p_end}
{pstd}{cmd: capture erase _mipllest_script.do}{p_end}
{pstd}{cmd: mipllest, replace: ekhb logit diabetes, decompose(age) mediators(iron zinc copper) controls(race) from(initvalues) outmat(initvalues)}{p_end}
{pstd}{cmd: mirubin, stub(_mipllest_)}{p_end}


{title:Also see}

{pstd}From Stata: {help gsem}{p_end}

{pstd}From SSC: {help khb}{p_end}


{title:References}

{pstd} Karlson, K.B./Holm, A./Breen, R. (2011): Comparing regression coefficients between same-sample nested models using logit and probit. A new method. Sociological Methodology 42:286-313.{p_end}


{title:Author}

{pstd}Bram Hogendoorn (b.hogendoorn@uva.nl)
{pstd}This program has been written in Stata, not Mata. Any volunteer who would like to experiment with translating this program is invited to do so. All code can be freely distributed.
