/* cap input rows for the captured run */
options obs=100;

/* Sample data standing in for the external `ipeds` library that this
   script reads in the original project (libname ipeds '~/IPEDS/').
   `salaries` mirrors the columns the author's PROC SQL reads
   (unitid, rank, sa09mct staff count, sa09mot outlays); `GradRateUse`
   supplies the upper/lower-median GradRate response and cohort Total. */
data work.salaries;
    input unitid rank sa09mct sa09mot total;
    datalines;
100001 7 120 8400000 640
100002 7 80 5200000 500
100003 7 45 2700000 210
100004 7 160 12000000 700
100005 7 30 1650000 180
100006 7 95 6100000 420
100007 7 140 9800000 610
100008 7 55 3200000 260
100009 7 110 7300000 560
100010 7 70 4400000 350
100011 7 130 9100000 620
100012 7 60 3600000 300
100013 7 150 10800000 680
100014 7 40 2300000 200
100015 7 100 6700000 480
100016 7 85 5600000 390
100017 7 125 8900000 650
100018 7 50 3000000 240
;
run;

data work.GradRateUse;
    length GradRate $12;
    input unitid GradRate $ total;
    datalines;
100001 Upper 640
100002 Upper 500
100003 Lower 210
100004 Upper 700
100005 Lower 180
100006 Lower 420
100007 Upper 610
100008 Lower 260
100009 Upper 560
100010 Upper 350
100011 Lower 620
100012 Lower 300
100013 Upper 680
100014 Lower 200
100015 Upper 480
100016 Lower 390
100017 Upper 650
100018 Lower 240
;
run;
