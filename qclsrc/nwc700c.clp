/*********************************************************************/
/* PROGRAM  : NWC700C                                                */
/* TITLE    : SUBMIT CUSTOMER LIST BY COUNTRY (COBOL) TO BATCH       */
/* AUTHOR   : P. GONZALES                        DATE: 08/19/91      */
/*********************************************************************/
             PGM
             SBMJOB     CMD(CALL PGM(NWLCBL/NWC700)) JOB(NWC700) +
                          JOBQ(QBATCH) INLLIBL(*CURRENT)
             MONMSG     MSGID(CPF0000)
             SNDPGMMSG  MSG('Customer list submitted to batch') +
                          MSGTYPE(*INFO)
             ENDPGM
