	;TEST - ZMENA BARVY VSECH PIXELU
	;push rbx
	;mov rbx,  [R9 + 4]
	;xor rax, rax
	;mov rax, rdx	 		; i
	;mul rbx 			; XP * i
	;add eax, ecx			; XP * i + j
	;mov [ rsi + rax ], byte 130

	;pop rbx


	
	bits 64

	section .data


triCtvrtiny	dd	0.75
maxIteraci	dq	500	
minPosun	dd	0.002

	section .text

	extern sqrtf
	
	global meanShift
	; meanShift
	; ( 
	; 1 unsigned char *imageMatrix,
	; 2 unsigned char *resultMatrix, 
	; 3 int xP, 	 
	; 4 int yP, 
	; 5 unsigned char color,
	; 6 struct Hodnoty H - int x, y, colorDiff, radius, radiusE2
	; )
	; 1-RDI, 2-RSI, 3-RDX, 4-RCX, 5-R8 a 6-R9.
meanShift:

	enter 124, 0

	mov [rbp - 88], rbx
	mov [rbp - 96], r12
	mov [rbp - 104], r13
	mov [rbp - 112], r14
	mov [rbp - 120], r15

	mov [rbp - 124], edx
	
	movzx r8d, r8b
	cvtsi2ss xmm8, r8d	; rootColor
	xorps xmm9, xmm9 	; xyzSum[2]
	xorps xmm10, xmm10	; xyzSum[1]
	xorps xmm11, xmm11	; xyzSum[0]
	xorps xmm12, xmm12	; windowSum
	cvtsi2ss xmm14, edx	; X
	cvtsi2ss xmm15, ecx	; Y 
	xor r11, r11		; iterace
	

.whileTrue:			; cyklus konvergence
	
	
	;vypocet velikosti okna

	;I--
	cvtsi2ss xmm1, [R9 + 12]
	movss xmm0, xmm14	; x
	subss xmm0, xmm1 	; x - radius
	cvtss2si r14, xmm0	; i
	dec r14			; i--


	addss xmm0, xmm1	; x += radius
	addss xmm0, xmm1
	
	cvtss2si r12, xmm0	; i - ukoncovaci podminka
	inc r12
	
	;J--
	movss xmm0, xmm15	; y
	subss xmm0, xmm1	; y - radius
	cvtss2si r15, xmm0	; j0
	dec r15			; j0--

	addss xmm0, xmm1	; j0 += radius
	addss xmm0, xmm1
	
	cvtss2si r13, xmm0	; j0 - ukoncovaci podminka
	inc r13


	;;;;OKRAJE OBRAZU;;;;
	xor rax, rax

	cmp r14, 0
	cmovl r14, rax

	cmp r15, 0
	cmovl r15, rax
	
	; test ukoncovaci podminky
	cmp r12, 0
	cmovl r12, rax
	
	cmp r13d, 0
	cmovl r13, rax

	cmp r12d, dword [R9]
	cmovg r12d, dword [R9]

	cmp r13d, dword [R9 + 4]
	cmovg r13d, dword [R9 + 4]

	; konec vypoctu velikosti okna-------------------------------
	
.outerFor:			;dva zanorene for cykly 
	
	
	mov r10, r15	 	; j
	
.innerFor:
	

	cmp r14d, dword [R9]
	jge .toOuterFor		; break			

	cmp r10d, dword [R9 + 4]
	jge .toOuterFor		; break

	xorps xmm13, xmm13	; sum = 0
	
	;\\\\\\\//KRUH\\////////
	
	cvtsi2ss xmm0, r14d
	subss xmm0, xmm14
	mulss xmm0, xmm0
	
	cvtsi2ss xmm1, r10d
	subss xmm1, xmm15
	mulss xmm1, xmm1
	
	addss xmm0, xmm1

	cvtsi2ss xmm1, [R9 + 16]
	;//////////\\\\\\\\\\\\
	; ( (i - x) * (i - x) + (j - y ) * (j - y) <= radiusE2 )
	comiss xmm0, xmm1
	ja .neOdpovida
	
	;index
	mov rax, r14
	mul dword [r9 + 4]
	add rax, r10

	movzx ebx, byte [rdi + rax] 	; opr... 
	cvtsi2ss xmm7, ebx		; child color
	movss xmm6, xmm7		; roz
	subss xmm6, xmm8
	xorps xmm0, xmm0
	comiss xmm6, xmm0
	
	movq rbx, xmm6			; absolutni hodnota	
	and ebx, 0x7fffffff
	movq xmm6, rbx
