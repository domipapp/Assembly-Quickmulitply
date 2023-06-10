; -----------------------------------------------------------
; Mikrokontroller alapú rendszerek házi feladat
; Készítette: Papp Domink
; Neptun code: EAT3D9
; Feladat leírása:
;		Belsõ memóriában lévõ 16 bites elõjeles szám "gyorsszorzása"
;		10 hatványa szorzóval (1, 10, 100, 1000, 10000), a 10 kitevõje
;		az egyik bemenõ paramétere a rutinnak (0..4).
,		Bemenet: szorzandó címe R0(mutató), továbbiakban operandus,
;		szorzó kitevõje R2(érték), eredmény címe R1(mutató).
;		Kimenet: 16 bites eredmény R1 által mutatott címen,
;		OV, PSW regiszterben az OV bit mutatja, van-e overflow
; -----------------------------------------------------------

$NOMOD51 ; a sztenderd 8051 regiszter definíciók nem szükségesek

$INCLUDE (SI_EFM8BB3_Defs.inc) ; regiszter és SFR definíciók

; Ugrótábl létrehozása
	CSEG AT 0
	SJMP Main

myprog SEGMENT CODE			;saját kódszegmens létrehozása
RSEG myprog 				;saját kódszegmens létrehozása
; ------------------------------------------------------------
; Fõprogram
; ------------------------------------------------------------
; Feladata: a szükséges inicializálás lépések elvégzése, bemenetek
;			megadása és a feladatot megvalóító szubrutin hívása
; ------------------------------------------------------------
Main:
	CLR IE_EA ; interruptok tiltása watchdog tiltás idejére
	MOV WDTCN,#0DEh ; watchdog timer tiltása
	MOV WDTCN,#0ADh
	SETB IE_EA ; interruptok engedélyezése

	; paraméterek elõkészítése a szubrutin híváshoz
	MOV R0, #0x30	;operandus címe
	MOV R1, #0x32	;kimenet címe
	MOV R2, #0x04	;10 hatványa

	MOV @R0, #0xF6 	;operandus LSB értéke
	INC R0			;következõ címen az MSB
	MOV @R0, #0xFF	;operandus MSB értéke
	DEC R0			;visszaállítjuk LSB-re
	MOV R7, #0		;PSW-t orolja, mutatja, hogy volt-e overflow

	CALL QuickMultiply ;gyorsszoró szubrutin hívása
	JMP $ ; végtelen ciklusban várunk



; -----------------------------------------------------------
; QuickMultiply szubrutin
; -----------------------------------------------------------
; Funkció: 		16 bites szám gyorsszorzása 10 hatványával
; Bementek:		R0 - operandus címe
;			 	R1 - kimenet, eredmény címe
;				R2 - 10 kitevõje 0...4
; Kimenetek:  	R2 - kimenet, eredmény címe
; Regisztereket módosítja:
;				R3, R4, R6, R7
; -----------------------------------------------------------
QuickMultiply:
	;kimenet nullázása, hozzá fogjuk adogatni a részereményeket
	MOV @R1, #0x00	;kimeneti LSB nullázása
	INC R1			;következõ byte
	MOV @R1, #0x00	;kimeneti MSB nullázása
	DEC R1			;eredeti címre visszaállítás

	;operandus értékének betöltése memóriából és kettes komplementelés
	MOV A, @R0	;operandus LSB-jét betöltjü
	MOV R3, A
 	INC R0		;operandus MSB-jére állítjuk a pointerünket
	MOV A, @R0	;operandus MSB-jét betöltjük
	MOV R4, A
	DEC R0		;visszaállítjuk a pointert az LSB-re
	;megnézzük, hogy az operandus negatív szám-e
	MOV A, R4	;operandus MSB betöltjük
	ANL A, #0x80;maszkolunk, hogy csak a legnagyobb bit lehessen nem 0
	JZ Switch	;ugrunk, ha a legnagyobb bit 0, azaz pozitív szám
	CALL Complement2	;a legnagyobb bit 1-es, kettes komplemenseljük


