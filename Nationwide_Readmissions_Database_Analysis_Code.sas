

/****************************/
/*Import cost-to-charge file*/
proc import datafile = "yourpath\cc2015NRD.csv"
	out = prelim.cc2015nrd
	dbms = csv
    replace;
    getnames = YES;
run;


/*******************************************************************************/
/*Load core files Nrd_2015_q1q3 and Nrd_2015_q4, merge two files named nrd_2015*/
proc sort data = prelim.nrd_2015_q1q3 out = nrd_2015_q1q3;
	by NRD_visitlink;
run;

proc sort data = prelim.nrd_2015_q4 out = nrd_2015_q4;
	by NRD_visitlink;
run;

data nrd_2015;
	merge nrd_2015_q1q3 nrd_2015_q4;
	by NRD_visitlink;
run;


/*Load severity files nrd_2015q1q3_severity and nrd_2015q4_severity, set two files named nrd_2015_severity*/
proc sort data = prelim.nrd_2015q1q3_severity out = nrd_2015q1q3_severity;
	by KEY_NRD;
run;


proc sort data = prelim.nrd_2015q4_severity out = nrd_2015q4_severity;
	by KEY_NRD;
run;


data nrd_2015_severity;
	set nrd_2015q1q3_severity nrd_2015q4_severity;
run;


proc sort data = nrd_2015_severity;
	by KEY_NRD;
run;


/*Load hospital file*/
data nrd_2015_hospital;
	set prelim.nrd_2015_hospital;
run;


/*Load cost-to-charge file*/
data cc2015nrd;
	set prelim.cc2015nrd;
run;



/*Combine corefile with severity data to get nrd_2015_se*/
proc sort data = nrd_2015;
	by KEY_NRD;
run;


proc sort data = nrd_2015_severity;
	by KEY_NRD;
run;


proc sql;
	create table nrd_2015_se as
	select a.*, b.*
		from nrd_2015 as a 
		left join nrd_2015_severity as b
			on a.KEY_NRD = b.KEY_NRD
	;
quit;


/*Combine nrd_2015_se dataset with hospital data to get nrd_2015_se_hosp*/
proc sql;
	create table nrd_2015_se_hosp as
    select a.*, b.*
		from nrd_2015_se as a 
		left join nrd_2015_hospital as b
			on a.HOSP_NRD = b.HOSP_NRD
	;
quit;



/*Combine nrd_2015_se_hosp dataset with cost-to-charge data to get nrd_2015_se_hosp_cost*/
data cc2015nrd;
	set cc2015nrd;
	HOSP_NRD_new = input(HOSP_NRD, 6.);
run;


data cc2015nrd (rename=(HOSP_NRD_new = HOSP_NRD) drop= HOSP_NRD);
	set cc2015nrd;
run;


proc sql;
	create table nrd_2015_se_hosp_cost as
	select a.*, b.CCR_NRD, b.WAGEINDEX
		from nrd_2015_se_hosp as a 
		left join cc2015nrd as b
			on a.HOSP_NRD = b.HOSP_NRD
	;
quit;


/*******************************************************************************/
/*******************************************************************************/
/*Question 1*/
/*Identify those with gastroenteritis(GE)-related hospitalizations*/
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost;
	array diag(2)$ DX1 I10_DX1;
	ge = 0;
	do i = 1 to 2;
	if diag(i) in ("0030","004","0040","0041","0042","0043","0048","0049","005",
		"0050","0051","0052","0053","0054","0058","00581","00589","0059","0061",
		"0062","007","0070","0071","0072","0073","0074","0075","0078","0079","008",
		"0080","00800","00801","00802","00803","00804","00809","0081","0082","0083",
		"0084","00841","00842","00843","00844","00845","00846","00847","00849","0085",
		"0086","00861","00862","00863","00864","00865","00866","00867","00869","0088",
		"009","0090","0091","0092","0093","558","5581","5582","5583","5584","55841",
		"55842","5589","A020","A03","A030","A031","A032","A033","A038","A039","A04",
		"A040","A041","A042","A043","A044","A045","A046","A047","A0471","A0472","A048",
		"A049","A05","A050"," A051","A052","A053","A054","A055","A058","A059","A060",
		"A061","A07","A070","A071","A072","A073","A07.4","A078","A079","A08","A080",
		"A081","A0811","A0819","A082","A083","A0831","A0832","A0839","A084","A088",
		"A09","K52","K520","K521","K522","K5221","K5222","K5229","K523","K528",
		"K5281","K5282","K5283","K52831","K52832","K52838","K52839","K5289","K529")

	then ge = 1;
	drop i;
	end;
