/*********************************************************************/
/* PROGRAM  : NWC000C                                                */
/* TITLE    : NORTHWIND (DALLAS) MAIN MENU - COBOL SYSTEM            */
/* AUTHOR   : P. GONZALES                        DATE: 04/02/91      */
/*                                                                   */
/* MODIFICATION LOG                                                  */
/* 06/06/91 PG   COPIED FROM THE HOUSTON MENU NW000C                 */
/* 08/14/98 AW   OPTIONS 5-9 USE CODE TABLE PROGRAM NWC500           */
/* 05/05/04 AW   GLOBAL MONMSG - SAME AS HOUSTON                     */
/*                                                                   */
/* LIBRARIES ARE HARD CODED.  THE LDA IS NOT CLEARED BETWEEN OPTIONS */
/*********************************************************************/
             PGM
             DCLF       FILE(NWC000D)
             MONMSG     MSGID(CPF0000 LNR0000 LBE0000 CEE0000) EXEC(GOTO +
                          CMDLBL(ERROR))

             ADDLIBLE   LIB(NWLEGDTA)
             MONMSG     MSGID(CPF0000)
             ADDLIBLE   LIB(NWLCBL)
             MONMSG     MSGID(CPF0000)
             CHGVAR     VAR(&MMSG) VALUE(' ')

 LOOP:       SNDRCVF    RCDFMT(MENU)
             IF         COND(&IN03 *EQ '1') THEN(GOTO CMDLBL(END))
             CHGVAR     VAR(&MMSG) VALUE(' ')

             IF         COND(&MOPT *EQ 1) THEN(CALL PGM(NWC100))
             IF         COND(&MOPT *EQ 2) THEN(CALL PGM(NWC200))
             IF         COND(&MOPT *EQ 3) THEN(CALL PGM(NWC300))
             IF         COND(&MOPT *EQ 4) THEN(CALL PGM(NWC400))
             IF         COND(&MOPT *EQ 5) THEN(CALL PGM(NWC500) +
                          PARM('REG'))
             IF         COND(&MOPT *EQ 6) THEN(CALL PGM(NWC500) +
                          PARM('SHP'))
             IF         COND(&MOPT *EQ 7) THEN(CALL PGM(NWC500) +
                          PARM('CAT'))
             IF         COND(&MOPT *EQ 8) THEN(CALL PGM(NWC500) +
                          PARM('TER'))
             IF         COND(&MOPT *EQ 9) THEN(CALL PGM(NWC500) +
                          PARM('DEM'))
             IF         COND(&MOPT *EQ 10) THEN(CALL PGM(NWC600))
             IF         COND(&MOPT *EQ 11) THEN(CALL PGM(NWC610))
             IF         COND(&MOPT *EQ 12) THEN(CALL PGM(NWC700C))
             IF         COND(&MOPT *EQ 90) THEN(SIGNOFF)
             IF         COND(&MOPT *GT 12 *AND &MOPT *NE 90) +
                          THEN(CHGVAR VAR(&MMSG) VALUE('INVALID OPTION'))

             CHGVAR     VAR(&MOPT) VALUE(0)
             GOTO       CMDLBL(LOOP)

 ERROR:      CHGVAR     VAR(&MMSG) VALUE('PROGRAM ERROR - CALL DALLAS +
                          DATA PROCESSING X2210')
             CHGVAR     VAR(&MOPT) VALUE(0)
             GOTO       CMDLBL(LOOP)

 END:        RETURN
             ENDPGM
