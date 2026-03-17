libname ipeds '~/IPEDS/';
options fmtsearch=(IPEDS);

/** Created Format to do a cutoff of the Upper and Lower Median for Graduation Rate **/

proc format; 
    value GRMed
    0-0.532 = 'Lower Median'
    0.532-1 = 'Upper Median';
run;

/** Creation of Categorical Response Variable using the format above **/

proc sql;
  create table GradRates as 
    select 
        cohort.Total,
        grads.Total as Grads_Total,
        Grads.UnitId, 
        Grads.Total/Cohort.Total as GradRate format=8.3 format=GRMed.
    from ipeds.Graduation(where=(group contains 'Completers')) as Grads
         inner join
         ipeds.Graduation(where=(group contains 'Incoming')) as Cohort
      on Grads.UnitID eq Cohort.UnitID
      where cohort.Total ge 200;
        ;
quit;

proc sort data = Gradrates out = GradRateUse;
    by unitid;
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

proc logistic data=CharacteristicsUse;
class hloffer region--cbsatype;
  model GradRate = HLoffer region--cbsatype / selection=stepwise ;
run;

/** Salaries */

proc sql;
    create table salariesuse as
    select GradRateUse.*, sa09mct, sa09mot, (s.sa09mot/s.sa09mct)/1000 as AvgSalary, (total/sa09mct) as Student_Staff_Ratio
    from GradRateUse inner join ipeds.salaries as s on s.unitid = GradRateUse.unitid
    where s.rank eq 7
    ;
quit;

proc logistic data=salariesuse;
  model GradRate = sa09mct--Student_Staff_Ratio / selection=stepwise ;
run;


/** Graduation Extented */

proc sql;
    create table ExtendedUse as
    select GradRateUse.*, men, women, (graiant+grasiat+grbkaat+grhispt+grnhpit) as NonWhite, grwhitt as White
    from GradRateUse inner join ipeds.graduationextended as gra on gra.unitid = GradRateUse.unitid
    ;
quit;

proc logistic data=ExtendedUse;
  model GradRate = men--White / selection=stepwise ;
run;

/** Tuition and Costs */

proc sql;
    create table tuitionuse3 as
    select  GradRateUse.*, (tuition1+fee1+roomamt+boardamt) as DTuitionFee, (tuition2+fee2+roomamt+boardamt) as ISTuitionFee, (tuition3+fee3+roomamt+boardamt) as OStuitionFee, room, roomcap,
    scan(put(t.board,board.), 1, ',') as MealPlan
    from GradRateUse inner join ipeds.tuitionandcosts as t on t.unitid = GradRateUse.unitid
    where board gt 0
    ;
quit;

proc logistic data=tuitionuse3;
    class room mealplan ;
  model GradRate = DTuitionFee--MealPlan / selection=stepwise ;
run;

proc sql;
    create table FinalModel as  
    select g.unitid, g.GradRate, g.Total, region, control, hloffer, locale, instcat, AvgSalary, White, Nonwhite,
            men, women, istuitionfee, ostuitionfee, roomcap
    from GradRateuse as g inner join characteristicsuse as c on c.unitid = GradRateUse.unitid
    inner join salariesuse as s on s.unitid = GradRateUse.unitid
    inner join ExtendedUse as e on e.unitid = GradRateUse.unitid
    inner join tuitionuse3 as t on t.unitid = GradRateUse.unitid;
quit;

proc logistic data=FinalModel;
    where control ne 3;
    class region control hloffer locale instcat;
  model GradRate = Total--roomcap / selection=stepwise ;

run;

/** Final Model to Interpret with chosen predictor variables*/

ods graphics off;
proc logistic data=FinalModel;
  where control ne 3;
  class region control/ param=glm;
  model Gradrate = region control avgsalary men white ostuitionfee roomcap;
  lsmeans region / diff adjust=tukey exp lines;
  lsmeans control / diff adjust=tukey exp lines;
run;