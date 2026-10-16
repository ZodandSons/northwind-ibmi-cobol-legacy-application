/*********************************************************************/
/* PROGRAM  : NWC620C                                                */
/* TITLE    : PRINT INVOICE - OVERRIDE PRINTER AND CALL NWC620       */
/* AUTHOR   : P. GONZALES                        DATE: 07/30/91      */
/* PARM     : ORDER NUMBER  *DEC (7 0)                               */
/* COPIED FROM NW620C - FORM TYPE AND SPOOL NAME ARE THE SAME, SO    */
/* DALLAS AND HOUSTON INVOICES LAND IN THE SAME OUTQ                 */
/*********************************************************************/
             PGM        PARM(&ORDER)
             DCL        VAR(&ORDER) TYPE(*DEC) LEN(7 0)

             OVRPRTF    FILE(QSYSPRT) PAGESIZE(66 132) LPI(6) CPI(10) +
                          FORMTYPE(INVOICE) SPLFNAME(NWINVOICE) +
                          HOLD(*YES) SHARE(*NO)
             CALL       PGM(NWC620) PARM(&ORDER)
             MONMSG     MSGID(CPF0000 CEE0000 LNR0000)
             DLTOVR     FILE(QSYSPRT)
             MONMSG     MSGID(CPF0000)
             ENDPGM
