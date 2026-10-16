# NWLCOBOL – Northwind Traders, the legacy way (COBOL edition)

This is the **COBOL edition** of the NWLEGACY modernization-training
application. The story is that Northwind's **Dallas division** had its own
COBOL team. In 1991 they wrote their own version of the Houston RPG system,
and in 1995 both systems were moved onto the same Northwind files. Since then
the two code bases have shared one database and drifted apart.

* **ILE COBOL** (`CBLLE`, compiled with `CRTBNDCBL`) for the interactive programs.
* One program that was never moved off **OPM COBOL/400** (`NWC700`, compiled with `CRTCBLPGM`): a batch report using `SORT` with INPUT and OUTPUT PROCEDURE sections.
* **No SQL, no procedures or service programs, no unit tests.**
* Native indexed I/O against the **same DDS files as the RPG edition** (library `NWLEGDTA`).
* Workstation `TRANSACTION` files with `INDARA` indicators, `COPY DDS-…` record layouts, `WRITE SUBFILE` and `READ SUBFILE … NEXT MODIFIED`.
* Hand-coded copybooks for every file, because `COPY DDS` can't handle the `#` in names like `OHORD#`.
* `PERFORM … THRU`, `GO TO`, period-terminated `IF`s, `77` levels, `REDEFINES` tables and `SEARCH`.
* The LDA through `LOCAL-DATA`, and data areas through a small CL program.
* Logic cloned from program to program, with drift inside the COBOL code and between the COBOL and RPG editions.
* **OPM CL** menu with hard-coded libraries and a global `MONMSG`.

> `TRAINER-GUIDE.md` is the answer key. It covers the patterns, the duplicated
> logic, the COBOL-versus-RPG drift and the latent bugs. Keep it away from
> trainees until after an exercise.

## Contents

| Object | Type | Purpose | RPG counterpart |
|---|---|---|---|
| NWC000C / NWC000D | CLP + DSPF | Main menu | NW000C |
| NWC100 / NWC100D | CBLLE + DSPF | Customers: logical delete, 8=Orders via the LDA, 9=Types | NW100R |
| NWC200 / NWC200D | CBLLE + DSPF | Employees: notes, 9=Territories, manager lookup | NW200R |
| NWC300 / NWC300D | CBLLE + DSPF | Suppliers, cloned from NWC100 | NW300R |
| NWC400 / NWC400D | CBLLE + DSPF | Products, cloned from NWC300; supplier and category lookups | NW400R |
| NWC500 / NWC500D | CBLLE + DSPF | One program for five code tables (REG SHP CAT TER DEM) | NW500R |
| NWC510 / NWC510D | CBLLE + DSPF | Employee territories (called from NWC200) | NW510R |
| NWC520 / NWC520D | CBLLE + DSPF | Customer demographic types, a copy of NWC510 | NW520R |
| NWC190 / NWC490 | CBLLE + DSPF | F4 select windows for customers and products (clones) | NW190R / NW490R |
| NWC600 / NWC600D | CBLLE + DSPF | Order entry: 10 fixed lines, no commit | NW600R |
| NWC610 / NWC610D | CBLLE + DSPF | Order inquiry: 4=Cancel, 5=Display, 6=Print | NW610R |
| NWC620C / NWC620 | CLP + CBLLE | Invoice: OVRPRTF wrapper and a printer-file program | NW620C / NW620R |
| NWC700C / NWC700 | CLP + OPM CBL | Customer list by country: SBMJOB, then SORT with a control break | NW700C / NW700R |
| NWCNXTC | CLP | Next order number from data area NWNXTORD | logic inside NW600R |
| xxxxxxCP | copy members | Record layouts for the 10 PFs and 4 LFs | — |
| DATEPRC | copy member | MMDDYY date check paragraph (used by NWC600 only) | DATCHK |

Database (library **NWLEGDTA**):

