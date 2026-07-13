/* Derived from "Model Selection - Logistic.sas" in this repo.
   The external ipeds.salaries table is replaced by the sample tables
   built in autoexec.sas; the computed AvgSalary and Student_Staff_Ratio
   columns, the rank=7 filter, and the PROC LOGISTIC stepwise selection
   are the author's own. */

/** Salaries */
proc sql;
    create table salariesuse as
    select GradRateUse.*, sa09mct, sa09mot, (s.sa09mot/s.sa09mct)/1000 as AvgSalary, (GradRateUse.total/sa09mct) as Student_Staff_Ratio
    from GradRateUse inner join work.salaries as s on s.unitid = GradRateUse.unitid
    where s.rank eq 7
    ;
quit;

proc logistic data=salariesuse;
  model GradRate = sa09mct sa09mot AvgSalary Student_Staff_Ratio / selection=stepwise ;
run;
