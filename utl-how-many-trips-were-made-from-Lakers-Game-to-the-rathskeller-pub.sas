%let pgm=utl-how-many-trips-were-made-from-Lakers-Game-to-the-rathskeller-pub;

How many trips were made from Lakers Game to the rathskeller pub

github
https://tinyurl.com/2ufup6j2
https://github.com/rogerjdeangelis/utl-how-many-trips-were-made-from-Lakers-Game-to-the-rathskeller-pub

stackoverflow R
https://tinyurl.com/4pjb86wa
https://stackoverflow.com/questions/76254138/transactional-data-to-from-to-table

options validvarname=upcase;
data have ;informat
fan 8.
loc $1.
;input
FAN  LOC;
cards4;
1 A
1 B
1 C
2 A
2 C
2 A
2 A
3 A
3 B
3 C
3 D
;;;;
run;quit;

/***************************************************************************************************************************/
/*                                                                                                                         */
/*  Up to 40 obs from HAVE with      | RULES (Think sequential leads - merge have have(firstobs=2)                         */
/*                                   |                                                                                     */
/*  Obs      FAN   LOC               | Consider A as the Lakers Game(A)  and B as Rathskeller Pub.                         */
/*                                   | How many trips are there from A to B (in that order no intermediate stops)          */
/*    1       1     A  |             |                                                                                     */
/*    2       1     B  | A to B      | FAN 1 travels from A to B                                                           */
/*    3       1     C                | FAN 3 travels from A to B                                                           */
/*    4       2     A                |                                                                                     */
/*    5       2     C                | SO we have                                                                          */
/*    6       2     A                |                                                                                     */
/*    7       2     A                | FRO     TOO    CNT                                                                  */
/*    8       3     A  |             |                                                                                     */
/*    9       3     B  | A to B      |  A      B       2                                                                   */
/*   10       3     C                |                                                                                     */
/*   11       3     D                |                                                                                     */
/*                                   |                                                                                     */
/***************************************************************************************************************************/
/*                      __ _          _        _              ____
/ |    ___  __ _ ___   / _(_)_ __ ___| |_ ___ | |__  ___ ____|___ \
| |   / __|/ _` / __| | |_| | `__/ __| __/ _ \| `_ \/ __|_____|__) |
| |_  \__ \ (_| \__ \ |  _| | |  \__ \ || (_) | |_) \__ \_____/ __/
|_(_) |___/\__,_|___/ |_| |_|_|  |___/\__\___/|_.__/|___/    |_____|

*/
data havNxt(drop=fanToo);
 merge have(rename=loc=fro ) have(firstobs=2 rename=(fan=fanToo loc=too));
 if fan < fanToo or too="" then delete;
run;quit;

proc freq data=havNxt;
 tables fro*too /list out=want(drop=percent);
run;quit;

/**************************************************************************************************************************/
/*                                                                                                                        */
/* The WPS System                                                                                                         */
/*                                                                                                                        */
/* Obs    FRO    TOO    COUNT                                                                                             */
/*                                                                                                                        */
/*  1      A      A       1                                                                                               */
/*  2      A      B       2  Two A to Twice                                                                               */
/*  3      A      C       1                                                                                               */
/*  4      B      C       2                                                                                               */
/*  5      C      A       1                                                                                               */
/*  6      C      D       1                                                                                               */
/*                                                                                                                        */
/**************************************************************************************************************************/
/*___                            __ _          _        _              ____
|___ \    __      ___ __  ___   / _(_)_ __ ___| |_ ___ | |__  ___ ____|___ \
  __) |   \ \ /\ / / `_ \/ __| | |_| | `__/ __| __/ _ \| `_ \/ __|_____|__) |
 / __/ _   \ V  V /| |_) \__ \ |  _| | |  \__ \ || (_) | |_) \__ \_____/ __/
|_____(_)   \_/\_/ | .__/|___/ |_| |_|_|  |___/\__\___/|_.__/|___/    |_____|
                   |_|
*/

%let _pth=%sysfunc(pathname(work));

%utl_submit_wps64('

libname wrk "&_pth";

data havNxt(drop=fanToo);
 merge wrk.have(rename=loc=fro ) wrk.have(firstobs=2 rename=(fan=fanToo loc=too));
 if fan < fanToo or too="" then delete;
run;quit;

proc freq data=havNxt;
 tables fro*too /list out=want(drop=percent);
run;quit;

proc print data=want;
run;quit;
');

/**************************************************************************************************************************/
/*                                                                                                                        */
/* The WPS System                                                                                                         */
/*                                                                                                                        */
/* Obs    FRO    TOO    COUNT                                                                                             */
/*                                                                                                                        */
/*  1      A      A       1                                                                                               */
/*  2      A      B       2  Two A to B                                                                                   */
/*  3      A      C       1                                                                                               */
/*  4      B      C       2                                                                                               */
/*  5      C      A       1                                                                                               */
/*  6      C      D       1                                                                                               */
/*                                                                                                                        */
/**************************************************************************************************************************/

/*____
|___ /   __      ___ __  ___   _ __  _ __ ___   ___   _ __
  |_ \   \ \ /\ / / `_ \/ __| | `_ \| `__/ _ \ / __| | `__|
 ___) |   \ V  V /| |_) \__ \ | |_) | | | (_) | (__  | |
|____(_)   \_/\_/ | .__/|___/ | .__/|_|  \___/ \___| |_|
                  |_|         |_|
*/

proc datasets lib=work nodetails nolist;
 delete want_r want_dr;
run;quit;


%let _pth=%sysfunc(pathname(work));

%utl_submit_wps64('

libname wrk "&_pth";

proc r;
export data=wrk.have r=have;
submit;
library(dplyr);
library(data.table);

want_r<-have |>
  mutate(from = LOC, too = lead(LOC), .by=FAN) |>
  filter(!is.na(too)) |>
  summarise(value=n(),.by=c(from,too));

want_dr<-as.data.table(have)[,.(from = LOC, too = lead(LOC))
    ,by=FAN][!is.na(too),.(value=.N), by=.(from,too)];

endsubmit;
import data=wrk.want_r r=want_r;
import data=wrk.want_dr r=want_dr;
run;quit;
');

proc print data=want_r;
title "WPS R lead";
run;quit;

proc print data=want_dr;
title "WPS R data.table";
run;quit;

 /**************************************************************************************************************************/
 /*                                                                                                                        */
 /* WPS R lead                  |  WPS R data.table                                                                        */
 /*                             |                                                                                          */
 /* Obs    FROM    TOO    VALUE |  Obs    FROM    TOO    VALUE                                                             */
 /*                             |                                                                                          */
 /*  1      A       B       2   |   1      A       B       2                                                               */
 /*  2      B       C       2   |   2      B       C       2                                                               */
 /*  3      A       C       1   |   3      A       C       1                                                               */
 /*  4      C       A       1   |   4      C       A       1                                                               */
 /*  5      A       A       1   |   5      A       A       1                                                               */
 /*  6      C       D       1   |   6      C       D       1                                                               */
 /*                                                                                                                        */
 /**************************************************************************************************************************/

/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|

*/