run;


/*Calculate crude counts/rates and weighted counts/rates of GE-related and GE-unrelated hospitalizations*/
/*Here I just want to know how many GE-related hospitalizations there are, 
so I did not deduplicate patients or apply any exclusion criteria.*/
proc freq data = nrd_2015_se_hosp_cost_ge;
	table ge;
run;


proc surveyfreq data = nrd_2015_se_hosp_cost_ge;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	table ge;
run;
/*Unweighted-9203(1.89%) GE-related hospitalizations*/
/*Weighted-25134(1.90%) GE-related hospitalizations*/
/*Unweighted-478886(98.11%) GE-unrelated hospitalizations*/
/*Weighted-1300476(98.10%) GE-unrelated hospitalizations*/


/*Create agegroup*/       
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
		if age < 3 then agegroup = 0; *0-<3 years old;
		else if 3 <= age < 13 then agegroup = 1; *<=3-<13 years old;
		else if 13 <= age < 18 then agegroup = 2; *<=13-<18 years old;
run;


/*Question 2*/
/*Counts/rates and weighted counts/rates of GE-related and GE-unrelated 
hospitalizations stratified by age group and sex*/
proc freq data = nrd_2015_se_hosp_cost_ge;
	table ge*(agegroup female); *Female = 1, Male = 0; 
run;


proc surveyfreq data = nrd_2015_se_hosp_cost_ge;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	table ge*(agegroup female);
run;


/*Generate patients level data */
proc sort data = nrd_2015_se_hosp_cost_ge;
	by NRD_VisitLink;
run;

proc sort data= nrd_2015_se_hosp_cost_ge out = nrd_2015_pt nodupkey;
	by NRD_VisitLink;
run;
/*391,005 patients, 488,089 visits*/


/*******************************************************************************/
/*******************************************************************************/
/*Patient characteristics: demographic information, comorbidities, and hospital characteristics*/
/*Comorbidities*/
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
/*define a pseudo discharge date using NRD_DaysToEvent and LOS*/
	pseudoDdate = NRD_DaysToEvent + LOS;
run;



proc sort data = nrd_2015_se_hosp_cost_ge;
	by NRD_VisitLink pseudoDdate;
run;


*Identify patients' clinical characteristics;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	if DXVER = . then DXVER = 9;
	else DXVER = DXVER;
	if PRVER = . then PRVER = 9;
	else PRVER = PRVER;
run;


*1. Hypertension;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label HTN = "Hypertension";
	HTN = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if comorbidity in: ("401", "402", "403", "404", "405") then HTN = 1;
		end;
		else if DXVER = 10 then do;
		if comorbidity in: ("I10", "I11", "I12", "I13", "I15", "I16", "I1A") then HTN = 1;
		end;
	end;
run;



*2. Heart failure;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label HF = "Heart failure";
	HF = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if comorbidity in: ("428") then HF = 1;
		end;
		else if DXVER = 10 then do;
		if comorbidity in: ("I50") then HF = 1;
		end;
	end;
run;



*3. Diabetes; 
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label DIAB = "Diabetes";
	DIAB = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if comorbidity in: ("250") then DIAB = 1;
		end;
		else if DXVER = 10 then do;
		if comorbidity in: ("E08", "E09", "E10", "E11", "E13") then DIAB = 1;
		end;
	end;
run;



*4. Asthma and chronic obstructive pulmonary diseases; 
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label COPD = "Asthma and chronic obstructive pulmonary diseases";
	COPD = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if comorbidity in: ("490", "491", "492", "493", "494", "495", "496") then COPD = 1;
		end;
		else if DXVER = 10 then do;
		if comorbidity in: ("J40", "J41", "J42", "J43", "J44", "J45", "J47") then COPD = 1;
		end;
	end;
run;



*5. Cystic fibrosis;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label CF = "Cystic fibrosis";
	CF = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if comorbidity in: ("2770") then CF = 1;
		end;
		else if DXVER = 10 then do;
		if comorbidity in: ("E84") then CF = 1;
		end;
	end;
run;