Switch:
	CJNE R2, #0x04, NotFour	;ugrik, ha R2 értéke nem 4
	;R2 értéke 4
	;10000 = 16 + 256 + 512 + 1024 + 8192
	;szorzás 16al
	MOV R6, #0x04
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 256al
	MOV R6, #0x04
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 512vel
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 1024el
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 8192vel
	MOV R6, #0x03
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása
	JMP CheckIfNeg

NotFour:
	CJNE R2, #0x03, NotThree;ugrik, ha R2 értéke nem 3
	;R2 értéke 3
	;1000 = 8 + 32 + 64 + 128 + 256 + 512
	;szorzás 8al
	MOV R6, #0x03
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 32vel
	MOV R6, #0x02
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 64-el
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 128al
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 256al
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 512vel
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	JMP CheckIfNeg
NotThree:
	CJNE R2, #0x02, NotTwo	;ugrik, ha R2 értéke nem 2
	;R2 értéke 2
	;100 = 4 + 32 + 64
	;szorzás 4el
	MOV R6, #0x02
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 32vel
	MOV R6, #0x03
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	;szorzás 64vel
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása

	JMP CheckIfNeg
NotTwo:
	CJNE R2, #0x01, IsZero	;ugrik, ha R2 értéke nem 1
	;R2 értéke 1
	;10 = 2 + 8
	;szorzás 2vel
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredmény hozzáadása
	;szorzás 8al
	MOV R6, #0x02
	CALL ShiftLeftR6Times
	CALL Add2Mem;	;eredmény hozzáadása

	JMP CheckIfNeg

IsZero:;R2 értéke 0
	CALL Add2Mem

CheckIfNeg:
	;megnézzük, hogy az operandus negatív szám volt-e
	INC R0		;MSB-re állítjuk a pointert
	MOV A, @R0	;operandus MSB betöltjük
	DEC R0		;LSB-re visszállítjuk a pointert
	ANL A, #0x80;maszkolunk, hogy csak a legnagyobb bit lehessen nem 0
	JZ OvCheck	;ugrunk, ha a legnagyobb bit 0, azaz pozitív szám
	;az elmentett eredményt kettes komplemenselni kell
	;betöltjük az eredményt R3(LSB) és R4(MSB) regiszterekbe
	MOV A, @R1	;eredmény LSB-jét betöltjük
	MOV R3, A
 	INC R1		;eredmény MSB-jére állítjuk a pointerünket
	MOV A, @R1	;eredmény MSB-jét betöltjük
	MOV R4, A
	DEC R1		;visszaállítjuk a pointert az LSB-re
	CALL Complement2	;a legnagyobb bit 1-es, kettes komplemenseljük
	;lenullázzuk a memóriában lévõ eredményt
	MOV @R1, #0x00	;kimeneti LSB nullázása
	INC R1			;következõ byte
	MOV @R1, #0x00	;kimeneti MSB nullázása
	DEC R1			;eredeti címre visszaállítás
	CALL Add2Mem	;memóriába betültjük a kettes komplemenselt eredményt


OvCheck:
	;megnézzük, történt-e túlcsordulás
	INC R0	;MSB-re állítjuk a pointert
	INC R1	;MSB-re állítjuk a pointert
	;ha változott a 15. bit akkor volt túlcsordulás
	MOV	A, @R0	;operandus MSB betoltése
	XRL A, @R1	;eredmény MSB-t xor-oljuk az operandus MSB-vel
	ANL A, #0x80;maszkolunk, hogy csak a legnagyobb bit lehessen nem 0
	JNZ Overflow;ha az elsõ bit egyes, azaz változás történt, akkor overflow van
	;ha van carry az R7ben akkor overflow
	MOV A, R7	;mindenkori PSW betöltjük
	ANL A, #0x80;maszkolunk, hogy csak a legnagyobb bit lehessen nem 0
	JNZ Overflow;ha az elsõ bit egyes, azaz változás történt, akkor overflow van
	RET

OverFlow:
	MOV PSW, #0x04	;beállítjuk a PSW-ben az overflow bitet
	RET



