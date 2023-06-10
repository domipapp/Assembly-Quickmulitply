; -----------------------------------------------------------
; Mikrokontroller alap� rendszerek h�zi feladat
; K�sz�tette: Papp Domink
; Neptun code: EAT3D9
; Feladat le�r�sa:
;		Bels� mem�ri�ban l�v� 16 bites el�jeles sz�m "gyorsszorz�sa"
;		10 hatv�nya szorz�val (1, 10, 100, 1000, 10000), a 10 kitev�je
;		az egyik bemen� param�tere a rutinnak (0..4).
,		Bemenet: szorzand� c�me R0(mutat�), tov�bbiakban operandus,
;		szorz� kitev�je R2(�rt�k), eredm�ny c�me R1(mutat�).
;		Kimenet: 16 bites eredm�ny R1 �ltal mutatott c�men,
;		OV, PSW regiszterben az OV bit mutatja, van-e overflow
; -----------------------------------------------------------

$NOMOD51 ; a sztenderd 8051 regiszter defin�ci�k nem sz�ks�gesek

$INCLUDE (SI_EFM8BB3_Defs.inc) ; regiszter �s SFR defin�ci�k

; Ugr�t�bl l�trehoz�sa
	CSEG AT 0
	SJMP Main

myprog SEGMENT CODE			;saj�t k�dszegmens l�trehoz�sa
RSEG myprog 				;saj�t k�dszegmens l�trehoz�sa
; ------------------------------------------------------------
; F�program
; ------------------------------------------------------------
; Feladata: a sz�ks�ges inicializ�l�s l�p�sek elv�gz�se, bemenetek
;			megad�sa �s a feladatot megval��t� szubrutin h�v�sa
; ------------------------------------------------------------
Main:
	CLR IE_EA ; interruptok tilt�sa watchdog tilt�s idej�re
	MOV WDTCN,#0DEh ; watchdog timer tilt�sa
	MOV WDTCN,#0ADh
	SETB IE_EA ; interruptok enged�lyez�se

	; param�terek el�k�sz�t�se a szubrutin h�v�shoz
	MOV R0, #0x30	;operandus c�me
	MOV R1, #0x32	;kimenet c�me
	MOV R2, #0x04	;10 hatv�nya

	MOV @R0, #0xF6 	;operandus LSB �rt�ke
	INC R0			;k�vetkez� c�men az MSB
	MOV @R0, #0xFF	;operandus MSB �rt�ke
	DEC R0			;vissza�ll�tjuk LSB-re
	MOV R7, #0		;PSW-t orolja, mutatja, hogy volt-e overflow

	CALL QuickMultiply ;gyorsszor� szubrutin h�v�sa
	JMP $ ; v�gtelen ciklusban v�runk



; -----------------------------------------------------------
; QuickMultiply szubrutin
; -----------------------------------------------------------
; Funkci�: 		16 bites sz�m gyorsszorz�sa 10 hatv�ny�val
; Bementek:		R0 - operandus c�me
;			 	R1 - kimenet, eredm�ny c�me
;				R2 - 10 kitev�je 0...4
; Kimenetek:  	R2 - kimenet, eredm�ny c�me
; Regisztereket m�dos�tja:
;				R3, R4, R6, R7
; -----------------------------------------------------------
QuickMultiply:
	;kimenet null�z�sa, hozz� fogjuk adogatni a r�szerem�nyeket
	MOV @R1, #0x00	;kimeneti LSB null�z�sa
	INC R1			;k�vetkez� byte
	MOV @R1, #0x00	;kimeneti MSB null�z�sa
	DEC R1			;eredeti c�mre vissza�ll�t�s

	;operandus �rt�k�nek bet�lt�se mem�ri�b�l �s kettes komplementel�s
	MOV A, @R0	;operandus LSB-j�t bet�ltj�
	MOV R3, A
 	INC R0		;operandus MSB-j�re �ll�tjuk a pointer�nket
	MOV A, @R0	;operandus MSB-j�t bet�ltj�k
	MOV R4, A
	DEC R0		;vissza�ll�tjuk a pointert az LSB-re
	;megn�zz�k, hogy az operandus negat�v sz�m-e
	MOV A, R4	;operandus MSB bet�ltj�k
	ANL A, #0x80;maszkolunk, hogy csak a legnagyobb bit lehessen nem 0
	JZ Switch	;ugrunk, ha a legnagyobb bit 0, azaz pozit�v sz�m
	CALL Complement2	;a legnagyobb bit 1-es, kettes komplemenselj�k