| File | Contents |
|---|---|
| CUSMST | Customers |
| EMPMST | Employees |
| EMPNOT | Employee notes, in 60-character lines |
| SUPMST | Suppliers |
| PRDMST | Products |
| CODTBL | Regions, shippers, categories, territories and customer types |
| EMPTER | Employee territories |
| CUSDEM | Customer demographic types |
| ORDHDR | Order headers |
| ORDDTL | Order lines |

* Logical files: CUSMSTL1/L2, EMPMSTL1/L2, SUPMSTL1, PRDMSTL1, ORDHDRL1.
* Data areas: NWNXTORD (next order number), NWNXTPRD (next product number), NWCOMP (company name).

## Folder layout

```
qcbllesrc/ *.cblle     ILE COBOL programs + copy members (xxxCP, DATEPRC)
qcblsrc/   nwc700.cbl  OPM COBOL/400
qddssrc/   *.pf *.lf *.dspf       display files (INDARA)
qclsrc/    *.clp       OPM CL
qsqlsrc/   nwlconv.sql           one-time data conversion  (setup only)
setup/     nwcbuild.clle   build program (setup only)
```

There are no PF or LF members here. The COBOL edition uses the RPG edition's
database.

## Set up

1. **Build the RPG edition first** (`nwlegacy` package, `NWLBUILD`). That
   creates and loads library `NWLEGDTA`, and `NWCBUILD` stops if it is missing.
2. Copy this folder into the IFS **root** file system, for example
   `/home/me/nwlcobol`. The root file system ignores case, and the build
   depends on that.
3. Build:
   ```
   CRTLIB NWLCBL
   CRTSRCPF NWLCBL/QCLSRC RCDLEN(92)
   CPYFRMSTMF FROMSTMF('/home/me/nwlcobol/setup/nwcbuild.clle') +
              TOMBR('/QSYS.LIB/NWLCBL.LIB/QCLSRC.FILE/NWCBUILD.MBR') MBROPT(*REPLACE)
   CRTBNDCL NWLCBL/NWCBUILD SRCFILE(NWLCBL/QCLSRC)
   CALL NWLCBL/NWCBUILD PARM(('/home/me/nwlcobol' (*CHAR 128)))
   ```
   `NWCBUILD` creates the source files and copies the members into them. It
   then compiles the display files first, because the COBOL needs them for
   `COPY DDS`, followed by the ILE COBOL, the OPM COBOL and the CL. Copy
   members are not compiled. At the end it reports how many steps failed.
4. Run `CALL NWLCBL/NWC000C`. Both editions can run at the same time against
   the same data, and several of the exercises depend on doing that.

## Compiler notes and assumptions

No IBM i system was available while this package was built, so nothing has
been compiled. The sources were checked by script for:
* column rules: column 7, Area A/B, nothing past column 72
* every `field OF format-I/-O` against the display-file DDS, including input/output usage
* every data name, paragraph and `GO TO`/`PERFORM` target resolving
* copybook layouts against the PF/LF DDS
* overlapping screen fields

A separate review pass also read the sources. Points most likely to need
attention on a real system:

* **Copy-member library.** `COPY CUSMSTCP.` (no `OF`) is expected to resolve
  to `QCBLLESRC` in the library list, which is the ILE COBOL default. If your
  release defaults elsewhere, add `OF QCBLLESRC`.
* **`COPY DDS-fmt-I/-O OF dspf`.** This needs the display file in the library
  list at compile time; `NWCBUILD` adds `NWLCBL`.
* **Sort work file in NWC700.** It is coded `ASSIGN TO DISK-SORTWK1`. COBOL/400
  only uses the device part of the name.
* **LDA.** The LDA is read and written with `SPECIAL-NAMES. LOCAL-DATA IS
  LDA-NAME` and `ACCEPT`/`DISPLAY … UPON`.
* **Activation group.** `CRTBNDCBL` uses its default activation group. Calls
  are plain dynamic `CALL "PGM"` program calls.
* **Source files.** All source files use `RCDLEN(92)`, which gives 80 columns
  of source: COBOL sequence area 1–6, change markers in 73–80.
