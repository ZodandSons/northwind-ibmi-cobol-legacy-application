       IDENTIFICATION DIVISION.
       PROGRAM-ID.    NWC700.
       AUTHOR.        P. GONZALES.
       INSTALLATION.  NORTHWIND TRADERS - DALLAS DIVISION.
       DATE-WRITTEN.  08/19/91.
      *****************************************************************
      *  CUSTOMER LIST BY COUNTRY  (COBOL/400 - OPM, CRTCBLPGM)
      *
      *  08/19/91 PG         NEW - RUNS IN BATCH FROM NWC700C
      *  09/30/95 PG   PG95  MOVED TO NORTHWIND FILE CUSMST
      *
      *  THE CUSTOMER LAYOUT IS CODED BELOW BY HAND (THIS PROGRAM IS
      *  OLDER THAN THE COPY MEMBERS).  IF CUSMST CHANGES, FIX IT HERE.
      *  THE FILE IS READ IN ARRIVAL SEQUENCE AND SORTED.
      *****************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-AS400.
       OBJECT-COMPUTER. IBM-AS400.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUSMST ASSIGN TO DATABASE-CUSMST
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-CUS-STAT.
           SELECT SORT-FILE ASSIGN TO DISK-SORTWK1.
           SELECT PRTFILE ASSIGN TO PRINTER-QSYSPRT.
       DATA DIVISION.
       FILE SECTION.
       FD  CUSMST
           LABEL RECORDS ARE STANDARD.
       01  CUS-REC.
           05  CUS-NO                  PIC X(5).
           05  CUS-NAME                PIC X(40).
           05  CUS-CONTACT             PIC X(30).
           05  FILLER                  PIC X(30).
           05  CUS-ADDRESS             PIC X(60).
           05  CUS-CITY                PIC X(15).
           05  FILLER                  PIC X(15).
           05  FILLER                  PIC X(10).
           05  CUS-COUNTRY             PIC X(15).
           05  CUS-PHONE               PIC X(24).
           05  FILLER                  PIC X(24).
           05  CUS-STATUS              PIC X(1).
           05  FILLER                  PIC X(22).
       SD  SORT-FILE.
       01  SORT-REC.
           05  SR-COUNTRY              PIC X(15).
           05  SR-CITY                 PIC X(15).
           05  SR-NAME                 PIC X(40).
           05  SR-NO                   PIC X(5).
           05  SR-CONTACT              PIC X(30).
           05  SR-PHONE                PIC X(24).
       FD  PRTFILE
           LABEL RECORDS ARE OMITTED.
       01  PRT-REC                     PIC X(132).
       WORKING-STORAGE SECTION.
       77  WS-CUS-STAT                 PIC XX    VALUE SPACES.
       77  WS-LINE-CNT                 PIC 99    VALUE 99.
       77  WS-PAGE                     PIC 999   VALUE ZERO.
       77  WS-CNTRY-CNT                PIC 9(5)  VALUE ZERO.
       77  WS-TOTAL-CNT                PIC 9(5)  VALUE ZERO.
       77  WS-PREV-COUNTRY             PIC X(15) VALUE HIGH-VALUES.
       77  WS-FIRST                    PIC X     VALUE "Y".
       01  WS-TODAY                    PIC 9(6)  VALUE ZERO.
       01  WS-TODAY-R REDEFINES WS-TODAY.
           05  WS-T-YY                 PIC 99.
           05  WS-T-MM                 PIC 99.
           05  WS-T-DD                 PIC 99.
       01  WS-MDY                      PIC 9(6)  VALUE ZERO.
       01  HD1.
           05  HD1-DATE                PIC 99/99/99.
           05  FILLER                  PIC X(12) VALUE SPACES.
           05  FILLER                  PIC X(30) VALUE
               "NORTHWIND TRADERS - DALLAS".
           05  FILLER                  PIC X(30) VALUE
               "CUSTOMER LIST BY COUNTRY".
           05  FILLER                  PIC X(5)  VALUE "PAGE".
           05  HD1-PAGE                PIC ZZ9.
       01  HD2.
           05  FILLER                  PIC X(7)  VALUE "CUST".
           05  FILLER                  PIC X(41) VALUE "COMPANY".
           05  FILLER                  PIC X(16) VALUE "CITY".
           05  FILLER                  PIC X(31) VALUE "CONTACT".
           05  FILLER                  PIC X(10) VALUE "PHONE".
       01  HD3.
           05  FILLER                  PIC X(9)  VALUE "COUNTRY: ".
           05  HD3-COUNTRY             PIC X(15).
       01  DL1.
           05  DL1-NO                  PIC X(5).
           05  FILLER                  PIC XX    VALUE SPACES.
           05  DL1-NAME                PIC X(40).
           05  FILLER                  PIC X     VALUE SPACE.
           05  DL1-CITY                PIC X(15).
           05  FILLER                  PIC X     VALUE SPACE.
           05  DL1-CONTACT             PIC X(30).
           05  FILLER                  PIC X     VALUE SPACE.
           05  DL1-PHONE               PIC X(24).
       01  TL1.
           05  FILLER                  PIC X(10) VALUE SPACES.
           05  FILLER                  PIC X(22) VALUE
               "CUSTOMERS IN COUNTRY".
           05  TL1-CNT                 PIC ZZ,ZZ9.
       01  TL2.
           05  FILLER                  PIC X(10) VALUE SPACES.
           05  FILLER                  PIC X(22) VALUE
               "TOTAL CUSTOMERS".
           05  TL2-CNT                 PIC ZZ,ZZ9.
       PROCEDURE DIVISION.
       0000-MAIN SECTION.
       0000-START.
           ACCEPT WS-TODAY FROM DATE.
           COMPUTE WS-MDY = WS-T-MM * 10000 + WS-T-DD * 100 + WS-T-YY.
           MOVE WS-MDY TO HD1-DATE.
           OPEN OUTPUT PRTFILE.
           SORT SORT-FILE
               ON ASCENDING KEY SR-COUNTRY SR-CITY SR-NAME
               INPUT PROCEDURE IS 1000-SELECT
               OUTPUT PROCEDURE IS 2000-PRINT.
           CLOSE PRTFILE.
           STOP RUN.
      *---------------------------------------------------------------
      *  1000 - INPUT PROCEDURE: EVERY RECORD ON THE FILE GOES IN.
      *         (STATUS D CUSTOMERS ARE NOT LEFT OUT)
      *---------------------------------------------------------------
       1000-SELECT SECTION.
       1000-START.
           OPEN INPUT CUSMST.
       1000-READ.
           READ CUSMST AT END GO TO 1000-END.
           MOVE CUS-COUNTRY TO SR-COUNTRY.
           MOVE CUS-CITY TO SR-CITY.
           MOVE CUS-NAME TO SR-NAME.
           MOVE CUS-NO TO SR-NO.
           MOVE CUS-CONTACT TO SR-CONTACT.
           MOVE CUS-PHONE TO SR-PHONE.
           RELEASE SORT-REC.
           GO TO 1000-READ.
       1000-END.
           CLOSE CUSMST.
       1000-EXIT.
           EXIT.
      *---------------------------------------------------------------
      *  2000 - OUTPUT PROCEDURE: PRINT WITH A BREAK ON COUNTRY
      *---------------------------------------------------------------
       2000-PRINT SECTION.
       2000-RETURN.
           RETURN SORT-FILE AT END GO TO 2000-END.
           IF SR-COUNTRY NOT = WS-PREV-COUNTRY
               PERFORM 2500-COUNTRY-BREAK THRU 2500-EXIT.
           IF WS-LINE-CNT > 55
               PERFORM 2700-HEADINGS THRU 2700-EXIT.
           MOVE SR-NO TO DL1-NO.
           MOVE SR-NAME TO DL1-NAME.
           MOVE SR-CITY TO DL1-CITY.
           MOVE SR-CONTACT TO DL1-CONTACT.
           MOVE SR-PHONE TO DL1-PHONE.
           WRITE PRT-REC FROM DL1 AFTER ADVANCING 1 LINE.
           ADD 1 TO WS-LINE-CNT.
           ADD 1 TO WS-CNTRY-CNT.
           ADD 1 TO WS-TOTAL-CNT.
           GO TO 2000-RETURN.
       2000-END.
           IF WS-FIRST = "N"
               MOVE WS-CNTRY-CNT TO TL1-CNT
               WRITE PRT-REC FROM TL1 AFTER ADVANCING 2 LINES.
           IF WS-LINE-CNT > 55
               PERFORM 2700-HEADINGS THRU 2700-EXIT.
           MOVE WS-TOTAL-CNT TO TL2-CNT.
           WRITE PRT-REC FROM TL2 AFTER ADVANCING 3 LINES.
           GO TO 2999-EXIT.
       2500-COUNTRY-BREAK.
           IF WS-FIRST = "N"
               MOVE WS-CNTRY-CNT TO TL1-CNT
               WRITE PRT-REC FROM TL1 AFTER ADVANCING 2 LINES
               ADD 2 TO WS-LINE-CNT.
           MOVE "N" TO WS-FIRST.
           MOVE ZERO TO WS-CNTRY-CNT.
           MOVE SR-COUNTRY TO WS-PREV-COUNTRY.
           IF WS-LINE-CNT > 50
               PERFORM 2700-HEADINGS THRU 2700-EXIT.
           MOVE SR-COUNTRY TO HD3-COUNTRY.
           WRITE PRT-REC FROM HD3 AFTER ADVANCING 2 LINES.
           ADD 2 TO WS-LINE-CNT.
       2500-EXIT.
           EXIT.
       2700-HEADINGS.
           ADD 1 TO WS-PAGE.
           MOVE WS-PAGE TO HD1-PAGE.
           WRITE PRT-REC FROM HD1 AFTER ADVANCING PAGE.
           WRITE PRT-REC FROM HD2 AFTER ADVANCING 2 LINES.
           MOVE 3 TO WS-LINE-CNT.
       2700-EXIT.
           EXIT.
       2999-EXIT.
           EXIT.