.notRoz:
	cvtsi2ss xmm5, [R9 + 8]		; colorDiff
	subss xmm5, xmm6		; colorDiff - roz 
	
	xorps xmm0, xmm0
	comiss xmm5, xmm0
	jb .neOdpovida			; odpovida boda parametrum?
	;xxd, yyd a zzd nejsou glob, bo je neni potreba mimo tuto podminku

	cvtsi2ss xmm1, [R9 + 12]	
	movss xmm6, xmm14
	cvtsi2ss xmm3, r14d
	subss xmm6, xmm3		
	divss xmm6, xmm1		; (x - i) / radius
	
	movss xmm5, xmm15
	cvtsi2ss xmm3, r10d
	subss xmm5, xmm3
	divss xmm5, xmm1		; (y - i )/ radius

	movss xmm4, xmm8
	subss xmm4, xmm7
	cvtsi2ss xmm1, [R9 + 8]
	divss xmm4, xmm1		; (rootColor - childColor) / colorDiff
	
	movss xmm13, xmm6
	mulss xmm13, xmm13
	
	mulss xmm5, xmm5
	mulss xmm4, xmm4
	
	addss xmm13, xmm5
	addss xmm13, xmm4		; sum = xxd*xxd + yyd*yyd + zzd*zzd

	; KERNEL (Epanechnikov)
	mov eax, 1
	cvtsi2ss xmm0, eax 
	
	comiss xmm13, xmm0
	jb .eofKernel1
	xorps xmm13, xmm13
	jmp .eofKernel2
.eofKernel1:

	mulss xmm13, xmm13
	subss xmm0, xmm13
	movss xmm13, [triCtvrtiny]			
	mulss xmm13, xmm0		; sum = 0.75f * ( 1 - sum * sum )

.eofKernel2:

	addss xmm12, xmm13		; windowSum += sum

	cvtsi2ss xmm0, r14d
	mulss xmm0, xmm13
	
	addss xmm11, xmm0		; xyzSum[0]
	
	cvtsi2ss xmm0, r10d
	mulss xmm0, xmm13
	
	addss xmm10, xmm0		; xyzSum[1]
	
	mulss xmm13, xmm7
	addss xmm9, xmm13		; xyzSum[2]
	

.neOdpovida: ; bod neodpovida parametrum, nebo je mimo kruh

	inc r10				; j++

	cmp r10, r13			; ukonceni innerFor
	je .toOuterFor	
		

	jmp .innerFor

.toOuterFor:
	
	inc r14				; i++
	
	cmp r14, r12			; podminka vnejsi for
	je .toWhileTrue


	jmp .outerFor

.toWhileTrue: ; ukonceni obou for cyklu

	xorps xmm0, xmm0
	comiss xmm12, xmm0
	
	divss xmm11, xmm12		; xyzSum[0] /= windowSum 
	divss xmm10, xmm12		; xyzSum[1] /= windowSum
	divss xmm9, xmm12		; xyzSum[2] /= windowSum

	
	;_VEKTOR POSUNU_
	movss xmm0, xmm11
	subss xmm0, xmm14
	mulss xmm0, xmm0
	
	movss xmm1, xmm10
	subss xmm1, xmm15
	mulss xmm1, xmm1

	movss xmm2, xmm9
	subss xmm2, xmm8
	mulss xmm2, xmm2

	addss xmm0, xmm1
	addss xmm0, xmm2
	

	mov [rbp - 32], r11
	mov [rbp - 40], r9
	mov [rbp - 48], rcx
	mov [rbp - 56], rdx
	mov [rbp - 64], rsi
	mov [rbp - 72], rdi
	mov [rbp - 80], r11

	movss [rbp -4], xmm8
	movss [rbp -8], xmm9
	movss [rbp -12], xmm10
	movss [rbp -16], xmm11
	movss [rbp -20], xmm14
	movss [rbp -24], xmm15

	call sqrtf			; posun
	; sqrt((xyzSum[0] - x) * (xyzSum[0] - x) + (xyzSum[1] - y) * (xyzSum[1] - y) +
	; (xyzSum[2] - rootColor) * (xyzSum[2] - rootColor))
	
	mov r11, [rbp - 32]
	mov r9, [rbp - 40]
	mov rcx, [rbp - 48]
	mov rdx, [rbp - 56]
	mov rsi, [rbp - 64]
	mov rdi, [rbp - 72]
	mov r11, [rbp - 80]

	
	movss xmm8, [rbp -4]
	movss xmm9, [rbp -8]
	movss xmm10,[rbp -12]
	movss xmm11,[rbp -16]
	movss xmm14,[rbp -20]
	movss xmm15,[rbp -24]
	
	inc r11
	
	
	; ukoncovaci podminka---
	cmp r11d, dword [maxIteraci]
	jge .konec

	movss xmm1, [minPosun]
	
	comiss xmm0, xmm1
	jb .konec
	; -----------------------

	movss xmm14, xmm11
	movss xmm15, xmm10
	movss xmm8, xmm9
	
	xorps xmm11, xmm11
	xorps xmm10, xmm10
	xorps xmm9, xmm9
	xorps xmm12, xmm12


	
	jmp .whileTrue

.konec:
	mov eax, [rbp - 124]
	mul dword [r9 + 4]
	add eax, ecx
	cvtss2si ebx, xmm9
	mov [rsi + rax], bl
	movss xmm0, xmm9

	
	mov rbx, [rbp - 88]
	mov r12, [rbp - 96]
	mov r13, [rbp - 104]
	mov r14, [rbp - 112]
	mov r15, [rbp - 120]

	leave
	ret