; -----------------------------------------------------------
; ShiftLeftR6Times szubrutin
; -----------------------------------------------------------
; Funkció: 		R3 és R4 tartalmát balra shifteli 1-el,
;				R3 tartalma beleshiftelõdik R4-be, R6-ban
;				meghatározott értékszer
; Bementek:		R3 - LSB
;			 	R4 - MSB
;				R6 - ennyiszer kell balra shiftelni
; Kimenetek:  	R3 - LSB
;			 	R4 - MSB
; Regisztereket módosítja:
;				R3, R4, R6
; -----------------------------------------------------------
ShiftLeftR6Times:
	CLR C		;CY törlése, hogy ne zavarjon be
	MOV A,R3	;LSB betöltése
	RLC A		;LSB balra forgatása, végére 0 kerül
	MOV R3,A	;elforgatott LSB kimentése
	MOV A,R4	;MSB betöltése
	RLC A		;MSB balra forgatása, végére LSB legnagyobb bitje kerül
	MOV R4,A	;elforgatott MSB kimentése
	CALL SaveOV;elmentjük, hogy történt-e CY, mert ha igen, az túlcsordulás
	DJNZ R6, ShiftLeftR6Times;csökkenti R6 értékét és shiftel, ha nem nulla
	RET



; -----------------------------------------------------------
; Add2Mem szubrutin
; -----------------------------------------------------------
; Funkció: 		R1 által mutatott címen lévõ 16 bites értékhez
;				hozzáadja R3(LSB) és R4(MSB) értékét
; Bementek:		R1 - mutató
;				R3 - LSB
;			 	R4 - MSB
; Kimenetek:  	R1 - mutatón lévõ érték
; Regisztereket módosítja:
;
; -----------------------------------------------------------
Add2Mem:
	CLR C     	;CY törlése, hogy ne zavarjon be
	MOV A,R3	;LSB betöltése
	ADD A,@R1	;memória LSB-jéhez R3 LSB hozzáadása
	MOV @R1,A  	;az összeget eltárolja a memóriában lévõ LSB-n
	INC R1		;memória MSB-re állítjuk a pointert
	MOV A,R4	;MSB betöltése
	ADDC A,@R1	;memória MSB-jéhez R4 MSB hozzáadása
	MOV @R1,A 	;az összeget eltárolja a memóriában lévõ MSB-n
	DEC R1		;visszaállítjuk a pointert a memória LSB-re
	RET



; -----------------------------------------------------------
; SaveOV szubrutin
; -----------------------------------------------------------
; Funkció: 		R7-be elmenti a PSW aktuális állapotát úgy,
;				hogy minden korábbi változata is jelen van
;				olyan formában, hogy az 1-eseket megõrzi
; Bementek:		R7 - PSW tároló regiszter
; Kimenetek:  	R7 - PWS tároló regiszter
; Regisztereket módosítja:
;				R7
; -----------------------------------------------------------
SaveOV:
	MOV A, PSW	;PSW betöltése
	ORL A, R7	;PSW-hez hozzá vagyolja R7-et, mindkettõ 1-esei A-ban
	MOV R7, A	;(PSW OR R7) kimentése R7-be
	RET



; -----------------------------------------------------------
; Complement2 szubrutin
; -----------------------------------------------------------
; Funkció: 		R3(LSB) és R4(MSB) 16 bites számot kettes
;				komplemenseli
; Bementek:		R3 - LSB
;				R4 - MSB
; Kimenetek:  	R3 - LSB
;				R4 - MSB
; Regisztereket módosítja:
;				R3, R4
; -----------------------------------------------------------
Complement2:
	CLR C		;töröljük a CY-t, nehogy bezavarjon
	MOV A, R3	;operandus LSB-jét betöltjük
	CPL A		;operandus LSB-jét komplementáljuk
	ADD A, #0x01;operandus LSB-jéhez hozzáadunk 1-et
	MOV R3, A	;R3 operandus LSB értéke
	MOV A, R4	;operandus MSB-jét betöltjük
	CPL A		;operandus MSB-jét komplementáljuk
	ADDC A,#0x00;operandus MSB-jéhez hozzáadjuk az LSB növelésébõl származó maradékot
	MOV R4, A	;R4 operandus MSB értéke
	RET



END