Switch:
	CJNE R2, #0x04, NotFour	;ugrik, ha R2 �rt�ke nem 4
	;R2 �rt�ke 4
	;10000 = 16 + 256 + 512 + 1024 + 8192
	;szorz�s 16al
	MOV R6, #0x04
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 256al
	MOV R6, #0x04
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 512vel
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 1024el
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 8192vel
	MOV R6, #0x03
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa
	JMP CheckIfNeg

NotFour:
	CJNE R2, #0x03, NotThree;ugrik, ha R2 �rt�ke nem 3
	;R2 �rt�ke 3
	;1000 = 8 + 32 + 64 + 128 + 256 + 512
	;szorz�s 8al
	MOV R6, #0x03
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 32vel
	MOV R6, #0x02
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 64-el
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 128al
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 256al
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 512vel
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	JMP CheckIfNeg
NotThree:
	CJNE R2, #0x02, NotTwo	;ugrik, ha R2 �rt�ke nem 2
	;R2 �rt�ke 2
	;100 = 4 + 32 + 64
	;szorz�s 4el
	MOV R6, #0x02
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 32vel
	MOV R6, #0x03
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	;szorz�s 64vel
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa

	JMP CheckIfNeg
NotTwo:
	CJNE R2, #0x01, IsZero	;ugrik, ha R2 �rt�ke nem 1
	;R2 �rt�ke 1
	;10 = 2 + 8
	;szorz�s 2vel
	MOV R6, #0x01
	CALL ShiftLeftR6Times
	CALL Add2Mem	;eredm�ny hozz�ad�sa
	;szorz�s 8al
	MOV R6, #0x02
	CALL ShiftLeftR6Times
	CALL Add2Mem;	;eredm�ny hozz�ad�sa

	JMP CheckIfNeg

IsZero:;R2 �rt�ke 0
	CALL Add2Mem

CheckIfNeg:
	;megn�zz�k, hogy az operandus negat�v sz�m volt-e
	INC R0		;MSB-re �ll�tjuk a pointert
	MOV A, @R0	;operandus MSB bet�ltj�k
	DEC R0		;LSB-re vissz�ll�tjuk a pointert
	ANL A, #0x80;maszkolunk, hogy csak a legnagyobb bit lehessen nem 0
	JZ OvCheck	;ugrunk, ha a legnagyobb bit 0, azaz pozit�v sz�m
	;az elmentett eredm�nyt kettes komplemenselni kell
	;bet�ltj�k az eredm�nyt R3(LSB) �s R4(MSB) regiszterekbe
	MOV A, @R1	;eredm�ny LSB-j�t bet�ltj�k
	MOV R3, A
 	INC R1		;eredm�ny MSB-j�re �ll�tjuk a pointer�nket
	MOV A, @R1	;eredm�ny MSB-j�t bet�ltj�k
	MOV R4, A
	DEC R1		;vissza�ll�tjuk a pointert az LSB-re
	CALL Complement2	;a legnagyobb bit 1-es, kettes komplemenselj�k
	;lenull�zzuk a mem�ri�ban l�v� eredm�nyt
	MOV @R1, #0x00	;kimeneti LSB null�z�sa
	INC R1			;k�vetkez� byte
	MOV @R1, #0x00	;kimeneti MSB null�z�sa
	DEC R1			;eredeti c�mre vissza�ll�t�s
	CALL Add2Mem	;mem�ri�ba bet�ltj�k a kettes komplemenselt eredm�nyt


OvCheck:
	;megn�zz�k, t�rt�nt-e t�lcsordul�s
	INC R0	;MSB-re �ll�tjuk a pointert
	INC R1	;MSB-re �ll�tjuk a pointert
	;ha v�ltozott a 15. bit akkor volt t�lcsordul�s
	MOV	A, @R0	;operandus MSB betolt�se
	XRL A, @R1	;eredm�ny MSB-t xor-oljuk az operandus MSB-vel
	ANL A, #0x80;maszkolunk, hogy csak a legnagyobb bit lehessen nem 0
	JNZ Overflow;ha az els� bit egyes, azaz v�ltoz�s t�rt�nt, akkor overflow van
	;ha van carry az R7ben akkor overflow
	MOV A, R7	;mindenkori PSW bet�ltj�k
	ANL A, #0x80;maszkolunk, hogy csak a legnagyobb bit lehessen nem 0
	JNZ Overflow;ha az els� bit egyes, azaz v�ltoz�s t�rt�nt, akkor overflow van
	RET

OverFlow:
	MOV PSW, #0x04	;be�ll�tjuk a PSW-ben az overflow bitet
	RET



