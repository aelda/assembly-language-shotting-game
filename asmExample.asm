TITLE Example of ASM                (asmExample.ASM)

; This program locates the cursor and displays the
; system time. It uses two Win32 API structures.
; Last update: 6/30/2005

INCLUDE Irvine32.inc

; Redefine external symbols for convenience
; Redifinition is necessary for using stdcall in .model directive 
; using "start" is because for linking to WinDbg.  added by Huang

 
main          EQU start@0
.data
screenColumns		DWORD	80
screenLeftBoundry	BYTE	0
screenRightBoundry	BYTE	79
QuitFlag			BYTE	0

winCaption	BYTE	"Game Message", 0
winQuestion	BYTE	"You Win!", 0dh, 0ah
			BYTE	"Try again?", 0

lossCaption		BYTE	"Game Message", 0
lossQuestion	BYTE	"You Lose!", 0dh, 0ah
				BYTE	"try again?", 0

MainChar			BYTE	06h, 0		
MainCharMoveStep	BYTE	2
MainCharFrontColor	BYTE	white	
MainCharBackColor	BYTE	red*16	;20h
MainCharX			BYTE	20
MainCharY			BYTE	20
OldMainCharX		BYTE	20
OldMainCharY		BYTE	20

BulletSymbol		BYTE	0fh, 0
BulletFrontColor	BYTE	yellow
BulletBackColor		BYTE	black*16	
BulletFlag			BYTE	0
BulletX				BYTE	0
BulletY				BYTE	0
OldBulletX			BYTE	0
OldBulletY			BYTE	0

scoreColor	DWORD	white+(black*16)
scoreMsg	BYTE	"Score:", 0
score		DWORD	0
winScore	DWORD	5
scoreY		BYTE	22
scoreX		BYTE	40

lifeColor				DWORD	white+(black*16)
lifeResetSymbol			BYTE	6 DUP(" ")
lifeMsg					BYTE	"Life:", 0
lifeY					BYTE	22
lifeX					BYTE	20
life					DWORD	20
initLife				DWORD	20

explosionFlag		BYTE	0

enemySymbol			BYTE	49h, 49h, 49h, 49h, 0
enemySize			BYTE	4
enemyResetSymbol	BYTE	4 DUP(" ")	; 4 should be same as enemySize
enemyInitX			BYTE	5
enemyX				BYTE	0
enemyY				BYTE	?
enemyFrontColor		BYTE	yellow		;05h
enemyBackColor		BYTE	white*16	;0E0h
enemyHitBoundryFlag	BYTE 	0
enemyResetLine		BYTE	80 DUP(" ")
showup  			BYTE 	0
first				BYTE    0

background BYTE	" "
backgroundColor DWORD (black*16)+black
frontColorMask BYTE 0Fh


.code
main PROC
	
	call Clrscr

L0:
	call HandleKeyEvent	
	call ClearMainCharOldPos
	call ClearBulletOldPos
	call clearEnemy
	call clearExplosion
	call checkBulletHitEnemy
	call updateEnemy
	call ShowMainChar
	call ShowBullet
	call showEnemy
	call showExplosion
	call showLife
	call ShowScore	
	call checkLife
	add enemyFrontColor, 2
	cmp QuitFlag, 1
	je Exit0
	jmp L0

Exit0:
	INVOKE ExitProcess, 0

main ENDP

ClearMainCharOldPos PROC USES eax edx
	mov dh, OldMainCharY
	mov dl, OldMainCharX
	call ClearPosBlack
	mov al, MainCharY
	mov OldMainCharY, al
	mov al, MainCharX
	mov OldMainCharX, al
	ret
ClearMainCharOldPos ENDP

ClearPosBlack PROC USES eax edx
	mov ah, black
	mov al, black
	call SetTextColor
	call Gotoxy
	mov edx, offset background
	call WriteString
	ret
ClearPosBlack ENDP