*6. Liver disease and viral hepatitis;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label LD = "Liver disease and viral hepatitis";
	LD = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if comorbidity in: ("070","570","571","572","573") then LD = 1;
		end;
		else if DXVER = 10 then do;
		if comorbidity in: ("B15","B16","B17","B18","B19","K70","K71","K72","K73","K74",
						"K75","K76","K77") then LD = 1;
		end;
	end;
run;



*7. Inflammatory bowel diseases;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label IBD = "Inflammatory bowel diseases";
	IBD = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if comorbidity in: ("555","556") then IBD = 1;
		end;
		else if DXVER = 10 then do;
		if comorbidity in: ("K50","K51") then IBD = 1;
		end;
	end;
run;



*8. Sickle cell diseases;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label sickle = "Sickle cell diseases";
	sickle = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if comorbidity in: ("2826") then sickle = 1;
		end;
		else if DXVER = 10 then do;
		if comorbidity in: ("D5700", "D5701", "D5702", "D5703", "D5709", "D571",
			"D5720", "D57211", "D57212", "D57213", "D57218",
			"D57219", "D5740", "D57411", "D57412", "D57413",
			"D57418", "D57419", "D5742", "D57431", "D57432",
			"D57433", "D57438", "D57439", "D5744", "D57451",
			"D57452", "D57453", "D57458", "D57459", "D5780",
			"D57811", "D57812", "D57813", "D57818", "D57819") then sickle = 1;
		end;
	end;
run;



*9. Cancer;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label Cancer = "Cancer";
	Cancer = 0;
	array comorbidity $ DX1-DX30 I10_DX1-I10_DX30;
	do over comorbidity;
		if DXVER = 9 then do;
		if ("140" <=: comorbidity <=: "208") or ("2090" <=: comorbidity <=: "2093") then Cancer = 1;
		end;
		else if DXVER = 10 then do;
		if ("C00" <=: comorbidity <=: "C96") then Cancer = 1;
		end;
	end;
run;



/*10. Mechanical ventilation will be used as a potential predictor for readmission*/
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	label venti = "Mechnical ventilation";
	venti = 0;
	array procedure $ PR1-PR15 I10_PR1-I10_PR15;
	do over procedure;
		if PRVER = 9 then do;
		if procedure in ("9390","9392","9601","9602","9603","9604","9605","9670","9671","9672") then venti = 1;
		end;
		else if PRVER = 10 then do;
		if procedure in: ("5A1935Z","5A1945Z","5A1955Z") then venti = 1;
		end;
	end;
run;



proc means data = nrd_2015_se_hosp_cost_ge n nmiss mean var STD min max q1 median q3;
	var N_DISC_U LOS;
run;


*Regroup season;
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	if DMONTH in (3,4,5)then season = 0; *Spring;
	else if DMONTH in (6,7,8) then season = 1; *Summer;
	else if DMONTH in (9,10,11) then season = 2; *Fall;
	else if DMONTH in (12,1,2) then season = 3; *Winter;

*Regroup patient location;
	if PL_NCHS in (1,2) then Pt_location = 0; *Large metropolitan areas with at least 1 million residents;
	else if PL_NCHS in (3,4) then Pt_location = 1; *small metropolitan areas with rsidents between 50,000 to 999,999;
	else if PL_NCHS in (5,6) then Pt_location = 2; *others (including micropolitan and nt metropolitan or micropolitan);

*Regroup primary insurance type;
	if PAY1 = 1 then INSUR = 0; *Medicare;
	else if PAY1 = 2 then INSUR = 1; *Medicaid;
	else if PAY1 = 3 then INSUR = 2; *Private insurance;
	else if PAY1 = 4 then INSUR = 3; *Self-pay;
	else if PAY1 = 5 or PAY1 = 6 then INSUR = 4; *No charge or other;
	else INSUR = .;

*Regroup hospital location;
	if HOSP_URCAT4 = 1 then hosp_location = 0; *Large metropolitan areas with at least 1 million residents;
	else if HOSP_URCAT4 = 2 then hosp_location = 1; *small metropolitan areas with less than 1 million residents;
	else if HOSP_URCAT4 = 3 or HOSP_URCAT4 = 4 then hosp_location = 2; *other (including micropolitan and non-urban areas);

*Regroup LOS;
	if LOS <1 then los_group = 0; *0-25th;
	else if 1 <= LOS < 2 then los_group = 1; *25-50th;
	else if 2 <= LOS < 4 then los_group = 2; *50-75th;
	else if LOS >= 4 then los_group = 3; *76th-100th;

