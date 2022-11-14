.model small

.stack 100H

.data 
    title_line_size db 29  
                     
    CR db 10
    LF db 13
             
    title1 db '        ________               __ ',10,13
           db '       / ____/ /_  ____  _____/ /_',10,13
           db '      / / __/ __ \/ __ \/ ___/ __/',10,13
           db '     / /_/ / / / / /_/ (__  ) /_  ',10,13
           db '     \____/_/_/_/\____/____/\__/  ',10,13
           db '           / / / /_  ______  / /_ ',10,13
           db '          / /_/ / / / / __ \/ __/ ',10,13
           db '         / __  / /_/ / / / / /_   ',10,13
           db '        /_/ /_/\__,_/_/ /_/\__/   ',10,13           
    title1_len EQU $-title1
                                                                 
    GHOST_MASK db '   xxxxxx   ',
               db '  xxxxxxxx  ',
               db ' xxxxxxxxxx ',
               db 'xxx  xx  xxx',
               db 'xxx  xx  xxx',
               db 'xxxxxxxxxxxx',
               db 'xxxxxxxxxxxx',
               db 'xxxxxxxxxxxx',
               db 'xxx xxxx xxx',
               db ' x   xx   x '
    GHOST_MASK_WIDTH_LEN db 12
    GHOST_MASK_HEIGHT_LEN db 10    
    
    VIDEO_BUFFER_SEGMENT dw 40960
                                                                 
    ; Tela inicial
    TITLE_SELECTED_BTN db 1 ; 1 ou 2     
    IS_GAME_TITLE_RENDERED db 0 ; 0 ou 1
    START_BTN_1 db 'Jogar$'
    START_BTN_2 db 'Sair$'  
    SHOULD_END_GAME db 0 ; 0 | 1
.code  

;INPUT : DL=X, DH=Y.
SET_CURSOR proc
      mov  ah, 2    
      mov  bh, 0    ;Pagina de video
      int  10h      
      RET
endp   

; Escreve na tela um caractere armazenado em DL     
ESC_CHAR proc
	push AX    ; salvar o reg AX
	mov AH, 2
	int 21H
	pop AX     ; restaurar o reg AX
	ret  
endp  

; Rotina que escreve na tela uma mensagem com endere?o em DX
ESC_STR proc
	push AX			
    mov AH, 9		
    int 21H  
    pop AX
    ret  
endp 
       
TEXT_MODE proc
    push AX
    ; Modo texto
    mov AX, 13h  
    int 10h
    pop AX    
    ret
TEXT_MODE endp 
        
; --------------------------------------------------------------  
; Mostra o t?tulo na tela inicial         
proc SHOW_TITLE
    push DX
    push CX
    push BX
    push AX     
                      
    mov AL, 0 ; https://i.pinimg.com/736x/9d/4a/3b/9d4a3b8bece01eb5aef7a78eb0d7be93.jpg
    mov BH, 0 ; Número da página
    mov BL, 2 ; Cor => 02 = Fundo preto e texto verde
    
    mov DH, 4              ; Linha
    mov DL, 0              ; Coluna
    mov CX, title1_len     ; Tamanho
    mov BP, offset title1  ; Endereço
    
    ; https://en.wikipedia.org/wiki/INT_10H
    mov AH, 13H 
    int 10H    
                   
    MOV IS_GAME_TITLE_RENDERED, 1
                   
    pop AX
    pop BX
    pop CX
    pop DX    
    ret
SHOW_TITLE endp
  
; Escuta o clique na tela inicial
CHANGE_OPTION proc
    PUSH AX
    XOR AX, AX
                            
    ; https://www.stanislavs.org/helppc/int_16.html 
    ; https://www.youtube.com/watch?v=8dYRlRjgqDY&ab_channel=ProgrammingDimension       
    
    ; Checar se alguma tecla foi clicada
    MOV AH, 01H
    INT 16H
    JZ END_CHANGE_OPTION ; ZF = 0 => nao clicado | ZF = 1 => clicado
    
    ; Checar qual botao foi clicado (AL = ASCII Char)
    MOV AH, 00H                                      
    INT 16H
       
    CMP AX, 4800H ; Cima 
    JE CHANGE_OPTION_ACTION
    
    CMP AX, 5000H ; Baixo
    JE CHANGE_OPTION_ACTION
    JMP END_CHANGE_OPTION
                   
    ; Se qualquer tecla (pra cima ou pra baixo) foi clicada, apenas inverta o bot?o selecionado
    CHANGE_OPTION_ACTION:
    XOR AX,AX
    MOV AL, TITLE_SELECTED_BTN
    CMP AL, 1
    JE CHANGE_OPTION_TO_2      ; Se era 1, troca pra 2
    JMP CHANGE_OPTION_TO_1     ; Se era 2, troca pra 1 
    
    CHANGE_OPTION_TO_1:
        MOV TITLE_SELECTED_BTN, 1
        JMP REFRESH_OPTION_BTN
    CHANGE_OPTION_TO_2:             
        MOV TITLE_SELECTED_BTN, 2
        JMP REFRESH_OPTION_BTN 
    
    REFRESH_OPTION_BTN:    
    call TITLE_BTNS             ; Renderiza novamente os botões em tela
 
    END_CHANGE_OPTION:   
    POP AX
    RET               