ClearBulletOldPos PROC USES eax edx
	mov dh, OldBulletY
	mov dl, OldBulletX
	call ClearBulletPos
	mov al, BulletY
	mov OldBulletY, al
	ret
ClearBulletOldPos ENDP

ClearBulletPos PROC USES eax
	mov eax, backgroundColor
	call SetTextColor
	call Gotoxy
	push edx
	mov edx, offset background
	call WriteString
	pop edx
	ret
ClearBulletPos ENDP

ShowBullet PROC USES eax edx

	cmp BulletFlag, 0
	je dontshow
	cmp OldBulletY, 0
	jbe disappear
	cmp explosionFlag, 1
	je	disappear
	mov dh, BulletY
	mov dl, BulletX
	call Gotoxy
	xor eax, eax
	mov al, BulletBackColor
	mov dl, frontColorMask
	and BulletFrontColor, dl
	add al, BulletFrontColor
	call SetTextColor
	mov edx, offset BulletSymbol
	call WriteString
	dec BulletY
	jmp dontshow
	
disappear:
	mov BulletFlag, 0
dontshow:
	ret	
ShowBullet ENDP

ActivateBullet PROC USES eax
	cmp BulletFlag, 1
	je stay
	mov BulletFlag, 1
	mov al, MainCharY
	dec al
	mov BulletY, al
	mov OldBulletY, al
	mov al, MainCharX
	mov BulletX, al
	mov OldBulletX, al

stay:
	ret
ActivateBullet ENDP

ShowMainChar PROC USES eax edx
	xor eax, eax
	mov al, MainCharBackColor
	mov dl, frontColorMask
	and MainCharFrontColor, dl
	add al, MainCharFrontColor
	call SetTextColor

	mov dh, MainCharY
	mov dl, MainCharX
	call Gotoxy
	mov edx, offset MainChar
	call WriteString
	ret
ShowMainChar ENDP

clearEnemy PROC USES eax edx
	mov eax, backgroundColor
	call SetTextColor
	mov dh, enemyY
	mov dl, enemyX
	call Gotoxy
	mov edx, offset enemyResetSymbol
	call WriteString
	ret
clearEnemy ENDP

clearExplosion PROC USES eax edx
	cmp explosionFlag, 2
	jne nothingtoclear
	mov explosionFlag, 0
	
nothingtoclear:	
	ret
clearExplosion ENDP

updateEnemy PROC USES eax
	cmp explosionFlag, 1
	je resetEnemyPostion
	mov al,80
	sub al, enemySize
	cmp enemyX, al
	je enemyhitboundry
	inc enemyX
	jmp continue
	
enemyhitboundry:
	mov enemyHitBoundryFlag, 1
	
resetEnemyPostion:
	call ClearEnemyLine
	mov al, enemyInitX
	mov enemyX, al
	mov showup,1

	
continue:
	ret
updateEnemy ENDP


ClearEnemyLine PROC USES eax edx
	mov eax, backgroundColor
	call SetTextColor
	mov dh, 0
	mov dl, enemyX
	call Gotoxy
	mov edx, offset enemyResetLine
	call WriteString
	ret
ClearEnemyLine ENDP


showEnemy PROC USES eax edx
	xor eax, eax
	mov eax,blue+(white*16)
	call SetTextColor
	.IF showup == 1
	mov al,20
	call RandomRange
	mov showup,0
	mov enemyY,al
	.ENDIF
	mov dh, enemyY
	mov dl, enemyX
	call Gotoxy
	mov edx, offset enemySymbol
	call WriteString
	ret
showEnemy ENDP


showScore PROC USES eax edx
	
	.IF first ==0
	mov explosionFlag,0
	mov first,1
	.ENDIF
	xor eax,eax
	mov eax, scoreColor
	call SetTextColor
	mov dh, scoreY
	mov dl, scoreX
	call Gotoxy
	mov edx, offset scoreMsg
	call WriteString
	add dl, 7
	call Gotoxy

	cmp explosionFlag, 0
	je remain
	inc score
	mov explosionFlag, 2
	
	
