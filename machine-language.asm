;Alefe Tiago Feliciano RA:230530
;-----Primeiramente, explicando como fiz a subrotina de delay com espera ativa!---
;A ideia de chamar uma subrotina para conseguir o delay necess�rio � consumir ciclos no processamento at� que se d�
;o tempo proposto. Para isso, fazemos carregamentos e decrementos em loop at� que se consiga a quantidade necess�ria de 
;tempo. Vamos aos calculos: 
;------
;Como o arduino tem 16Mhz de frequ�ncia e sabemos que o periodo para um ciclo � de 1/16e6 (inverso da frequ�ncia),
;sabemos tamb�m que a quantidade de ciclos para conseguir um determinado tempo (t) de espera � dado por:
;qtd_ciclos=t/(1/f). Logo, para:
    ;			------- 0.1 s -----> qtd_ciclos=0.1/(1/16e6) = 1 600 000 ciclos
    ;			------- 1 s -------> qtd_ciclos=1/(1/16e6) = 16 000 000 ciclos 
    ; agora, olhando para a estrutura dos la�os que ser�o utilizados: 
    ;delay_X_ms:            
    ;	ldi REG1,A      
    ;L3:
    ;	ldi REG2,B     
    ;L2:
    ;	ldi REG3,C     
    ;L1:
    ;	dec REG3            
    ;	nop                    
    ;	brne L1  

    ;	dec REG2            
    ;	brne L2   

    ;	dec REG1            
    ;	brne L3        
;    ret
;Seu funcionamento � dado da seguinte forma:
;No primeiro la�o (antes de BRNE L1) eu tenho 3 instru��es que v�o consumir (segundo o manual do montador) 4 ciclos de
;relogio! Logo, como esse la�o decrementa REG3 e pula para DEC REG2 s� quando REG3 nulo, ent�o at� que REG3 zere eu tenho 
;4xC ciclos! Usando o mesmo pensamento para o outros loops tenho uma express�o final: 4*C*B*A ciclos.
;E essa multiplica��o tem que dar 1 600 000 para 0.1s
			;-------- 16 000 000 para 1s 
;Para isso, usei A=250, B=160, C=100 para 1s
		;A=250, B=50, C=32 para 0.1s
; E assim, consegui implementar as esperas ativas necess�rias.
    
    
.org 0x0000 ; Por padr�o, colocamos o endere�o 0x0000 que � onde o programa vai come�ar de fato e onde o reset ficar�. Ou seja,
		; quando apertado o reset na placa, PC toma o valor 0x00.
		
		
		
jmp main ; Contudo, logo que o PC � incrementado, o programa entra nessa estrutura de jump para o endere�o do r�tulo main
	; que ser� associado a um endere�o de memoria logo abaixo. 
    
.org 0x0004  ;aqui eu declarei o endere�o de mem�ria pra onde o programa vai se ocorrer uma interrup��o     
jmp rsi ; Para n�o ficar colocando endere�os de mem�ria, criei (l� onde a fun��o de tratamento de interrup��es esta definido)um r�tulo (rsi)
     
.org 0x0034   ; primeiro endere�o depos dos endere�os reservados para a rotina de interrup��o � onde vou colocar meu programa principal.
    
main: ;o endere�o 34 0x0034 recebe o rotulo main
   cli
   ;configurando o stack pointer(endere�o da pilha)
   ;SP <= 0X08FF
   ;SP: SPH 0x3E- endere�o para manipula��o spi,in, out,cdi (0x5E-endere�o do mapeamento em memo) 
   ;e SPL 0x3D (0x5D)
   ;Stack pointer deve apontar para o �ltimo eneder�o de memoria de dados 0x08FF
   ldi r16, 0xFF; Usando r16 como reg auxiliar, carrego em SPL o valor 0xFF
   out SPL, r16 ; SPL=0X3D
   
   ldi r16, 0x08
   out SPH, r16; Sem usar o mapeamento em memoria (valor fora do parenteses no manual), carrego 0x08 em SPH.
   
  ;config portas I/O
   
  ;---- Para a entrada ---- 
  
   cbi DDRD,3 ;configurando o pino 3 como entrada (botao)
   sbi PORTD,3 ;ativando resistor de pullup para o bot�o
   in r16, MCUCR ;Carrega MCUCR em r16 para criar uma mascara na proxima linha (queremos zerar o bit 4)- PUD - Resistor de pull-up
   andi r16, 0xEF  ; zera o bit PUD e mantem-se o conteudo dos outros bits.
   out MCUCR,r16 ; carrega o mcucr com a m�scara
    
   ;--- Para o LED --- 
   sbi DDRB,5 ;configurando a port B5 como sa�da (led integrado)
   cbi PORTB,5 ;apaga o led no in�cio
   
  ;config interrupt
  
   ldi r16,8 
   sts EICRA,r16 ; como EICRA n�o pode ser acessado por sbi,cbi. Usei um registrador auxiliar para carregar valor 8 nele (a interrup�a� � ativada por borda de descida! Visto que ativamos o resitor de pull up)
   sbi EIMSK,1 ; ativo a interrup��o INT1
   cbi EIMSK,0 ; por garantia desativo a interrup��o INT0
   
   sei ; habilito as interrup��es que haviam sido desabilitadas
   jmp laco ; por via de duvidas, garanto que o la�o ser� iniciado!
   
