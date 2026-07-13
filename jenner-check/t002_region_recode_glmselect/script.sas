/* Derived from "Model Selection - Linear.sas" in this repo.
   The external ipeds.characteristics table is replaced by the sample
   CharSource table built in autoexec.sas; the $Sta state-to-region
   format, the HLOFFER CASE recode and the PROC GLMSELECT stepwise
   model selection are the author's own. */

/** Turned fips states into Regions */
proc format;
    value $Sta
    'Texas', 'Oklahoma', "Arkansas", 'Louisiana',
    "Mississippi",'Alabama','Georgia','Florida',
    'Tennessee',"South Carolina","North Carolina",
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

/** Simplify HLOFFER into degree tiers and assign each school a Region **/
proc sql;
    create table CharacteristicsUse as
    select
    case
          when hloffer ge 1 and hloffer < 7 then "Below Master's"
          when hloffer eq 7 then "Master's No Doctoral"
          when hloffer eq 8 then "Master's No Doctoral"
          when hloffer eq 9 then 'Doctoral'
        end as HLOffer,
        unitid, GradRate,
        put(StateName, $Sta.) as Region length=12
    from work.CharSource
    ;
quit;

proc freq data=CharacteristicsUse;
    table Region HLOffer;
run;

proc glmselect data=CharacteristicsUse;
    class HLoffer Region;
    model Gradrate = HLoffer Region / selection=stepwise(select=SL select=cv)
            slentry=0.05 slstay=0.05;
run;