remain:

	mov eax, score
	call WriteDec
	ret
showScore ENDP


clearShowLife PROC USES eax edx
	mov eax, 00000000h
	call SetTextColor
	mov dh, lifeY
	mov dl, lifeX
	call Gotoxy
	mov edx, offset lifeResetSymbol
	call WriteString
	ret
clearShowLife ENDP


showLife PROC USES eax edx
	mov eax, lifeColor
	cmp life, 1
	ja nowarning
	call clearShowLife


nowarning:
	call SetTextColor
	mov dh, lifeY
	mov dl, lifeX
	call Gotoxy
	mov edx, offset lifeMsg
	call WriteString
	add dl, 6
	call Gotoxy
	cmp enemyHitBoundryFlag, 0
	je remain
	dec life
	mov enemyHitBoundryFlag, 0

	
remain:
	mov eax, life
	call WriteDec
	ret
showLife ENDP


checkBulletHitEnemy PROC USES eax
	
	mov al, enemyY
	cmp BulletY, al
	jne nochange
	mov al, enemyX
	cmp BulletX, al
	jb nochange
	add al, enemySize
	cmp BulletX, al
	ja nochange
	mov explosionFlag, 1
	add enemyBackColor, 16
	
nochange:
	ret
checkBulletHitEnemy ENDP


showExplosion PROC USES eax edx
	cmp explosionFlag, 0
	je	noexplosion

	; reset Bullet position
	mov BulletY, 0
	mov BulletX, 0
	
noexplosion:
	ret
showExplosion ENDP 



checkLife PROC USES eax ebx edx
	mov eax, winScore
	cmp score, eax
	jne L4
	mov ebx, OFFSET winCaption
	mov edx, OFFSET winQuestion
	call MsgBoxAsk
	cmp eax, 6
	je L5
	mov QuitFlag, 1
	ret
	
L5:
	mov eax, initLife
	mov life, eax
	mov score, 0
	ret
	
L4:	
	cmp life, 0
	je L0
	ret
	
L0:
	mov ebx, OFFSET lossCaption
	mov edx, OFFSET lossQuestion
	call MsgBoxAsk
	cmp eax, 6
	je L1
	mov QuitFlag, 1
	
L1:
	mov eax, initLife
	mov life, eax
	mov score, 0
    mov BulletFlag, 0    
	ret	
checkLife ENDP


HandleKeyEvent PROC
	pushad
	mov eax, 50
	call Delay		;Each frame,the duration ofthe delay MUST be 50 milliseconds.
	call ReadKey
	cmp al, 'a'
	je Left
	cmp al, 'd'
	je Right
	cmp al, ' '
	je Fire
	cmp dx, 001Bh	;key ESC
	je Quit
	jmp	L1
	
Left:
	call HandleKeyEventLeftMove
	jmp L1
	
Right:
	call HandleKeyEventRightMove
	jmp L1
	
Fire:
	call ActivateBullet 
	jmp L1
	
Quit:
	mov QuitFlag, 1
	
L1:
	popad
	ret
HandleKeyEvent ENDP 


HandleKeyEventLeftMove PROC USES eax
	mov al, screenLeftBoundry
	inc al
	cmp MainCharX, al	;check left boundry
	jbe stay
	mov al, MainCharMoveStep
	sub MainCharX, al
	
stay:
	ret
HandleKeyEventLeftMove ENDP 


HandleKeyEventRightMove PROC USES eax
	mov al, screenRightBoundry
	dec al
	cmp MainCharX, al	;check right boundry
	jae stay
	mov al, MainCharMoveStep
	add MainCharX, al
	
stay:
	ret
HandleKeyEventRightMove ENDP 

END main 