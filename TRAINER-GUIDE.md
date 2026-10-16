# NWLCOBOL – Trainer guide (answer key)

This guide catalogs what was planted in the COBOL edition:
* legacy COBOL patterns
* architecture smells
* logic duplicated inside the COBOL code
* drift between the COBOL and RPG editions, which share one database
* latent bugs

References give the **program and paragraph** (and change marker). The
RPG-edition answer key (`nwlegacy/TRAINER-GUIDE.md`) covers the shared
database and the RPG side. The modern `northwind-ibmi` package is the "after"
picture.

---

## 1. The story the code tells

| Year | Who | What happened |
|---|---|---|
| 1991 | PG (P. Gonzales) | The Dallas division writes its own COBOL/400 system. NWC100 comes first; NWC200, NWC300 and NWC400 are cloned from it ("CLONED FROM NWC100/NWC300"). Order entry NWC600, inquiry NWC610, invoice NWC620 and the NWC700 report follow |
| 1995 | PG | "Moved to Northwind files" (marker PG95). Dallas drops its own files and uses Houston's DDS files. Copy members are hand-coded. Order numbers come from Houston's data area through a new CL program, NWCNXTC |
| 1997–98 | PG, AW | Supplier/product numbering becomes "highest on file + 1" (PG97). NWC500 replaces four code-table programs (AW98) |
| 1999–2000 | AW (A. Washington) | Y2K: `ACCEPT FROM DATE` stays 6-digit (AW99). Order dates become CYYMMDD with **window 50** (AW00). Houston used 40 |
| 2001–02 | AW | The DATEPRC copy member (AW01) is used by one program. Stock relief arrives, and the **order total now includes freight** (AW02) |
| 2004–08 | AW, RS | The LDA customer filter (AW04), territories (AW05), cancel puts stock back (RS06), logical delete (RS08). NWC520 is a copy of NWC510 |
| ~1999 | — | Moved to ILE COBOL (`CBLLE`), except NWC700, which stays OPM COBOL/400 |

---

## 2. Legacy COBOL patterns (where to find them)

| # | Pattern | Examples |
|---|---|---|
| C1 | `GO TO` loops and exits, `PERFORM … THRU …-EXIT`, `GO TO` out of a performed paragraph to the end of the program | every interactive program (`0100-SHOW-LIST`, `GO TO 9000-END-PGM` from NWC610 `5000-DISPLAY`) |
| C2 | Period-terminated `IF`s with no `END-IF`. `END-PERFORM`/`END-READ` appear in later patches only | everywhere; AW-era code mixes both styles |
| C3 | `77`-level work fields, one global WORKING-STORAGE, file status fields declared but never tested | all |
| C4 | **Hand-coded copy members** for every file ("LAYOUT MUST MATCH FILE … CHANGE BOTH TOGETHER"), because `COPY DDS` rejects `#` in names | `*CP` members |
| C5 | **A third copy of the customer layout**, typed inline with FILLERs | NWC700 `CUS-REC` |
| C6 | Workstation `TRANSACTION` files: `INDARA` with `PIC 1 INDICATOR` arrays, `B"1"` literals, separate `-I`/`-O` buffers kept in step with `MOVE CORRESPONDING` | NWC100 `7500-SHOW-DETAIL`, NWC600 `0100-HEADER` |
| C7 | Numbered indicators with program-wide meaning (31–38 subfile, 40/41 protect, 51+ field errors, 61–70 line errors) | all; NWC600 `3000` clears 61–70 one at a time |
| C8 | Ten numbered screen fields moved one by one (LPRD01…LPRD10) instead of an array | NWC600 `2100-SCREEN-TO-TABLE`, `2200-TABLE-TO-SCREEN` |
| C9 | `REDEFINES` tables built from `VALUE` strings (`"312831…"` days per month, message tables) and `SEARCH` | NWC200 `WS-MONTH-DAYS`, DATEPRC, NWC500 type table |
| C10 | `DIVIDE … GIVING … REMAINDER` date arithmetic, 6-digit `ACCEPT FROM DATE` | NWC610/NWC620 `7000-CYMD-TO-MDY`, all `ACCEPT WS-TODAY` |
| C11 | The LDA through `SPECIAL-NAMES LOCAL-DATA`, `ACCEPT`/`DISPLAY UPON` | NWC100 `8100-ORDERS`, NWC610 mainline |
| C12 | `CLASS` condition for validation; commented-out code with a dated note | NWC100 `PHONE-CHARS`; NWC300 `8000-EDIT` (fax check removed by PG in 1997) |
| C13 | OPM COBOL/400 `SORT` with INPUT/OUTPUT PROCEDURE sections, `RELEASE`/`RETURN`, a hand-made control break, `GO TO 2999-EXIT` to fall out of a section | NWC700 |
| C14 | Printer file with no DDS: print lines as `01` groups of FILLERs, a manual line counter (`> 55`), `AFTER ADVANCING PAGE` | NWC620, NWC700 |
| C15 | Change markers in columns 73–80 and modification logs | AW00, AW01, AW02, AW04, RS06, … |
| C16 | Magic literals: status `D O S C`, table types `"SHP" "CAT"`, limits 300/500/999, "CALL I.S." | throughout |
| C17 | OPM CL with hard-coded libraries, a global `MONMSG`, `SIGNOFF`, and a CL program used as a "subroutine" for data areas | NWC000C, NWCNXTC |