; -----------------------------------------------------------
; ShiftLeftR6Times szubrutin
; -----------------------------------------------------------
; Funkci�: 		R3 �s R4 tartalm�t balra shifteli 1-el,
;				R3 tartalma beleshiftel�dik R4-be, R6-ban
;				meghat�rozott �rt�kszer
; Bementek:		R3 - LSB
;			 	R4 - MSB
;				R6 - ennyiszer kell balra shiftelni
; Kimenetek:  	R3 - LSB
;			 	R4 - MSB
; Regisztereket m�dos�tja:
;				R3, R4, R6
; -----------------------------------------------------------
ShiftLeftR6Times:
	CLR C		;CY t�rl�se, hogy ne zavarjon be
	MOV A,R3	;LSB bet�lt�se
	RLC A		;LSB balra forgat�sa, v�g�re 0 ker�l
	MOV R3,A	;elforgatott LSB kiment�se
	MOV A,R4	;MSB bet�lt�se
	RLC A		;MSB balra forgat�sa, v�g�re LSB legnagyobb bitje ker�l
	MOV R4,A	;elforgatott MSB kiment�se
	CALL SaveOV;elmentj�k, hogy t�rt�nt-e CY, mert ha igen, az t�lcsordul�s
	DJNZ R6, ShiftLeftR6Times;cs�kkenti R6 �rt�k�t �s shiftel, ha nem nulla
	RET



; -----------------------------------------------------------
; Add2Mem szubrutin
; -----------------------------------------------------------
; Funkci�: 		R1 �ltal mutatott c�men l�v� 16 bites �rt�khez
;				hozz�adja R3(LSB) �s R4(MSB) �rt�k�t
; Bementek:		R1 - mutat�
;				R3 - LSB
;			 	R4 - MSB
; Kimenetek:  	R1 - mutat�n l�v� �rt�k
; Regisztereket m�dos�tja:
;
; -----------------------------------------------------------
Add2Mem:
	CLR C     	;CY t�rl�se, hogy ne zavarjon be
	MOV A,R3	;LSB bet�lt�se
	ADD A,@R1	;mem�ria LSB-j�hez R3 LSB hozz�ad�sa
	MOV @R1,A  	;az �sszeget elt�rolja a mem�ri�ban l�v� LSB-n
	INC R1		;mem�ria MSB-re �ll�tjuk a pointert
	MOV A,R4	;MSB bet�lt�se
	ADDC A,@R1	;mem�ria MSB-j�hez R4 MSB hozz�ad�sa
	MOV @R1,A 	;az �sszeget elt�rolja a mem�ri�ban l�v� MSB-n
	DEC R1		;vissza�ll�tjuk a pointert a mem�ria LSB-re
	RET



; -----------------------------------------------------------
; SaveOV szubrutin
; -----------------------------------------------------------
; Funkci�: 		R7-be elmenti a PSW aktu�lis �llapot�t �gy,
;				hogy minden kor�bbi v�ltozata is jelen van
;				olyan form�ban, hogy az 1-eseket meg�rzi
; Bementek:		R7 - PSW t�rol� regiszter
; Kimenetek:  	R7 - PWS t�rol� regiszter
; Regisztereket m�dos�tja:
;				R7
; -----------------------------------------------------------
SaveOV:
	MOV A, PSW	;PSW bet�lt�se
	ORL A, R7	;PSW-hez hozz� vagyolja R7-et, mindkett� 1-esei A-ban
	MOV R7, A	;(PSW OR R7) kiment�se R7-be
	RET



; -----------------------------------------------------------
; Complement2 szubrutin
; -----------------------------------------------------------
; Funkci�: 		R3(LSB) �s R4(MSB) 16 bites sz�mot kettes
;				komplemenseli
; Bementek:		R3 - LSB
;				R4 - MSB
; Kimenetek:  	R3 - LSB
;				R4 - MSB
; Regisztereket m�dos�tja:
;				R3, R4
; -----------------------------------------------------------
Complement2:
	CLR C		;t�r�lj�k a CY-t, nehogy bezavarjon
	MOV A, R3	;operandus LSB-j�t bet�ltj�k
	CPL A		;operandus LSB-j�t komplement�ljuk
	ADD A, #0x01;operandus LSB-j�hez hozz�adunk 1-et
	MOV R3, A	;R3 operandus LSB �rt�ke
	MOV A, R4	;operandus MSB-j�t bet�ltj�k
	CPL A		;operandus MSB-j�t komplement�ljuk
	ADDC A,#0x00;operandus MSB-j�hez hozz�adjuk az LSB n�vel�s�b�l sz�rmaz� marad�kot
	MOV R4, A	;R4 operandus MSB �rt�ke
	RET



END