*Regroup N_DISC_U;
	if N_DISC_U < 459408 then case_group = 0; *0-25th;
	else if 459408 <= N_DISC_U < 824359 then case_group = 1; *25-50th;
	else if 824359 <= N_DISC_U < 1901450 then case_group = 2; *50-75th;
	else case_group = 3; *76th-100th;
run;




proc format;
	value sexf
		0 = "Male"
 		1 = "Female";
	value agegrpf
		0 = "Age 0-3"
		1 = "Age 3-13"
		2 = "Age 13-18"
		. = "Missing";
	value incomef
		1 = "0-25th"
		2 = "26-50th"
		3 = "51-75th"
		4 = "76-100th"
		. = "Missing";
	value insurf
		0 = "Medicare"
		1 = "Medicaid"
		2 = "Private insurance"
		3 = "Self-pay"
		4 = "No charge or other"
		. = "Missing";
	value Pt_locationf
		0 = "Large"
		1 = "Small"
		2 = "Other"
		. = "Missing";
	value Hos_locationf
		0 = "Large"
		1 = "Small"
		2 = "Other";
	value severf
		0 = "No class specified"
		1 = "Minor"
		2 = "Moderate"
		3 = "Major"
		4 = "Extreme"
		. = "Missing";
	value seasonf
		0 = "Spring"
		1 = "Summer"
		2 = "Fall"
		3 = "Winter";
	value sizef
		1 = "Small"
		2 = "Medium"
		3 = "Large"
		. = "Missing";
	value EDf
		0 = "Non ED"
		1 = "ED"
		2 = "ED"
		3 = "ED"
		4 = "ED";
	value casef
		0 = "0-25th"
		1 = "26-50th"
		2 = "51-75th"
		3 = "76-100th";
	value htnf
		0 = "No"
		1 = "Yes";
	value afibf
		0 = "No"
		1 = "Yes";
	value hff
		0 = "No"
		1 = "Yes";
	value diabf
		0 = "No"
		1 = "Yes";
	value copdf
		0 = "No"
		1 = "Yes";
	value cff
		0 = "No"
		1 = "Yes";
	value hivf
		0 = "No"
		1 = "Yes";
	value ldf
		0 = "No"
		1 = "Yes";
	value jiaf
		0 = "No"
		1 = "Yes";
	value ibdf
		0 = "No"
		1 = "Yes";
	value sicklef
		0 = "No"
		1 = "Yes";
	value cancerf
		0 = "No"
		1 = "Yes";
	value ventif
		0 = "No"
		1 = "Yes";
run;



/*format the data*/
data nrd_2015_se_hosp_cost_ge;
	set nrd_2015_se_hosp_cost_ge;
	format FEMALE sexf. agegroup agegrpf. season seasonf. INSUR insurf. Pt_location Pt_locationf. case_group casef.
		hosp_location Hos_locationf. APRDRG_Severity severf. HOSP_BEDSIZE sizef. HCUP_ED edf. ZIPINC_QRTL incomef.
		HTN htnf. HF hff. DIAB diabf. COPD copdf. CF cff. 
		LD ldf. IBD ibdf. sickle sicklef. Cancer cancerf. venti ventif.;
run;
 


/*******************************************************************************/
/*******************************************************************************/
/*Generate comorbidities for each patient based on their records*/
proc sql;
	create table comor as 
	select distinct nrd_visitlink, max(HTN) as HTN, max(HF) as HF, max(DIAB) as DIAB,
			max(COPD)as COPD, max(CF) as CF, max(LD) as LD, max(IBD) as IBD, 
			max(sickle) as sickle, max(Cancer) as Cancer
		from nrd_2015_se_hosp_cost_ge
			group by NRD_VisitLink;
quit;
/*391,005 patients*/


/*GE-related hospitalizations*/
data nrd_2015_ge;
	set nrd_2015_se_hosp_cost_ge;
	if ge = 1;
run;
/*9,203 GE-related visits*/

/*Patient level data for those who hospitalized for GE: 8,929 patients*/
proc sort data = nrd_2015_ge nodupkey out = nrd_2015_ge_ID (drop = HTN HF DIAB COPD CF LD IBD sickle Cancer);
	by NRD_VisitLink;
run;



