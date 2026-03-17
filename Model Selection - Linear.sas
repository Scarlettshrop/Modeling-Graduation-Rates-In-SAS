libname ipeds '~/IPEDS/';
options fmtsearch=(IPEDS);

/** proc catalog catalog=ipeds.formats;
contents;
quit; **/

/** proc format library=ipeds fmtlib;
run; **/

/** Calculation of Graduation Rates (Response variable for this project) **/

proc sql;
  create table GradRates as 
    select 
        cohort.Total,
        grads.Total as Grads_Total,
        Grads.UnitId, 
        Grads.Total/Cohort.Total as GradRate
    from ipeds.Graduation(where=(group contains 'Completers')) as Grads
         inner join
         ipeds.Graduation(where=(group contains 'Incoming')) as Cohort
      on Grads.UnitID eq Cohort.UnitID
      where cohort.Total ge 200;
        ;
quit;

/* Sorted dataset by unitID to ensure it is in the correct order 

   Then standardize the Grad Rate to the variable be the Average Graduation Rate*/

proc sort data = Gradrates out = GradRateUse1;
    by unitid;
run;

proc standard data=gradrateuse1 mean=0 out=GradRateUse;
    var Gradrate;
run;

/** GradRates vs Characteristics Model Selection */

proc contents data=ipeds.characteristics;
run;

/** Turned fips states into Regions */
proc format;
    value $Sta
    'Texas', 'Oklahoma', "Arkansas", 'Louisiana', 
    "Mississippi",'Alabama','Georgia','Florida',
    'Tennessee',"South Carolina",'North Carolina',
    'Virginia',"Kentucky", "West Virginia", "Puerto Rico"
     = 'South'

    'Washington', 'Oregon', "Idaho", "Montana",
    "Wyoming", "California", "Nevada", "Utah",
    "Colorado", "Arizona", "New Mexico",
    "Alaska", "Hawaii" = "West"

    "North Dakota", "Minnesota", "Wisconsin", "Michigan",
    "South Dakota", "Iowa", "Illinois", "Indiana", "Ohio",
    "Nebraska", "Kansas", "Missouri" = "Midwest"

    "Maine", "New Hampshire", "Vermont", 
    "Massachusetts", "New York", "Connecticut", 
    "Rhode Island", "Pennsylvania", "New Jersey", "Maryland", "Delaware", "District of Columbia" = "Northeast";
run;

/** Edit this further to create a variable of White vs Nonwhite students (this will help cut down on variables) **/

proc sql;
    create table CharacteristicsUse as
    select 
    case
          when hloffer ge 1 and hloffer < 7 then "Below Master's"
          when hloffer eq 7 then "Master’s with No Doctoral"
		  when hloffer eq 8 then "Master’s with No Doctoral"
		  when hloffer eq 9 then 'Doctoral'
        end
		as HLOffer, GradRateUse.*, put(put(fips, fips.), $Sta.) as Region length=12, iclevel, control, scan(put(c.locale,locale.), 1, ':') as locale, 
        instcat, /**C21ENPRF,**/ cbsatype
    from GradRateUse inner join ipeds.characteristics as c on c.unitid = GradRateUse.unitid
    where c.hloffer ne -3 and c.iclevel ne -3 and c.locale ne -3 and 
    c.instcat ge 0 and c.C21ENPRF ne -2 and c.CBSATYPE ne -2 and c.control ne -3
    ;
quit;

/** Simplified HLOFFER and Locale to have greater significance in the model, will attempt to cut down on FIPS by region as it is currently too overwhelming on the model, 
and took out all "unknown" data points to get rid of unnessecary info that could skew the model **/

proc glmselect data=CharacteristicsUse;
    class HLoffer region--cbsatype;
    model Gradrate = HLoffer region--cbsatype / selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    ;
run;

/** GradRates vs Salaries Model Selection */

proc contents data=ipeds.salaries;
run;

/** Took out salary totals that are specific to gender and just focus on total salary for all staff*/

proc sql;
    create table salariesuse as
    select GradRateUse.*, sa09mct, sa09mot, (s.sa09mot/s.sa09mct)/1000 as AvgSalary, (total/sa09mct) as Student_Staff_Ratio
    from GradRateUse inner join ipeds.salaries as s on s.unitid = GradRateUse.unitid
    where s.rank eq 7
    ;