---

## 3. Architecture smells

* **Two applications, one database, no shared code.** Dallas (COBOL) and
  Houston (RPG) both update `NWLEGDTA`. Each has its own copy of every rule,
  so the data means different things depending on which screen wrote it
  (section 5).
* **Nothing is modular.** Each program does screen I/O, validation, pricing
  and file updates in one member. The only shared pieces are the copy members,
  one date paragraph, and a CL program for the next order number.
* **Copy members are a manual contract.** If someone adds a field to CUSMST
  with CHGPF, the 14 copybooks and NWC700's inline layout must all be changed
  by hand, and nothing fails at compile time.
* **Side channels:** the LDA (NWC100 → NWC610), the data area through a CL
  program (NWC600 → NWCNXTC), and dynamic `CALL` with positional parameters
  (NWC100 → NWC520, NWC200 → NWC510, NWC600 → NWC190, NWC490 and NWC620C).
* **No logical files where they would help.** NWC610 reads every order to
  filter one customer, and NWC700 sorts the whole customer file, because the
  composite-key LFs (ORDHDRL1, CUSMSTL2) were "too hard" from COBOL.
* **No integrity:** no commitment control, no journaling, no constraints, and
  locks held while the user thinks.

---

## 4. Duplicated logic inside the COBOL edition

| Logic | Copies | Drift |
|---|---|---|
| Work-with skeleton (load subfile, options, change/add/delete/display, move paragraphs, edit) | NWC100 → NWC200, NWC300 → NWC400 | NWC100 hides `STAT = "D"` customers; nothing else knows about logical delete. NWC300 still says "CUSTOMER NOT FOUND", "CUSTOMER ALREADY ON FILE" and "CUSTOMER NUMBER IS REQUIRED" |
| Select windows | NWC190, NWC490 | NWC190 offers deleted customers. NWC490 offers discontinued products |
| Link programs | NWC510 → NWC520 | NWC520 says "EMPLOYEE NOT ON FILE" about a customer |
| Date check | NWC200 `8700-DATE-CHECK` (MMDDYYYY, **February always 29**), DATEPRC `9500-CHECK-MDY` (MMDDYY, **February always 28**) | 02/29/2023 is a valid birth date. On 02/29/2028 order entry rejects its own default (today's) date |
| CYYMMDD → MMDDYY | NWC610 `7000`, NWC620 `7000` (comment: "COPIED FROM NWC610") | Identical today; nothing keeps them that way |
| MMDDYY → CYYMMDD | NWC600 `4500-MDY-TO-CYMD` | Window 50. The RPG edition uses 40 |
| Extended price | NWC600 `3100` (`PRC*QTY*(100-DSC)/100`, rounded, stored in ODEXT); NWC610 `5000` recomputes as `PRC*QTY*(1-DISC)`, rounded; NWC620 prints the stored ODEXT | Three places, two formulas. They can disagree on converted orders whose ODEXT came from the 1999 conversion |
| Next number | NWC300/NWC400 `4500` (read the whole file, highest + 1); NWC600 via NWCNXTC (data area, no lock); NWC200 (user types it) | Three strategies. NWC400 ignores data area NWNXTPRD, which Houston's NW400R uses |
| Re-read before rewrite | NWC100–400 `3000` ("EDIT MAY HAVE READ OTHER RECORDS"), NWC500 AW02 | Same lesson as Houston TPK04, learned separately |

---

## 5. COBOL ↔ RPG drift (shared-data problems)

These problems only appear because two applications write the same files. They
make good exercises for "find the business rule" with AI.

| # | Rule | Houston RPG | Dallas COBOL | Effect |
|---|---|---|---|---|
| D1 | **OHTOTL (order total)** | items only (NW600R) | items **+ freight** (NWC600 AW02) | Inquiry totals mean different things per order. **Both invoice programs add freight again**, so every order entered in Dallas is invoiced with freight counted twice (NWC620 `0500-TOTALS`, NW620R). |
| D2 | **Order number** | NWNXTORD read `*LOCK`, updated | NWCNXTC: `RTVDTAARA`/`CHGDTAARA`, **no lock** | If two entry screens save at the same moment, they get the same number. NWC600 then shows "ORDER NUMBER ALREADY USED - CALL I.S.", and the header write fails. The number is used up either way. |
| D3 | **Y2K window** | YY < 40 → 20YY | YY < 50 → 20YY | An order date typed as `..../45` is 1945 in Houston and 2045 in Dallas. |
| D4 | **Cancel** | status C, stock **not** returned | status C, stock **returned** (NWC610 RS06) | Inventory depends on which screen cancelled the order. Neither asks for confirmation. |
| D5 | **Product numbers** | data area NWNXTPRD | highest on file + 1 | After Dallas adds a product, Houston proposes a number that is already used. |
| D6 | **Who/when stamps** | `CMCHUS`/`OHENTU` = user profile | program name `"NWC100"` / `"NWC600"`; `OHENTD` = the *order* date typed, not today | Audit fields are useless for Dallas rows. |
| D7 | **Supplier home page** (80 bytes on file) | shown in 2 × 40 | screen field is **60** | Every change made in NWC300 cuts the last 20 characters off the stored home page: silent data loss on rewrite (`7100-SCREEN-TO-FILE`). |
| D8 | **Customer list** | CUSMSTL2 + RPG cycle; prints a status column | arrival sequence + SORT; **no status column** | Logically deleted customers appear in the Dallas report and are counted, with no way to tell them apart. |
| D9 | **Shared spool name** | NWINVOICE / FORMTYPE(INVOICE) | the same (NWC620C was copied) | The two divisions' invoices land in one hold queue, with nothing on them to say which division produced them. |

---

## 6. Latent bugs (bug-hunt answer key)

1. **Locks during think time.** NWC100–400 `3000-CHANGE` and `6000-DISPLAY`
   read the I-O file and then show the screen. F12 leaves the record locked
   until the next I/O. The add duplicate check locks the record it finds.
2. **NWC600 `3100-PRICE-ONE`** reads PRDMST, which is open I-O, for every
   line. The last product stays locked while the operator types.
3. **NWC610 locks as it lists.** It reads ORDHDR, which is opened I-O for the
   cancel, sequentially. Option 5 also reads PRDMST for update.
4. **No commitment control** in NWC600 `4000-WRITE-ORDER`: header, lines,
   then stock. `WRITE ORDDTL … INVALID KEY CONTINUE` ignores failed line writes.
5. **An order with freight and no items is accepted.** The "NO ITEMS ON THE
   ORDER" test runs after freight has been added to WS-TOTAL (NWC600
   `0200-LINES`), so a header with no lines is written.
