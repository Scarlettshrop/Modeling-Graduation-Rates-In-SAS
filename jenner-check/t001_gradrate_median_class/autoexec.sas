/* cap input rows for the captured run */
options obs=100;

/* Sample data standing in for the external `ipeds` library that this
   script reads in the original project (libname ipeds '~/IPEDS/').
   Mirrors the columns the author's PROC SQL reads from ipeds.Graduation:
   UnitId, the Completers/Incoming group, and Total. */
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