laco:
    call delay_1_s ;inicio esperando 1s, visto que no la�o principal queremos 0,5Hz de frequ�ncia. Essa subrotina foi explicada no topo do arquivo
    sbi PORTB,5 ; acendo o led
    call delay_1_s ; espero mais 1s
    cbi PORTB,5; apago o led
    
    jmp laco ; retorno para o inicio do la�o

rsi:
    push r16 ;salva r16 na pilha , se a interrup��o acontecer no meio da subrotina de tempo n�o perco nada.
    push r17 ;salva r17 na pilha , se a interrup��o acontecer no meio da subrotina de tempo n�o perco nada.
    push r18 ;salva r18 na pilha , se a interrup��o acontecer no meio da subrotina de tempo n�o perco nada.
    in r16, SREG ;  r16 <- SREG 
    push r16 ;salva o valor de SREG na pilha.
    in r16, PORTB
    push r16  ; Salvo o estado do LED anterior a chamada tamb�m.
    
    
    ;----- Ligando e desligando o LED de 0.1 - 0.1 s para criar o efeito desejado --- 
    cbi PORTB,5
    call delay_100_ms
    sbi PORTB,5
    call delay_100_ms
    cbi PORTB,5
    call delay_100_ms
    sbi PORTB,5
    call delay_100_ms
    cbi PORTB,5
    call delay_100_ms
    sbi PORTB,5
    call delay_100_ms
    cbi PORTB,5
    call delay_100_ms
    
    pop r16 
    out PORTB, r16 ;Restauro o valor do LED
    pop r16
    out SREG,r16 ; Restauro o valor de SREG
    pop r18  ;Restauro o valor de r18
    pop r17  ; Restauro o valor de r17 
    in r16, EIFR ; carrega o conte�do de EIFR em r16
    ori r16, 2 ; desativa o bit que indica interrup��o externa da iNT1. P/ Evitar dupla chamada da RSI.
    out EIFR, r16 ; transfere-se a m�scara atualizada para EIFR
    pop r16 ; Restauro o valor de r16
    
    reti ; retorno da rotina de interrup��o.
 
    
    
    ; ''''' SUBROTINAS DE CONSUMO DE TEMPO ''''''
    ; O MODELO PADR�O DAS DUAS FORAM EXPLICADOS NO TOPO DO ARQUIVO!! 
    ; A DEMONSTRA��O DOS VALORES CARREGADOS EM CADA REGISTRADOR TAMBEM ESTAO L�
    ; LEMBRANDO QUE L3,L2,L1 E L3_1, L2_1, L1_1 S�O APENAS ROTULOS! 
    
delay_100_ms:            
    ldi r16,32      
L3:
    ldi r17,50     
L2:
    ldi r18,250     
L1:
    dec r18            
    nop                    
    brne L1  
    
    dec r17            
    brne L2   
    
    dec r16            
    brne L3        
ret
    
    
delay_1_s:            
    ldi r16,100      
L1_1:
    ldi r17,160     
L2_1:
    ldi r18,250     
L3_1:
    dec r18            
    nop                    
    brne L3_1 
    
    dec r17            
    brne L2_1  
    
    dec r16            
    brne L1_1        
ret
    
; VALE LEMBRAR QUE PARA SUBROTINAS USEI OS COMANDOS CALL - RET PARA CHAMAR E VOLTAR
; JA PARA RSI USEI CALL E RETI     