quit;

proc glmselect data=salariesuse;
    model Gradrate =  sa09mct sa09mot AvgSalary Student_Staff_Ratio/ selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    ;
run;


/** GradRates vs GradExtended Model Selection */

proc contents data=ipeds.graduationextended;
run;

/** Took out variables where Race is 2 or more and where race is unknown. Also turned race into white vs nonwhite variables for simplicity**/

proc sql;
    create table ExtendedUse as
    select GradRateUse.*, men, women, (graiant+grasiat+grbkaat+grhispt+grnhpit) as NonWhite, grwhitt as White
    from GradRateUse inner join ipeds.graduationextended as gra on gra.unitid = GradRateUse.unitid
    ;
quit;


proc glmselect data=ExtendedUse;
    model Gradrate =  men--White/ selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    ;
run;

/** GradRates vs Tuition Model Selection */

proc contents data=ipeds.tuitionandcosts;
run;

proc sql;
    create table tuitionuse as
    select  GradRateUse.*, tuition1, fee1, tuition2, fee2, tuition3, fee3, room, roomcap,
    board, roomamt, boardamt
    from GradRateUse inner join ipeds.tuitionandcosts as t on t.unitid = GradRateUse.unitid
    where board gt 0
    ;
quit;

proc glmselect data=tuitionuse;
    class board;
    model Gradrate =  tuition1--boardamt/ selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    ;
run;

/** The next two models were created to see if manipulating the tuition to include or exclude fees would result in dinnerent results. It did not alter the results and they are not different
    than the model run above. Maybe take out fees to cut down on varirables in final model?**/

proc sql;
    create table tuitionuse2 as
    select  GradRateUse.*, tuition1/1000 as DistrictTuition1k, tuition2/1000 as InstateTuition1k, tuition3/1000 as outofstatetuition1k, room, roomcap,
    board, roomamt, boardamt
    from GradRateUse inner join ipeds.tuitionandcosts as t on t.unitid = GradRateUse.unitid
    where board gt 0
    ;
quit;

proc glmselect data=tuitionuse2;
    class board;
    model Gradrate =  DistrictTuition1k--boardamt/ selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    ;
run;

/** THE FINAL TUITION SQL AND MODEL I USED */

proc sql;
    create table tuitionuse3 as
    select  GradRateUse.*, (tuition1+fee1+roomamt+boardamt) as DTuitionFee, (tuition2+fee2+roomamt+boardamt) as ISTuitionFee, (tuition3+fee3+roomamt+boardamt) as OStuitionFee, room, roomcap,
    scan(put(t.board,board.), 1, ',') as MealPlan
    from GradRateUse inner join ipeds.tuitionandcosts as t on t.unitid = GradRateUse.unitid
    where board gt 0
    ;
quit;

proc freq data=tuitionuse3;
    table MealPlan;
run;

proc glmselect data=tuitionuse3;
    class MealPlan;
    model Gradrate = DTuitionFee--MealPlan/ selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    ;
run;

/** First run at a Test Model - Did not end up using this one**/

proc sql;
    create table TestModel as  
    select g.unitid, g.GradRate, g.Total, region, control, hloffer, locale, instcat, cbsatype, AvgSalary, White, Nonwhite,
            men, women, tuition3, roomcap, roomamt, boardamt, fee3, board
    from GradRateuse as g inner join characteristicsuse as c on c.unitid = GradRateUse.unitid
    inner join salariesuse as s on s.unitid = GradRateUse.unitid
    inner join ExtendedUse as e on e.unitid = GradRateUse.unitid
    inner join tuitionuse as t on t.unitid = GradRateUse.unitid;
quit;

proc glmselect data=TestModel;
    class region--cbsatype board;
    model Gradrate = total--board/ selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    ;
run;

/** The model above was altered to add in the simplified race categories and simplified tuition and costs varibles**/

/** Test Model 2 - Did not end up using this one */


