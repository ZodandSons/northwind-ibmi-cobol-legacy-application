/*********************************************************************/
/* PROGRAM  : NWCNXTC                                                */
/* TITLE    : GET NEXT ORDER NUMBER FROM DATA AREA NWNXTORD          */
/* AUTHOR   : A. WASHINGTON                      DATE: 09/30/95      */
/* PARM     : ORDER NUMBER  *DEC (7 0) - RETURNED                    */
/*                                                                   */
/* THE DATA AREA IS SHARED WITH THE HOUSTON RPG ORDER ENTRY NW600R.  */
/* NO *LOCK - TWO JOBS CAN GET THE SAME NUMBER.                      */
/*********************************************************************/
             PGM        PARM(&ORDER)
             DCL        VAR(&ORDER) TYPE(*DEC) LEN(7 0)

             RTVDTAARA  DTAARA(NWLEGDTA/NWNXTORD) RTNVAR(&ORDER)
             CHGVAR     VAR(&ORDER) VALUE(&ORDER + 1)
             CHGDTAARA  DTAARA(NWLEGDTA/NWNXTORD) VALUE(&ORDER)
             ENDPGM
