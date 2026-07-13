/* Derived from "Model Selection - Logistic.sas" in this repo.
   The libname/format-catalog references to the external ipeds library are
   replaced by the sample Graduation table built inline below; the GRMed
   format definition, the Completers/Incoming self-join and the median
   cutoff of the response variable are the author's own. This script is
   self-contained so it can be posted directly to /v1/quick. */

/* Sample data standing in for the external `ipeds` library
   (libname ipeds '~/IPEDS/'). Mirrors the columns the author's PROC SQL
   reads from ipeds.Graduation: UnitId, the Completers/Incoming group, Total. */
data work.Graduation;
    length group $20;
    input UnitId group $ Total;
    datalines;
100001 Completers 320
100001 Incoming 640
100002 Completers 150
100002 Incoming 500
100003 Completers 90
100003 Incoming 210
100004 Completers 400
100004 Incoming 700
100005 Completers 60
100005 Incoming 180
100006 Completers 260
100006 Incoming 430
100007 Completers 350
100007 Incoming 590
100008 Completers 120
100008 Incoming 240
;
run;

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
    from work.Graduation(where=(group contains 'Completers')) as Grads
         inner join
         work.Graduation(where=(group contains 'Incoming')) as Cohort
      on Grads.UnitID eq Cohort.UnitID
      where cohort.Total ge 200;
        ;
quit;

proc sort data = Gradrates out = GradRateUse;
    by unitid;
run;

proc freq data=GradRateUse;
    table GradRate;
run;