proc sql;
    create table TestModel2 as  
    select g.unitid, g.GradRate, g.Total as 'Total Students'n, region, control, hloffer as "Highest Level of Degree Offered"n, locale, instcat, cbsatype, 
    AvgSalary as "Average Salary 1k"n, White as "White Students"n, Nonwhite as "Non-White Students"n,
            men, women, OStuitionFee/1000 as "Out-of-State COA 1k"n, roomcap as "Total Room Capacity"n
    from GradRateuse as g inner join characteristicsuse as c on c.unitid = GradRateUse.unitid
    inner join salariesuse as s on s.unitid = GradRateUse.unitid
    inner join ExtendedUse as e on e.unitid = GradRateUse.unitid
    inner join tuitionuse3 as t on t.unitid = GradRateUse.unitid;
quit;

proc glmselect data=TestModel2;
    class region--cbsatype;
    model Gradrate = "Total Students"n--"Total Room Capacity"n/ selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    stats=(AIC AICC BIC SBC)
    ;
run;

proc glm data=TestModel2;
    class region control locale;
    model GradRate = "Out-of-State COA 1k"n "White Students"n "Average Salary 1k"n region men control
                        "Total Room Capacity"n "Non-White Students"n women 'Total Students'n locale / solution;
run;

/* added a scaler on all variables to see if intercept could be improved */

proc standard data=TestModel2 mean=0 out=TestModel2STD;
    var "Out-of-State COA 1k"n "White Students"n "Average Salary 1k"n men "Total Room Capacity"n "Non-White Students"n women 'Total Students'n;
run;

proc glm data=TestModel2STD;
    class region control locale;
    model GradRate = "Out-of-State COA 1k"n "White Students"n "Average Salary 1k"n region men control
                        "Total Room Capacity"n "Non-White Students"n women 'Total Students'n locale / solution;
run;

/** Below is the Final Model Dataset used for the final Model Selection and GLM Fit */
/** Final Model below was done to scale up some components, as trying to interpret a model where (for ex) for every 1 White student is admitted was too small to have an effect */

proc sql;
    create table FinalModel as  
    select g.unitid, g.GradRate, g.Total/100 as 'Total Students 100'n, region, control, hloffer as "Highest Level of Degree Offered"n, locale, instcat, cbsatype, 
    AvgSalary as "Average Salary 1k"n, White/100 as "White Students 100"n, Nonwhite/100 as "Non-White Students 100"n,
            men/100 as men100, women/100 as women100, OStuitionFee/1000 as "Out-of-State COA 1k"n, roomcap/100 as "Total Room Capacity 100"n
    from GradRateuse as g inner join characteristicsuse as c on c.unitid = GradRateUse.unitid
    inner join salariesuse as s on s.unitid = GradRateUse.unitid
    inner join ExtendedUse as e on e.unitid = GradRateUse.unitid
    inner join tuitionuse3 as t on t.unitid = GradRateUse.unitid;
quit;

proc glmselect data=FinalModel;
    class region--cbsatype;
    model Gradrate = "Total Students 100"n--"Total Room Capacity 100"n/ selection=stepwise(select=SL select=cv) 
            slentry=0.05 slstay=0.05
    stats=(AIC AICC BIC SBC)
    ;
run; 

proc glm data=FinalModel;
    class region control locale;
    model GradRate = "Out-of-State COA 1k"n "White Students 100"n "Average Salary 1k"n region men100 control
                        "Total Room Capacity 100"n "Non-White Students 100"n women100 'Total Students 100'n locale / solution;
run;

/* added a scaler on all variables to see if intercept could be improved */

/** Below is the Final GLM model we agreed on and used to Interpret Results */

proc standard data=FinalModel mean=0 out=FinalModelSTD;
    var "Out-of-State COA 1k"n "White Students 100"n "Average Salary 1k"n men100 "Total Room Capacity 100"n "Non-White Students 100"n women100 'Total Students 100'n;
run;

ods graphics off;
proc glm data=finalmodelSTD;
    class region control locale;
    model GradRate = "Out-of-State COA 1k"n "White Students 100"n "Average Salary 1k"n region men100 control
                        "Total Room Capacity 100"n "Non-White Students 100"n women100 'Total Students 100'n locale / solution;
    lsmeans region / lines adjust=tukey;
    lsmeans control / lines adjust=tukey;
    lsmeans locale / lines adjust=tukey;
run;