6. **Stock goes negative.** There is no check, and discontinued products and
   deleted customers are accepted (NWC600 `2000`/`3100`).
7. **Stale ship-to.** It is defaulted only when blank; change the customer
   and the previous address stays (same as RPG).
8. **Stale LDA filter.** NWC100 option 8 sets the filter and nothing clears
   it, so menu option 11 opens filtered to the last customer viewed.
9. **Silent limits:** 500 customer, supplier and product rows; 300 employees
   and window rows; 999 orders (NWC610 does say so); 100 lines in the
   order-display subfile.
10. **Deletes:** customers are logical (status D) and are blocked as
    "ALREADY ON FILE" when re-added. Suppliers, products and employees are
    physical, with no where-used check. NWC200 leaves EMPNOT and EMPTER rows
    behind. NWC500 deletes with no confirmation.
11. **Employee notes.** NWC200 `8300-NOTES` shows the first 10 lines, deletes
    all of them, and writes back 10, losing any lines beyond 10.
12. **Leap years:** see section 4 (Feb 29 always valid in NWC200, never valid in DATEPRC).
13. **Century dropped on display.** `7000-CYMD-TO-MDY` keeps only YY.
14. **Error handling.** No file status is ever tested after `OPEN`. The CL
    menu's global `MONMSG` turns every crash into "PROGRAM ERROR - CALL DALLAS
    DATA PROCESSING".
15. **NWC620 when the order is not found** prints nothing and returns
    silently. For a missing customer it prints `*** CUSTOMER NOT ON FILE ***`
    on a real invoice.

---

## 7. Suggested exercises

1. **Explain** NWC600 with AI: paragraph call graph, indicator map, data
   dictionary from the copybooks. Then ask the AI to compare it with NW600R
   and list the business-rule differences. Score the result against section 5.
2. **Find the shared-data bugs.** Enter the same order in both editions,
   print both invoices, and explain the difference (D1). Then decide what
   OHTOTL *should* mean and write the data fix.
3. **Characterize, then refactor.** Capture invoice output and inquiry
   screens as tests, and replace `GO TO`/`PERFORM THRU` with structured
   `PERFORM`/`EVALUATE`/`END-IF` without changing the output.
4. **Kill the copybooks.** Generate layouts from the DDS (or move to SQL DDL
   and `SQL TYPE`/host structures). Make NWC700 use the shared layout.
5. **One rule, one place.** Extract the date, pricing, next-number and lookup
   logic into ILE procedures or service programs, callable from both COBOL
   and RPG. Make NWCNXTC safe (`*LOCK`, or a SQL sequence or identity column).
6. **OPM → ILE.** Convert NWC700 to ILE COBOL. Then replace the SORT with
   SQL `ORDER BY` or a keyed LF and compare.
7. **COBOL → RPG or Java/Python.** Use AI to translate NWC610 to free-form
   RPG and run both side by side to prove they behave the same, *including*
   the bugs, before fixing anything.
8. **Transactions and locking.** Journal the files, add commitment control to
   order entry, use read-without-lock for display, and optimistic
   re-read-and-compare for update.
9. **Bug hunt.** Hand out sections 5 and 6 as a scoring sheet afterwards.