CHANGE_OPTION endp         
             
proc SET_CARACTERE_A_SER_MOSTRADO
    CMP TITLE_SELECTED_BTN, BL
    JNE ESPACO_EM_BRANCO
    CMP BH, 1
    JNE PARENTESES_2
    MOV DL, '['
    JMP FIM_TESTE_BOTAO
    PARENTESES_2:
    MOV DL, ']'
    JMP FIM_TESTE_BOTAO
    ESPACO_EM_BRANCO:
    MOV DL, ' '
    FIM_TESTE_BOTAO:
    RET
endp SET_CARACTERE_A_SER_MOSTRADO       

; DH = Qual linha; BL = 1 | 2 - Botao atual
proc SHOW_TITLE_PARENTHESIS
    PUSH DX            
    PUSH AX
    
    MOV DL, 14
    CALL SET_CURSOR
    
    MOV BH, 1      
    CALL SET_CARACTERE_A_SER_MOSTRADO
    MOV AL, 03H
    INT 21H
              
    MOV DL, 24
    CALL SET_CURSOR
                 
    MOV BH, 2                
    CALL SET_CARACTERE_A_SER_MOSTRADO
    MOV AL, 03H
    INT 21H
             
    POP AX
    POP DX
    RET
endp SHOW_TITLE_PARENTHESIS  

proc TITLE_BTNS     
    ; Posiciona o cursor na posi??o para escrever o primeiro bot?o             
    mov DL, 17
    mov DH, 19
                                
    MOV BL, 1
    CALL SHOW_TITLE_PARENTHESIS
                        
    call SET_CURSOR
    mov DX, offset START_BTN_1
    mov AH, 09H
    int 21H   
                                                                  
    ; Posiciona o cursor na posi??o para escrever o segundo bot?o
    mov DL, 17
    mov DH, 21
                           
    MOV BL, 2
    CALL SHOW_TITLE_PARENTHESIS
    
    call SET_CURSOR
    mov DX, offset START_BTN_2
    mov AH, 09H
    int 21H
                   
    ret
endp
       
; DH = Y (linha). DL = X (coluna). CH = Cor
proc DRAW_ONE_GHOST
    PUSH AX
    PUSH DS
    PUSH BX     
    PUSH CX
            
    MOV CL, DL  ; Salva o conteudo de DL em CL como um auxiliar pois a multiplicacao destroi o conteudo de DX
            
    XOR AX, AX
    MOV AL, DH   ; Salva o conteudo de DH (linha a ser printada) para multiplicacao
    MOV BX, 320  ; Precisa ser um registrador para o comando MUL
    MUL BX       ; multiplica por 320 para encontrar a posição de memória na qual o pixel deve ser posto       
    
    XOR BX, BX
    MOV BL, CL  ; Move a linha para BL (com BX zerado) para poder somar registradores de 16 bits (soma equivalente)
    ADD AX, BX  ; Soma com a coluna para encontrar a posição correta   
    
    MOV BX, AX  ; Salva a posicao exata do pixel em BX
     
    MOV AX, VIDEO_BUFFER_SEGMENT ; Seta o segmento de buffer de vídeo (precisa do AX para essa atribuicao)
    MOV DS, AX                          
                                                                                  
    MOV [BX], CH ; Poe o pixel na posicao correta com a cor correspondente    
          
    POP CX
    POP BX
    POP DS
    POP AX
    ret
DRAW_ONE_GHOST endp
        
proc DRAW_INITIAL_SCREEN_GHOSTS   
    PUSH DX
           
    MOV CH, 0CH ; VERMELHO_CLARO
    MOV DL, 10H
    MOV DH, 10H
    
    call DRAW_ONE_GHOST
    
    POP DX
    ret
DRAW_INITIAL_SCREEN_GHOSTS endp
         
proc INITIAL_SCREEN    
    MOV AL, IS_GAME_TITLE_RENDERED
    CMP AL, 0            
    JNE START_NEXT_OPERATION ; Se já renderizou o titulo, não renderize novamente
    
    call SHOW_TITLE                           
    call TITLE_BTNS      
                                                                                 
    call DRAW_INITIAL_SCREEN_GHOSTS
                                                                                 
    START_NEXT_OPERATION:  
    call CHANGE_OPTION  
    
    ret
INITIAL_SCREEN endp
           
inicio: 
    mov AX, @DATA
    mov DS, AX  
    mov ES, AX 
    
    ;call TEXT_MODE   

    mov AX, 13h  
    int 10h            
        
    LOOP_GAME:             
    CALL INITIAL_SCREEN    
    MOV AL, SHOULD_END_GAME
    CMP AL, 1 
    JNE LOOP_GAME
                
    mov AH, 4CH
    int 21H
    
end inicio          