/*Combine patient-level data with correspoinding comorbidities*/
proc sql;
	create table nrd_2015_ge_w_comor as 
	select a.*, b.*
		from nrd_2015_ge_ID as a 
		left join comor as b
			on a.NRD_VisitLink = b.NRD_VisitLink 
			order by a.NRD_VisitLink
	;
quit;



/*Patients without GE-related hospitalizatoins*/
/*Patient level data for those who did not hospitalize for GE: 382,076 patients*/
data nrd_2015_nonge_ID;
	merge nrd_2015_pt nrd_2015_ge_ID(in = ge);
	by NRD_VisitLink;
	if not(ge);
run;



proc sql;
	create table nrd_2015_nonge_ID2 as 
	select a.*
		from nrd_2015_se_hosp_cost_ge as a
		inner join nrd_2015_nonge_ID as b
			on a.NRD_VisitLink = b.NRD_VisitLink
			order by a.NRD_VisitLink, a.pseudoDdate
	;
quit;



proc sort data = nrd_2015_nonge_ID2 nodupkey out = nrd_2015_nonge_ID2;
	by NRD_VisitLink;
run;



proc sql;
	create table nrd_2015_nonge_w_comor as 
	select a.*, b.*
		from nrd_2015_nonge_ID2 as a 
		left join comor as b
			on a.NRD_VisitLink = b.NRD_VisitLink 
			order by a.NRD_VisitLink;
quit;



/*Combine patient characteristics for patients with GE-related and GE-unrelated conditions*/
data nrd_2015_all_comor;
	set nrd_2015_ge_w_comor nrd_2015_nonge_w_comor;
run;

/*Evaluation of differences between two groups*/
proc ttest data = nrd_2015_all_comor;
	var AGE;
	class ge;
run;


proc freq data = nrd_2015_all_comor;
tables ge*(FEMALE agegroup INSUR Pt_location ZIPINC_QRTL APRDRG_Severity HOSP_BEDSIZE 
		hosp_location HOSP_UR_TEACH case_group HCUP_ED season
		HTN HF DIAB COPD CF LD IBD sickle Cancer)/chisq;
run;



/*******************************************************************************/
/*******************************************************************************/
/*Question 3*/
/*Characteristics of patients having GE-related hospitalizations*/
proc means data = nrd_2015_ge_w_comor n nmiss mean var STD min max q1 median q3;
	var AGE N_DISC_U LOS;
run;


proc freq data = nrd_2015_ge_w_comor;
	table FEMALE agegroup INSUR Pt_location ZIPINC_QRTL APRDRG_Severity HOSP_BEDSIZE 
		hosp_location HOSP_UR_TEACH case_group HCUP_ED season
		HTN HF DIAB COPD CF LD IBD sickle Cancer;
run;


proc surveymeans data = nrd_2015_ge_w_comor;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	var AGE;
run;


proc surveyfreq data = nrd_2015_ge_w_comor;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	table FEMALE agegroup INSUR Pt_location ZIPINC_QRTL APRDRG_Severity HOSP_BEDSIZE 
		hosp_location HOSP_UR_TEACH case_group HCUP_ED season
		HTN HF DIAB COPD CF LD IBD sickle Cancer;
run;



/*Characteristics of patients not having GE-related hospitalizations*/
proc means data = nrd_2015_nonge_w_comor n nmiss mean var std min max;
	var AGE N_DISC_U LOS;
run;


proc freq data = nrd_2015_nonge_w_comor;
	table FEMALE agegroup INSUR Pt_location ZIPINC_QRTL APRDRG_Severity HOSP_BEDSIZE 
		hosp_location HOSP_UR_TEACH case_group HCUP_ED season
		HTN HF DIAB COPD CF LD IBD sickle Cancer;
run;


proc surveymeans data = nrd_2015_nonge_w_comor;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	var AGE N_DISC_U LOS;
run;

proc surveyfreq data = nrd_2015_nonge_w_comor;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	table FEMALE agegroup INSUR Pt_location ZIPINC_QRTL APRDRG_Severity HOSP_BEDSIZE 
		hosp_location HOSP_UR_TEACH case_group HCUP_ED season
		HTN HF DIAB COPD CF LD IBD sickle Cancer;
run;



