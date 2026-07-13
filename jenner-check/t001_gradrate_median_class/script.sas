/* Derived from "Model Selection - Logistic.sas" in this repo.
   The libname/format-catalog references to the external ipeds library are
   replaced by the sample Graduation table built in autoexec.sas; the
   GRMed format definition, the Completers/Incoming self-join and the
   median cutoff of the response variable are the author's own. */

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
