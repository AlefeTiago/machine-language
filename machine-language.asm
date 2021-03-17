;Alefe Tiago Feliciano RA:230530
;-----Primeiramente, explicando como fiz a subrotina de delay com espera ativa!---
;A ideia de chamar uma subrotina para conseguir o delay necessário é consumir ciclos no processamento até que se dê
;o tempo proposto. Para isso, fazemos carregamentos e decrementos em loop até que se consiga a quantidade necessária de 
;tempo. Vamos aos calculos: 
;------
;Como o arduino tem 16Mhz de frequência e sabemos que o periodo para um ciclo é de 1/16e6 (inverso da frequência),
;sabemos também que a quantidade de ciclos para conseguir um determinado tempo (t) de espera é dado por:
;qtd_ciclos=t/(1/f). Logo, para:
    ;			------- 0.1 s -----> qtd_ciclos=0.1/(1/16e6) = 1 600 000 ciclos
    ;			------- 1 s -------> qtd_ciclos=1/(1/16e6) = 16 000 000 ciclos 
    ; agora, olhando para a estrutura dos laços que serão utilizados: 
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
;Seu funcionamento é dado da seguinte forma:
;No primeiro laço (antes de BRNE L1) eu tenho 3 instruções que vão consumir (segundo o manual do montador) 4 ciclos de
;relogio! Logo, como esse laço decrementa REG3 e pula para DEC REG2 só quando REG3 nulo, então até que REG3 zere eu tenho 
;4xC ciclos! Usando o mesmo pensamento para o outros loops tenho uma expressão final: 4*C*B*A ciclos.
;E essa multiplicação tem que dar 1 600 000 para 0.1s
			;-------- 16 000 000 para 1s 
;Para isso, usei A=250, B=160, C=100 para 1s
		;A=250, B=50, C=32 para 0.1s
; E assim, consegui implementar as esperas ativas necessárias.
    
    
.org 0x0000 ; Por padrão, colocamos o endereço 0x0000 que é onde o programa vai começar de fato e onde o reset ficará. Ou seja,
		; quando apertado o reset na placa, PC toma o valor 0x00.
		
		
		
jmp main ; Contudo, logo que o PC é incrementado, o programa entra nessa estrutura de jump para o endereço do rótulo main
	; que será associado a um endereço de memoria logo abaixo. 
    
.org 0x0004  ;aqui eu declarei o endereço de memória pra onde o programa vai se ocorrer uma interrupção     
jmp rsi ; Para não ficar colocando endereços de memória, criei (lá onde a função de tratamento de interrupções esta definido)um rótulo (rsi)
     
.org 0x0034   ; primeiro endereço depos dos endereços reservados para a rotina de interrupção é onde vou colocar meu programa principal.
    
main: ;o endereço 34 0x0034 recebe o rotulo main
   cli
   ;configurando o stack pointer(endereço da pilha)
   ;SP <= 0X08FF
   ;SP: SPH 0x3E- endereço para manipulação spi,in, out,cdi (0x5E-endereço do mapeamento em memo) 
   ;e SPL 0x3D (0x5D)
   ;Stack pointer deve apontar para o último enederço de memoria de dados 0x08FF
   ldi r16, 0xFF; Usando r16 como reg auxiliar, carrego em SPL o valor 0xFF
   out SPL, r16 ; SPL=0X3D
   
   ldi r16, 0x08
   out SPH, r16; Sem usar o mapeamento em memoria (valor fora do parenteses no manual), carrego 0x08 em SPH.
   
  ;config portas I/O
   
  ;---- Para a entrada ---- 
  
   cbi DDRD,3 ;configurando o pino 3 como entrada (botao)
   sbi PORTD,3 ;ativando resistor de pullup para o botão
   in r16, MCUCR ;Carrega MCUCR em r16 para criar uma mascara na proxima linha (queremos zerar o bit 4)- PUD - Resistor de pull-up
   andi r16, 0xEF  ; zera o bit PUD e mantem-se o conteudo dos outros bits.
   out MCUCR,r16 ; carrega o mcucr com a máscara
    
   ;--- Para o LED --- 
   sbi DDRB,5 ;configurando a port B5 como saída (led integrado)
   cbi PORTB,5 ;apaga o led no início
   
  ;config interrupt
  
   ldi r16,8 
   sts EICRA,r16 ; como EICRA não pode ser acessado por sbi,cbi. Usei um registrador auxiliar para carregar valor 8 nele (a interrupçaõ é ativada por borda de descida! Visto que ativamos o resitor de pull up)
   sbi EIMSK,1 ; ativo a interrupção INT1
   cbi EIMSK,0 ; por garantia desativo a interrupção INT0
   
   sei ; habilito as interrupções que haviam sido desabilitadas
   jmp laco ; por via de duvidas, garanto que o laço será iniciado!
   
laco:
    call delay_1_s ;inicio esperando 1s, visto que no laço principal queremos 0,5Hz de frequência. Essa subrotina foi explicada no topo do arquivo
    sbi PORTB,5 ; acendo o led
    call delay_1_s ; espero mais 1s
    cbi PORTB,5; apago o led
    
    jmp laco ; retorno para o inicio do laço

rsi:
    push r16 ;salva r16 na pilha , se a interrupção acontecer no meio da subrotina de tempo não perco nada.
    push r17 ;salva r17 na pilha , se a interrupção acontecer no meio da subrotina de tempo não perco nada.
    push r18 ;salva r18 na pilha , se a interrupção acontecer no meio da subrotina de tempo não perco nada.
    in r16, SREG ;  r16 <- SREG 
    push r16 ;salva o valor de SREG na pilha.
    in r16, PORTB
    push r16  ; Salvo o estado do LED anterior a chamada também.
    
    
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
    in r16, EIFR ; carrega o conteúdo de EIFR em r16
    ori r16, 2 ; desativa o bit que indica interrupção externa da iNT1. P/ Evitar dupla chamada da RSI.
    out EIFR, r16 ; transfere-se a máscara atualizada para EIFR
    pop r16 ; Restauro o valor de r16
    
    reti ; retorno da rotina de interrupção.
 
    
    
    ; ''''' SUBROTINAS DE CONSUMO DE TEMPO ''''''
    ; O MODELO PADRÃO DAS DUAS FORAM EXPLICADOS NO TOPO DO ARQUIVO!! 
    ; A DEMONSTRAÇÃO DOS VALORES CARREGADOS EM CADA REGISTRADOR TAMBEM ESTAO LÁ
    ; LEMBRANDO QUE L3,L2,L1 E L3_1, L2_1, L1_1 SÃO APENAS ROTULOS! 
    
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