/*******************************************************************************/
/*******************************************************************************/
/*Apply exclusion criteria*/
data nrd_2015_readm;
	set nrd_2015_se_hosp_cost_ge;
	/*flag index event*/
	indexevent=0;
	if DIED ^= 1 and 1 <= DMONTH <=11 and LOS ^= . and ge = 1 and SAMEDAYEVENT = 0 and ELECTIVE = 0 then indexevent=1;
run;

proc freq data = nrd_2015_readm;
	table DIED DMONTH LOS SAMEDAYEVENT ELECTIVE TOTCHG;
run;



/*Patients with missingness on key variables (length of stay, total charge, death, visit link, and days to event) are excluded.
To qualify as an index admission eligible for readmissions analysis, patients must not have died in hospital during their visit 
and must have been discharged from the hospital before 1 December 2015, to provide a 30-day time frame for analyzing readmissions. 
In our readmissions sample, we excluded patients with an elective hospital admission.*/
data nrd_2015_readm;
	set nrd_2015_readm;
	if LOS ne . and LOS ne .A and LOS ne .B and LOS ne .C;
	if TOTCHG ne .;
	if NRD_DaysToEvent ne .;
run;


/*Calculate the proportion of readmission among those index GE-related hospitalization*/
proc freq data = nrd_2015_readm;
	table indexevent;
run;


/*Total record; unweighted number of records with an index event*/
proc freq data = nrd_2015_readm;
	tables indexevent indexevent*(FEMALE agegroup DQTR season);
run;


/*Weighted national frequency of index event by sex age discharge quarter*/
proc surveyfreq data = nrd_2015_readm;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	tables  indexevent indexevent*(FEMALE agegroup DQTR season);
run;



/*Extract ge-related hospitalizations that meet the inclusion criteria*/
data nrd_2015_readm_ge;
	set nrd_2015_readm;
	where indexevent = 1;
run;
/*7,673 index events*/


/*Extract the first hospitalization: we chose the first one since there may be more than one eligible index event for a patient*/
proc sort data = nrd_2015_readm_ge nodupkey out = nrd_2015_readm_ge_first;
	by NRD_VisitLink;
run;
/*7,469 patients with index event*/


/*Identify 30-day all-cause readmission (readmission for any reason)*/
proc sql;
	create table readmission as
	select distinct a.*,
    	case when b.KEY_NRD ne . then 1 else 0 end as readmit length=3 label='Readmission for any cause(0/1)',
				          b.KEY_NRD as key_nrd_r label='Visit ID for readmission',
				          b.TOTCHG as readmitchg length=3 label='Total charge for the closet readmission',
						  b.CCR_NRD as ccr_readm length=3 label='cost to charge ratio for the closet readmission',
						  b.NRD_DaysToEvent as daystoreadmit label='Daystoevent of the closest readmission',
						  b.MDC_noPOA as MDC_noPOA_r label="DRG for readmission",
						  b.pseudoddate as pseudoddate_r label='Pseudo discharge date of the closet readmission'
		from nrd_2015_readm_ge_first as a 
		left join Nrd_2015_se_hosp_cost_ge as b
			on a.NRD_VisitLink = b.NRD_VisitLink and a.KEY_NRD ne b.KEY_NRD  and (b.NRD_DaysToEvent - a.pseudoddate) between 0 and 30
				order by a.NRD_VisitLink, a.KEY_NRD, b.NRD_DaysToEvent, b.pseudoddate;
quit;
/*7,560 readmission records, which means that some patients have more than one readmission*/


/*Extract the closest readmission to each index event; all readmission within 30 days*/
data readmission1 (drop=totalreadmissions) /*keep the first readmission only*/
     readmissionAll (keep= NRD_VisitLink KEY_NRD totalreadmissions) /*keep total readmission only*/;
	set readmission;
	by NRD_VisitLink KEY_NRD;
	attrib totalreadmissions label = 'Total readmission';
    if first.KEY_NRD then do;
		totalreadmissions = 0;
	output readmission1;
	end;
	totalreadmissions + readmit;
	if last.KEY_NRD then output readmissionAll;
run;
/*7,469 obeservartions in readmission1, readmissionall*/



/*******************************************************************************/
/*******************************************************************************/
/*Question 4, 5*/
/*Calculate the 30-day all-cause readmission rate*/
proc freq data = readmission1;
	table readmit;
run;


proc freq data = readmission1;
	table readmit*(FEMALE agegroup);
run;



/*Weighted 30-day all-cause readmission rate*/
proc surveyfreq data = readmission1;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	table readmit;
run;


