/* cap input rows for the captured run */
options obs=100;

/* Sample data standing in for the external `ipeds` library that this
   script reads in the original project (libname ipeds '~/IPEDS/').
   Mirrors the columns the author's PROC SQL/model reads: a state name
   (recoded to Region via the $Sta format), hloffer, and the GradRate
   response. Comma-delimited (DSD) so multi-word state names load whole. */
data work.CharSource;
    length StateName $20;
    infile datalines dsd;
    input unitid StateName $ hloffer GradRate;
    datalines;
100001,Texas,9,0.51
100002,California,7,0.62
100003,Florida,5,0.44
100004,New York,9,0.70
100005,Ohio,8,0.55
100006,Georgia,7,0.48
100007,Illinois,9,0.66
100008,Arizona,5,0.40
100009,Virginia,8,0.58
100010,Michigan,9,0.63
100011,Oregon,7,0.52
100012,Colorado,8,0.60
100013,Massachusetts,9,0.72
100014,Nevada,7,0.49
100015,Indiana,8,0.57
100016,Washington,9,0.65
;
run;