proc surveyfreq data = readmission1;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	table readmit*(FEMALE agegroup);
run;


/*******************************************************************************/
/*******************************************************************************/
/*Question 6*/
/*Mean total charge & cost for index hospitalzation*/
data readmission1_cost;
	set readmission1;
	indexcost = TOTCHG*CCR_NRD;
run;


proc means data = readmission1_cost ;
	var indexcost TOTCHG;
	class readmit;
run;


proc ttest data = readmission1_cost ;
	var indexcost TOTCHG;
	class readmit;
run;

/*Mean cost and charge for first readmission*/
data readmission1_re;
	set readmission1;
	if readmit = 1;
	cost_readmin1= readmitchg*ccr_readm;
run;

proc means data = readmission1_re ;
	var cost_readmin1 readmitchg;
run;



/*******************************************************************************/
/*******************************************************************************/
/*Question 7*/
/*Top fourteen reasons for readmission*/
/*mdcall_2021f. is a mapping tool generated by HCUP, wich can help us map the dischaege DRG code to the disease categories */
proc format;
	value mdcall_2021f
		0 = "Ungroupable"
		1 = "Nervous System"
		2 = "Eye"
		3 = "Ear, Nose, Mouth, And Throat"
		4 = "Respiratory System"
		5 = "Circulatory System"
		6 = "Digestive System"
		7 = "Hepatobiliary System and Pancreas"
		8 = "Musculoskeletal System and Connective Tissue"
		9 = "Skin, Subcutaneous Tissue, and Breast"
		10 = "Endocrine, Nutritional, and Metabolic System"
		11 = "Kidney and Urinary Tract"
		12 = "Male Reproductive System"
		13 = "Female Reproductive System"
		14 = "Pregnancy, Childbirth, and Puerperium"
		15 = "Newborn and Other Neonates (Perinatal Period)"
		16 = "Blood and Blood Forming Organs and Immunological Disorders"
		17 = "Myeloproliferative Diseases and Disorders (Poorly Differentiated Neoplasms)"
		18 = "Infectious and Parasitic Diseases and Disorders"
		19 = "Mental Diseases and Disorders"
		20 = "Alcohol/Drug Use or Induced Mental Disorders"
		21 = "Injuries, Poison, and Toxic Effect of Drugs"
		22 = "Burns"
		23 = "Factors Influencing Health Status"
		24 = "Multiple Significant Trauma"
		25 = "Human Immunodeficiency Virus (HIV) Infection";
run;


proc surveyfreq data = readmission1 order = freq; 
    strata NRD_STRATUM;
    cluster HOSP_NRD;
    weight DISCWT;    
    tables readmit*MDC_noPOA_R;
    format MDC_noPOA_R mdcall_2021f.;
run;



/*******************************************************************************/
/*******************************************************************************/
/*Question 8*/
/*Univariate analysis for the potential predictors of 30-day readmission, we use the dataset readmission1 becasue we only capture whether there is a readmission or not(binary variable)*/
%macro logit(predictor);
proc logistic data = readmission1 descending;
class &predictor./ref=first param=ref;
model readmit = &predictor.;
RUN;
%mend;
%logit(FEMALE);
%logit(agegroup);
%logit(INSUR);
%logit(Pt_location);
%logit(ZIPINC_QRTL);
%logit(HTN);
%logit(HF);
%logit(DIAB);
%logit(COPD);
%logit(CF);
%logit(LD);
%logit(IBD);
%logit(sickle);
%logit(Cancer);
%logit(HOSP_BEDSIZE);
%logit(hosp_location);
%logit(season);
%logit(venti);



/*Prediction model for readmission for index GE-related hospitalizations*/
proc surveylogistic data = readmission1 order = internal;
	cluster HOSP_NRD;
	weight DISCWT;
	strata NRD_STRATUM;
	class  FEMALE agegroup INSUR Pt_location ZIPINC_QRTL HOSP_BEDSIZE 
		hosp_location season HTN HF DIAB COPD CF LD IBD sickle Cancer venti/ref= first param=ref;
	model readmit(event = "1") = FEMALE agegroup INSUR Pt_location ZIPINC_QRTL HOSP_BEDSIZE 
		hosp_location season HTN HF DIAB COPD CF LD IBD sickle Cancer venti;
run;
/************************************END***************************************/
/************************************END***************************************/

