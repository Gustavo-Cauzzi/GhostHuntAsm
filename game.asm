.model small

.stack 100H

.data     
    CR db 10
    LF db 13    
    
    ; Debug
    DEACTIVATE_INITIAL_SCREEN_MOVMENT DB 0   ; 0 | 1 - As vezes buga os botoes do menu 
    DEACTIVATE_GAME_TIMER db 1  ; Desativa o delay de milissegundos e o timer do jogo 
    GAME_END_TIME DB 0          ; 0 - 60 -> Caso for necess?rio diminuir o timer do jogo a fim de testes
    DEBUG_MOVMENT_OFFSET DB 0   ; 0 | 1 - Mostra as bounderies/offsets dos movimentos que s?o utilizados para detectar colis?o
                                ; com o final da tela
    
    ; Game flags
    CURRENT_SCREEN db 2 ; 1 | 2 | 3 = Start | Game | End
             
    GAME_TITLE db '        ________               __ ',10,13
               db '       / ____/ /_  ____  _____/ /_',10,13
               db '      / / __/ __ \/ __ \/ ___/ __/',10,13
               db '     / /_/ / / / / /_/ (__  ) /_  ',10,13
               db '     \____/_/_/_/\____/____/\__/  ',10,13
               db '           / / / /_  ______  / /_ ',10,13
               db '          / /_/ / / / / __ \/ __/ ',10,13
               db '         / __  / /_/ / / / / /_   ',10,13
               db '        /_/ /_/\__,_/_/ /_/\__/   ',10,13           
    GAME_TITLE_LEN EQU $-GAME_TITLE
                            
    END_GAME_TEXT db '          _____            __    ',10,13
                  db '         / __(_)_ _    ___/ /__  ',10,13
                  db '        / _// /    \  / _  / -_) ',10,13
                  db '       /_/ /_/_/_/_/  \_,_/\__/  ',10,13
                  db '        __ / /__  ___ ____       ',10,13
                  db '       / // / _ \/ _ `/ _ \      ',10,13
                  db '       \___/\___/\_, /\___/      ',10,13
                  db '                /___/            ',10,13
    END_GAME_TEXT_LEN EQU $-END_GAME_TEXT
                  
    GHOST_MASK db '   xxxxxx   ',' '
               db '  xxxxxxxx  ',' '
               db ' xxxxxxxxxx ',' '
               db 'xxx  xx  xxx',' '
               db 'xxx  xx  xxx',' '
               db 'xxxxxxxxxxxx',' '
               db 'xxxxxxxxxxxx',' '
               db 'xxxxxxxxxxxx',' '
               db 'xxx xxxx xxx',' '
               db ' x   xx   x  '
    GHOST_MASK_WIDTH_LEN db 13
    GHOST_MASK_HEIGHT_LEN db 10  
    
    HUNTER_MASK db '   xxxxxxxx ',' '
                db '  xxxxxxxxxx',' '
                db ' xx  xxxxxx ',' '
                db 'xxxxxxxxx   ',' '
                db 'xxxxxx      ',' '
                db 'xxxxxx      ',' '
                db 'xxxxxxxx    ',' '
                db ' xxxxxxxxx  ',' '
                db '  xxxxxxxxxx',' '
                db '   xxxxxxxx  '
    HUNTER_MASK_WIDTH_LEN db 13
    HUNTER_MASK_HEIGHT_LEN db 10            
                               
    SCORE_TEXT db 'Score: $'
    
    ; Constantes Gerais
    VIDEO_BUFFER_SEGMENT dw 40960 ; A000H
    FFF0_CONST DW 65535 ; FFF0
    PRETO    db 0
    VERDE    db 0AH ;2
    CIANO    db 0BH ;3
    VERMELHO db 0CH ;4
    MAGENTA  db 0DH ;5
    AMARELO  db 0EH ;6 (MARROM)
    DELAY_LEAST_SIGNIFICANT_PART DW 41248 ;A120H (para o delay de 500ms)
    
    ; Tela inicial
    START_IS_GAME_TITLE_RENDERED db 0 ; 0 ou 1
    TITLE_SELECTED_BTN db 1 ; 1 ou 2     
    START_BTN_1 db 'Jogar$'
    START_BTN_2 db 'Sair$'  
    SHOULD_END_GAME db 0 ; 0 | 1
    START_MOTION_OFFSET DW 282
    START_GOING_RIGHT DB 1
    
    ; Tela de fim de jogo
    END_BTN_1 db 'Voltar$'
    
    ; Tela do jogo
    SHOULD_RENDER_LINE_AGAIN db 0 ; 0 = no, outro valor = qual linha deve ser recarregada
    IS_GAME_FIRST_RENDER DB 1
    IS_LINE_GOING_TO_THE_RIGHT DB 0, 0, 0, 0
    LINE_OFFSET DW 0, 0, 0, 0
    INITIAL_POSITION_GAME_LINES DB 0, 20, 35, 50 ; A primeira que ? igual ao offset 0 n serve pra nada
    NUMBER_OF_GHOSTS_IN_LINE DB 0, 0, 0, 0
    MAX_OF_NUMBER_OF_GHOSTS_IN_LINE DB 0, 2, 3, 4
    GAME_SCORE_TEXT DB 'SCORE: '         
    GAME_SCORE_TEXT_LEN EQU $-GAME_SCORE_TEXT
    GAME_SCORE_QUANTITY_TEXT DB '0000' 
    GAME_SCORE_QUANTITY_TEXT_LEN EQU $-GAME_SCORE_QUANTITY_TEXT   
    GAME_SCORE_QUANTITY_TEXT_BKP DB '0000$' ; Para restaurar quando o jogo ? recome?ado
    GAME_SCORE dw 0  
    GAME_SECOND_QUANTITY_ELAPSED db 0
    GAME_SECOND_QUANTITY_ELAPSED_OBJ db 17
    GAME_TIMER db 60
    GAME_TIMER_TEXT db '60'
    GAME_TIMER_TEXT_LEN EQU $-GAME_TIMER_TEXT  
    GAME_TIMER_TEXT_BKP db '60$' ; Para restaurar quando o jogo ? recome?ado  
    GAME_TIMER_DESC db 'Tempo: '
    GAME_TIMER_DESC_LEN EQU $-GAME_TIMER_DESC
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
        

; Escreve na tela um inteiro sem sinal    
; de 16 bits armazenado no registrador AX
ESC_UINT16 proc 
    push AX      ; Salvar registradores utilizados na proc
    push BX
    push CX
    push DX 
       
    mov BX, 10   ; divis?es sucessivas por 10
    mov cx, 4
      
LACO_DIV:
    xor DX, DX   ; zerar DX pois o dividendo ? DXAX
    div BX       ; divis?o para separar o d?gito em DX
    
    push DX      ; empilhar o d?gito
     
    loop LACO_DIV ; enquanto AX diferente de 0 salte para LACO_DIV
       
    mov cx, 4    
 LACO_ESCDIG:   
    pop DX       ; desempilha o d?gito    
    add DL, '0'  ; converter o d?gito para ASCII
    call ESC_CHAR               
    loop LACO_ESCDIG ; decrementa o contador de d?gitos
    
    pop DX       ; Restaurar registradores utilizados na proc
    pop CX
    pop BX
    pop AX
    ret     
endp   
    
; --------------------------------------------------------------  
; Mostra o t?tulo na tela inicial         
SHOW_TITLE proc
    push DX
    push CX
    push BX
    push AX     
                      
    mov AL, 0 ; https://i.pinimg.com/736x/9d/4a/3b/9d4a3b8bece01eb5aef7a78eb0d7be93.jpg
    mov BH, 0 ; N?mero da p?gina
    mov BL, 2 ; Cor => 02 = Fundo preto e texto verde
    
    mov DH, 4              ; Linha
    mov DL, 0              ; Coluna
    mov CX, GAME_TITLE_LEN     ; Tamanho
    mov BP, offset GAME_TITLE  ; Endere?o
    
    ; https://en.wikipedia.org/wiki/INT_10H
    mov AH, 13H 
    int 10H    
                   
    MOV START_IS_GAME_TITLE_RENDERED, 1
                   
    pop AX
    pop BX
    pop CX
    pop DX    
    ret
endp 

; AX
RAND_NUM_0_9 proc
    push ax
    push cx
    
    mov ah, 00h  ; interrupts to get system time        
    int 1ah      ; CX:DX now hold number of clock ticks since midnight      

    mov  ax, dx
    xor  dx, dx
    mov  cx, 10    
    div  cx       ; here dx contains the remainder of the division - from 0 to 9
    
    pop cx
    pop ax
    ret
endp
  
SET_GLOBAL_VARIABLES_OF_MAIN_GAME PROC    
    push dx
    PUSH CX
    push ax
    push bx
    PUSH DI
    PUSH SI
    push es
    
    MOV CX, 4
    MOV SI, OFFSET GAME_SCORE_QUANTITY_TEXT_BKP
    MOV DI, OFFSET GAME_SCORE_QUANTITY_TEXT
    REP MOVSB
    
    MOV CX, 2
    MOV SI, OFFSET GAME_TIMER_TEXT_BKP
    MOV DI, OFFSET GAME_TIMER_TEXT
    REP MOVSB
    
    MOV GAME_SCORE, 0  
    MOV GAME_TIMER, 60
    MOV IS_GAME_FIRST_RENDER, 1
    
    pop es
    POP SI
    POP DI
    pop bx
    pop ax
    POP CX
    pop dx
    RET
ENDP

SHOW_END_GAME_TEXT proc
    push DX
    push CX
    push BX
    push AX  
    
    mov AL, 0 
    mov BH, 0 
    mov BL, 02h ; Cor => 02 = Fundo preto e texto verde
    
    mov DH, 4              ; Linha
    mov DL, 0              ; Coluna
    mov CX, END_GAME_TEXT_LEN      ; Tamanho
    mov BP, offset END_GAME_TEXT   ; Endere?o
    
    ; https://en.wikipedia.org/wiki/INT_10H
    mov AH, 13H 
    int 10H            
  
    pop AX
    pop BX
    pop CX
    pop DX  
    ret
endp

; Escuta o clique na tela inicial
CHANGE_OPTION proc
    PUSH AX
    PUSH BX
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
    
    CMP AX, 1C0DH ; Enter
    JNE END_CHANGE_OPTION      ; Se n?o for o Enter, n?o importa, termine a proc
    
    MOV BL, TITLE_SELECTED_BTN ; Caso for o Enter que foi clicado, olhe o bot?o selecionado para determinar a a??o
    CMP BL, 1                  ; Checa se "Jogar" esta selecionado
    JNE CLOSE_GAME_OPTION      ; Se n?o for esse o bot?o selecionado, ? o "Sair"
    
    MOV CURRENT_SCREEN, 2      ; Muda para o jogo (A??o do bot?o "Jogar") 
    CALL RESET_GAME_SCREEN
    CALL SET_GLOBAL_VARIABLES_OF_MAIN_GAME
    JMP END_CHANGE_OPTION
 
    CLOSE_GAME_OPTION:
    MOV SHOULD_END_GAME, 1
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
    call TITLE_BTNS             ; Renderiza novamente os bot?es em tela
 
    END_CHANGE_OPTION:  
    POP BX 
    POP AX
    RET               
endp

CHECK_END_GAME_ACTIONS proc
    PUSH AX
    XOR AX, AX
                            
    ; https://www.stanislavs.org/helppc/int_16.html 
    ; https://www.youtube.com/watch?v=8dYRlRjgqDY&ab_channel=ProgrammingDimension       
    
    ; Checar se alguma tecla foi clicada
    MOV AH, 01H
    INT 16H
    JZ NO_END_SCREEN_OPERATION ; ZF = 0 => nao clicado | ZF = 1 => clicado
    
    ; Checar qual botao foi clicado (AL = ASCII Char)
    MOV AH, 00H                                      
    INT 16H
    
    CMP AX, 1C0DH                    ; Enter
    JNE NO_END_SCREEN_OPERATION      ; Se n?o for o Enter, n?o importa, termine a proc
    
    MOV CURRENT_SCREEN, 1           ; Muda para a tela de inicio 
    CALL RESET_GAME_SCREEN
    
    NO_END_SCREEN_OPERATION:   
    POP AX
    ret
endp         
             
SET_CARACTERE_A_SER_MOSTRADO proc
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
endp       

; DH = Qual linha; BL = 1 | 2 - Botao atual
SHOW_TITLE_PARENTHESIS proc
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
endp   

TITLE_BTNS proc     
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

END_GAME_BUTTONS proc
    PUSH DX
    PUSH AX
    
    mov TITLE_SELECTED_BTN, 1 ; Finge que o bot?o selecionado na end screen ? o mesmo do menu (s? para poder reutilizar o SHOW_TITLE_PARENTHESIS)

    ; Posiciona o cursor na posi??o para escrever o primeiro bot?o             
    mov DL, 16
    mov DH, 19
                                
    MOV BL, 1
    CALL SHOW_TITLE_PARENTHESIS
                        
    call SET_CURSOR
    mov DX, offset END_BTN_1
    mov AH, 09H
    int 21H   
    
    POP AX
    POP DX    
    ret
endp
 
SHOW_END_SCREEN_SCORE proc
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX    

    MOV DH, 15
    MOV DL, 11
    CALL SET_CURSOR
    
    XOR AX, AX
    MOV DX, offset SCORE_TEXT
    MOV AH, 09H
    INT 21H    
    
    mov AL, 0 
    mov BH, 0 
    mov BL, 2 ; Cor => 2 = Verde
    
    MOV DH, 15
    MOV DL, 20
    CALL SET_CURSOR
    mov CX, GAME_SCORE_QUANTITY_TEXT_LEN  ; Tamanho
    mov BP, OFFSET GAME_SCORE_QUANTITY_TEXT  ; Endere?o
            
    mov AH, 13H 
    int 10H    
    
    POP DX
    POP CX
    POP BX
    POP AX
    ret
endp

; Seta o DS para o buffer de v?deo        
SET_DS_VIDEO_BUFFER proc 
    PUSH AX         
    MOV AX, VIDEO_BUFFER_SEGMENT ; Seta o segmento de buffer de v?deo (precisa do AX para essa atribuicao)
    MOV DS, AX      
    POP AX
    ret
endp     
                   
SET_DS_NORMAL_SEGMENT proc
    PUSH AX    
    mov AX, @DATA   
    mov DS, AX      
    POP AX
    ret
endp
       
; DX = offset da mascara.
; CL = Comprimento da mascara
; CH = Altura da mascara
; AL = Cor      
; BX = Endere?o inicial do segmento A000H
DRAW_MASK proc
    PUSH DS  
    PUSH CX   
    PUSH DX
    PUSH AX
    PUSH DI
                
    call SET_DS_VIDEO_BUFFER
                                        
    MOV AH, CH ; Altura da mascara eh controlado abaixo por AH 
    XOR CH, CH                          
    MOV DI, CX ; Auxiliar do comprimento da linha
    
    MASK_LINE_RENDER_LOOP:
        MASK_RENDER_LOOP:
            PUSH BX 
            MOV BX, DX
            MOV BX, ES:[BX]  ; DX nao acessa a memoria
            CMP BL, ' '   ; compara o proximo char da mascara                   
            POP BX
            JE NEXT_CHAR_MASK_RENDER ; Se for um espaco na mascara, pule pro proximo pixel
            
            MOV [BX], AL 
            
            NEXT_CHAR_MASK_RENDER:  
            INC BX
            INC DX
            LOOP MASK_RENDER_LOOP     
         DEC AH                                                                         
         MOV CX, DI    ; Reinicia a contagem de comprimento da linha para o proximo loop
         
         ADD BX, 320 
         SUB BX, CX
         CMP AH, 0
         JNE MASK_LINE_RENDER_LOOP

    SKIP_MASK_RENDER:
    POP DI
    POP AX
    POP DX
    POP CX
    POP DS
    RET
endp
 
; DX = X (coluna). 
; CH = Cor
; DI = 1 = fantasma | 2 = hunter
; AX = Y (Linha)
DRAW proc
    PUSH AX
    PUSH DS     
    PUSH CX 
    PUSH DX
    PUSH BX
    PUSH DI
             
    PUSH CX     ; Salva a cor para usar depois
    MOV CX, DX  ; Salva o conteudo de DX em CX como um auxiliar pois a multiplicacao destroi o conteudo de DX
            
    MOV BX, 320  ; Precisa ser um registrador para o comando MUL
    MUL BX       ; multiplica por 320 para encontrar a posi??o de mem?ria na qual o pixel deve ser posto       
    
    XOR BX, BX
    ADD AX, CX  ; Soma com a coluna para encontrar a posi??o correta   
    
    MOV BX, AX  ; Salva a posicao exata do pixel em BX                        
              
    POP CX
    MOV AL, CH  ; Cor para AL
    CMP DI, 1
    JE DRAW_GHOST_OPTIONS
    
    MOV DX, offset HUNTER_MASK         
    MOV CL, HUNTER_MASK_WIDTH_LEN               
    MOV CH, HUNTER_MASK_HEIGHT_LEN
    JMP DRAW_SELECTED
    
    DRAW_GHOST_OPTIONS:
    MOV DX, offset GHOST_MASK         
    MOV CL, GHOST_MASK_WIDTH_LEN               
    MOV CH, GHOST_MASK_HEIGHT_LEN
    JMP DRAW_SELECTED
    
    DRAW_SELECTED:
    call DRAW_MASK 
          
    POP DI 
    POP BX 
    POP DX
    POP CX
    POP DS
    POP AX
    ret
endp

RESET_GAME_SCREEN proc
    push AX
    mov START_IS_GAME_TITLE_RENDERED, 0 
    mov IS_GAME_FIRST_RENDER, 1
    mov START_MOTION_OFFSET, 282
    
    mov AX, 13h  ; Seta o modo para v?deo de novo para limpar a tela automaticamente 
    int 10h            
            
    pop AX
    ret
endp
        
DRAW_INITIAL_SCREEN_GHOSTS proc   
    PUSH DX
               
    MOV AX, 120 ; ALTURA DE TODOS
    MOV DX, 75
    
    MOV DI, 2 ; Desenhar o ca?ador
    MOV CH, AMARELO
    call DRAW
    
    MOV DI, 1 ; Desenhar apenas fantasmas a partir de agora
    
    MOV CH, VERDE
    ADD DX, 38
    call DRAW
                       
    MOV CH, CIANO
    ADD DX, 38
    call DRAW
    
    MOV CH, VERMELHO
    ADD DX, 38
    call DRAW 
    
    MOV CH, MAGENTA
    ADD DX, 38
    call DRAW
    
    POP DX
    ret
endp
       
INVERT_BL_1_0 PROC

    CMP BL, 1
    JE INVERT_BL_TO_0
    JNE INVERT_BL_TO_1
    
    INVERT_BL_TO_0: 
    MOV BL, 0
    JMP END_INVERT_BL
    
    INVERT_BL_TO_1:
    MOV BL, 1

    END_INVERT_BL:
    RET
ENDP
  
MOVE_START_LINE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV DX, 120
    MOV BL, START_GOING_RIGHT
    XOR BH, BH
    MOV DI, BX
    CALL MOVE_LINE
    
    CMP BL, 1
    JE MOVE_START_LINE_RIGHT
    JNE MOVE_START_LINE_LEFT
    ;---------
    
    MOVE_START_LINE_RIGHT:
    MOV AX, START_MOTION_OFFSET
    INC AX
    MOV START_MOTION_OFFSET, AX
    JMP MOVE_START_LINE_END
    
    MOVE_START_LINE_LEFT:
    MOV AX, START_MOTION_OFFSET
    DEC AX
    MOV START_MOTION_OFFSET, AX
    JMP MOVE_START_LINE_END
    
    ;---------
    MOVE_START_LINE_END:
    
    CMP BL, 1
    JE START_TEST_OFFSET_ENDING_RIGHT
    JNE START_TEST_OFFSET_ENDING_LEFT
    ;------------- 
    
    START_TEST_OFFSET_ENDING_RIGHT:
    CMP AX, 320
    JNE START_TEST_OFFSET_ENDING_END
    
    CALL INVERT_BL_1_0
    MOV AX, 70
    MOV START_MOTION_OFFSET, AX
    MOV START_GOING_RIGHT, BL
    JMP START_TEST_OFFSET_ENDING_END
    
    
    START_TEST_OFFSET_ENDING_LEFT:
    CMP AX, 0
    JNE START_TEST_OFFSET_ENDING_END
    
    CALL INVERT_BL_1_0
    MOV AX, 250
    MOV START_MOTION_OFFSET, AX
    MOV START_GOING_RIGHT, BL
    JMP START_TEST_OFFSET_ENDING_END
    
    ;------------- 
    START_TEST_OFFSET_ENDING_END:
    CALL DEBUG_START_OFFSET
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ENDP

INITIAL_SCREEN proc
    MOV AL, START_IS_GAME_TITLE_RENDERED
    CMP AL, 0            
    JNE START_NEXT_OPERATION ; Se j? renderizou o titulo, n?o renderize novamente
    
    call SHOW_TITLE                           
    call TITLE_BTNS      
                                                                                 
    call DRAW_INITIAL_SCREEN_GHOSTS
    
    START_NEXT_OPERATION:  
    call CHANGE_OPTION   
    
    MOV AL, DEACTIVATE_INITIAL_SCREEN_MOVMENT
    CMP AL, 1
    JE END_INITIAL_SCREEN_RENDER
    
    CALL MOVE_START_LINE   
    CALL GAME_DELAY 
    
    END_INITIAL_SCREEN_RENDER:
    ret
endp
    
; BX = Gerar de 1 ate? BX
GENERATE_RANDOM_NUMBER proc
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AH, 00h  ; Interrupcao para obter a hora do sistema    
    INT 1AH      ; CX:DX tem quantos clocks houve desde a meia noite

    mov  ax, dx
    xor  dx, dx
    mov  cx, 10    
    div  cx
    
    MOV AX, DX
    MUL BX
    MOV BX, 10
    DIV BX
    INC AX
            
    POP DX
    POP CX
    POP BX
    ret
endp
  
GAME_SCREEN_RENDER_HUNTER proc
    PUSH DX
    PUSH DI
    PUSH CX
    
    MOV AX, 187
    MOV DX, 154
    
    MOV DI, 2 ; Desenhar o ca?ador
    MOV CH, AMARELO
    call DRAW

    POP CX
    POP DI
    POP DX
    ret
endp
  
; DI = LINHA
; BX => Quantos no m?ximo em cada linha
GET_NUMBER_OF_GHOSTS_IN_ROW proc
    MOV BX, OFFSET MAX_OF_NUMBER_OF_GHOSTS_IN_LINE
    MOV BX, [BX + DI]
    XOR BH, BH
    ret
endp

; DI = LINHA
; CH => COR
GET_COLOR_OF_GHOSTS_IN_ROW proc
    cmp DI, 1
    je SET_COLOR_OF_GHOSTS_IN_ROW_1
    cmp DI, 2
    je SET_COLOR_OF_GHOSTS_IN_ROW_2
    cmp DI, 3
    je SET_COLOR_OF_GHOSTS_IN_ROW_3
    jmp END_COLOR_OF_GHOSTS_IN_ROW
    
    SET_COLOR_OF_GHOSTS_IN_ROW_1:
    mov CH, MAGENTA
    jmp END_COLOR_OF_GHOSTS_IN_ROW
    
    SET_COLOR_OF_GHOSTS_IN_ROW_2:
    mov CH, CIANO
    jmp END_COLOR_OF_GHOSTS_IN_ROW
    
    SET_COLOR_OF_GHOSTS_IN_ROW_3:
    mov CH, VERDE
    jmp END_COLOR_OF_GHOSTS_IN_ROW
    
    END_COLOR_OF_GHOSTS_IN_ROW:
    ret
endp

GET_START_POSITION_OF_LINE PROC
    MOV BX, OFFSET INITIAL_POSITION_GAME_LINES
    MOV BL, [BX + DI]
    XOR BH, BH
    
    RET
ENDP   

; DI = Linha atual
GET_GAME_LEFT_RIGHT PROC
    PUSH AX
    PUSH BX
    MOV BX , 2 ; Gerar um numero aleatorio ate 2 (1 ou 2)
    CALL GENERATE_RANDOM_NUMBER ; AX tem 1 ou 2
    mov bx, offset IS_LINE_GOING_TO_THE_RIGHT
    cmp ax, 1
    je SET_INITIAL_POSITION_START
    JMP SET_INITIAL_POSITION_END
    
    SET_INITIAL_POSITION_START:
    MOV DX, 0
    mov [BX+DI], 1
    JMP END_INITIAL_POSITION_SETTER
    SET_INITIAL_POSITION_END:
    MOV DX, 308
    mov [BX+DI], 0
                                   
    END_INITIAL_POSITION_SETTER:
    POP BX
    POP AX
    RET    
ENDP  

REFRESH_SCORE_STRING proc
    push AX      
    push BX
    push CX
    push DX 
    PUSH DI
       
    MOV AX, GAME_SCORE
    mov BX, 10   ; divis?es sucessivas por 10
    MOV CX, 4
      
    LACO_DIV_SCORE:
        xor DX, DX   ; zerar DX pois o dividendo ? DXAX
        div BX       ; divis?o para separar o d?gito em DX
        
        add DL, '0'  ; converter o d?gito para ASCII
        PUSH BX
        MOV BX, OFFSET GAME_SCORE_QUANTITY_TEXT
        MOV DI, CX
        DEC DI
        MOV [BX + DI], DL
        POP BX
        
        LOOP LACO_DIV_SCORE 
        
    POP DI
    pop DX
    pop CX
    pop BX
    pop AX
    ret
endp

RENDER_SCORE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH BP    
    
    mov AL, 0 ; https://i.pinimg.com/736x/9d/4a/3b/9d4a3b8bece01eb5aef7a78eb0d7be93.jpg
    mov BH, 0 ; N?mero da p?gina
    mov BL, 15 ; Cor => 15 = Branco
    
    mov DH, 0              ; Linha
    mov DL, 0              ; Coluna
    mov CX, GAME_SCORE_TEXT_LEN     ; Tamanho
    mov BP, offset GAME_SCORE_TEXT  ; Endere?o
                                            
    mov AH, 13H 
    int 10H    
    
    CALL REFRESH_SCORE_STRING
    
    mov AL, 0 
    mov BH, 0 
    mov BL, 2 ; Cor => 2 = Verde
    
    mov DH, 0              ; Linha
    mov DL, 7              ; Coluna
    mov CX, GAME_SCORE_QUANTITY_TEXT_LEN  ; Tamanho
    mov BP, OFFSET GAME_SCORE_QUANTITY_TEXT  ; Endere?o
            
    mov AH, 13H 
    int 10H    
            
    POP BP
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ENDP        

SET_NEXT_GHOST_POSITION PROC
    PUSH AX
    MOV AX, 100
    CMP DX, AX
    JC INCREMENT_20_TO_POSITION
    JMP DECREMENT_20_TO_POSITION
       
    INCREMENT_20_TO_POSITION: 
    ADD DX, 32
    JMP END_INCREMENT_POSITION  
    DECREMENT_20_TO_POSITION:
    SUB DX, 32
    END_INCREMENT_POSITION:
    POP AX
    RET
ENDP

; Di = qual linha (1, 2, 3)
GAME_SCREEN_RENDER_GHOSTS_ROW proc
    PUSH DI
    
    CALL GET_NUMBER_OF_GHOSTS_IN_ROW ; BX tem o numero m?ximo de 
    CALL GET_COLOR_OF_GHOSTS_IN_ROW  ; CH tem a cor
    CALL GENERATE_RANDOM_NUMBER      ; AX tem o valor de fantasmas a ser gerado na linha
    ; DEC AX ; Tem algum problema que esta gerando um a mais do que o m?ximor
    CALL GET_START_POSITION_OF_LINE  ; BX tem a altura da linha atual 
    CALL GET_GAME_LEFT_RIGHT         ; DX tem a posicao inicial da coluna a ser printada
    
    PUSH BX
    MOV BX, offset NUMBER_OF_GHOSTS_IN_LINE
    MOV [BX+DI], AX
    POP BX
    
    PUSH BX
    MOV BX, OFFSET IS_LINE_GOING_TO_THE_RIGHT
    MOV SI, [BX + DI]
    POP BX
    CALL RECALCULATE_GAME_LINE_OFFSET
    
    GHOSTS_ROW_LOOP:
        PUSH AX
        MOV AX, BX
        
        MOV DI, 1 ; fantasma
        call DRAW
        POP AX
                  
        CALL SET_NEXT_GHOST_POSITION
                  
        DEC AX
        CMP AX, 0
        JNE GHOSTS_ROW_LOOP
    POP DI
    ret
endp

; Recebe em DI qual linha deve ser rerenderizada (Se DI = 0, todas ser?o renderizadas. Usado no render inicial da tela do jogo)
RENDER_GAME_GHOSTS_LINE PROC
    CMP DI, 0 
    JNE RENDER_SPECIFIC_LINE
    
    inc DI
    call GAME_SCREEN_RENDER_GHOSTS_ROW
    inc DI
    call GAME_SCREEN_RENDER_GHOSTS_ROW
    inc DI
    call GAME_SCREEN_RENDER_GHOSTS_ROW
    JMP END_RENDER_GAME_GHOSTS_LINE
    
    RENDER_SPECIFIC_LINE:
    call GAME_SCREEN_RENDER_GHOSTS_ROW
    
    END_RENDER_GAME_GHOSTS_LINE:
    RET
ENDP

; DX = linha (humanamente falando) a ser movida
; DI = 1 = DIREITA, 0 = ESQUERDA

MOVE_LINE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES
         
    MOV CX, 320
    MOV AX, DX
    MUL CX
    MOV BX, AX
    
    MOV CX, 10 ; 10 Linhas para mover
    
    CMP DI, 1
    JE MOVE_LINE_TO_THE_RIGHT
    JMP MOVE_LINE_TO_THE_LEFT
    
    MOVE_LINE_TO_THE_RIGHT:
    LOOP_MOVE_PIXELS_LINHA_RIGHT:
        MOV ES, VIDEO_BUFFER_SEGMENT    
        MOV AX, ES:[BX] ; AX = Primeiro pixel
        INC BX
        
        PUSH CX
        MOV CX, 319
        LOOP_MOVE_PIXELS_COLUNA_RIGHT:
            MOV DX, ES:[BX] 
            MOV ES:[BX], AX
            MOV AX, DX
            INC BX
            LOOP LOOP_MOVE_PIXELS_COLUNA_RIGHT
        POP CX
        LOOP LOOP_MOVE_PIXELS_LINHA_RIGHT
        JMP MOVE_LINE_END
        
    MOVE_LINE_TO_THE_LEFT:
    ADD BX, 3200
    LOOP_MOVE_PIXELS_LINHA_LEFT:
        MOV ES, VIDEO_BUFFER_SEGMENT    
        MOV AX, ES:[BX] ; AX = Primeiro pixel
        DEC BX
        
        PUSH CX
        MOV CX, 319
        LOOP_MOVE_PIXELS_COLUNA_LEFT:
            MOV DX, ES:[BX] 
            MOV ES:[BX], AX
            MOV AX, DX
            DEC BX
            LOOP LOOP_MOVE_PIXELS_COLUNA_LEFT
        POP CX
        LOOP LOOP_MOVE_PIXELS_LINHA_LEFT
        JMP MOVE_LINE_END
    
    MOVE_LINE_END:
    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ENDP  

GAME_DELAY proc  
    push cx
    push dx
    push ax
    
    mov al, DEACTIVATE_GAME_TIMER
    cmp al, 1
    je SKIP_GAME_DELAY
    
    ;; delay de 500ms (muito lento)
    ;xor cx, cx
    ;mov dx, DELAY_LEAST_SIGNIFICANT_PART ; parte baixa
    ;mov cx, 0007h ; parte alta
    ;mov ah, 86h
    ;int 15h
    
    xor cx, cx
    mov dx, 0C350h ; 50000 microsegundos
    mov ah, 86h
    int 15h ; http://vitaly_filatov.tripod.com/ng/asm/asm_026.13.html
    
    SKIP_GAME_DELAY:
    pop ax
    pop dx
    pop cx
    ret
GAME_DELAY endp 
      
DOUBLE_DI proc
    push ax
    push dx   
     
    xor dx, dx
    xor ax, ax
    mov ax, di
    mov dx, 2
    mul dx
    mov di, ax  
    
    pop dx
    pop ax
    ret
endp     

; DX = linha (humanamente falando) a ser movida
; DI = numero da linha a ser movida
MOVE_GAME_LINE PROC
    PUSH BX
    PUSH AX
    push cx
    PUSH DI

    MOV BX, OFFSET LINE_OFFSET
    push di
    call DOUBLE_DI
    MOV AX, [BX+DI]                          
    pop di
    
    MOV BX, OFFSET IS_LINE_GOING_TO_THE_RIGHT       
    push cx  
    MOV CL, [BX+DI]
    xor ch, ch
    MOV SI, cx
    pop cx
    
    PUSH DI
    MOV DI, SI
    CALL MOVE_LINE
    POP DI
    
    CMP SI, 1
    JE GOING_TO_THE_RIGHT_TESTS
    JMP GOING_TO_THE_LEFT_TESTS
    
    GOING_TO_THE_RIGHT_TESTS:
    ADD AX, 2
    CMP AX, 320
    JC END_MOVE_GAME_LINE
    sub AX, 2
    
    CALL INVERT_GHOST_LINE_DIRECTION
    CALL RECALCULATE_GAME_LINE_OFFSET
    MOV BX, OFFSET LINE_OFFSET ; Busca o valor novo
    push di
    call DOUBLE_DI
    MOV AX, [BX+DI]                          
    pop di
    JMP END_MOVE_GAME_LINE
    
    
    GOING_TO_THE_LEFT_TESTS:
    sub AX, 2
    CMP AX, 2
    JnC END_MOVE_GAME_LINE
   
    add AX, 2
    CALL INVERT_GHOST_LINE_DIRECTION
    CALL RECALCULATE_GAME_LINE_OFFSET    
    MOV BX, OFFSET LINE_OFFSET ; Busca o valor novo
    push di
    call DOUBLE_DI
    MOV AX, [BX+DI]                          
    pop di
    
    JMP END_MOVE_GAME_LINE
    
    END_MOVE_GAME_LINE:       
    MOV BX, OFFSET LINE_OFFSET
    push di
    call DOUBLE_DI
    MOV [BX+DI], ax                          
    pop di
    
    POP DI
    POP AX
    pop cx
    POP BX
    RET
ENDP

; DI = LINHA  
; SI => NOVO VALOR
INVERT_GHOST_LINE_DIRECTION PROC
    PUSH BX
    PUSH AX

    MOV BX, OFFSET IS_LINE_GOING_TO_THE_RIGHT
    XOR AX, AX
    MOV AL, [BX+DI]
    CMP AL, 1
    JE INVERT_GHOST_LINE_DIRECTION_TO_0
    JMP INVERT_GHOST_LINE_DIRECTION_TO_1
    
    INVERT_GHOST_LINE_DIRECTION_TO_0:
    mov al, 0
    MOV [BX+DI], al
    MOV SI, 0
    JMP END_INVERT_GHOST_LINE_DIRECTION
    
    INVERT_GHOST_LINE_DIRECTION_TO_1:
    mov al, 1
    MOV [BX+DI], al
    MOV SI, 1
    
    END_INVERT_GHOST_LINE_DIRECTION:
    
    POP AX
    POP BX
    RET
ENDP

; SI = 0 = AGORA INDO PARA ESQUERDA | 1 = AGORA INDO PARA A DIREITA
; DI = Linha de fantasmas do jogo
RECALCULATE_GAME_LINE_OFFSET PROC
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, OFFSET NUMBER_OF_GHOSTS_IN_LINE
    XOR CX, CX
    MOV CL, [BX+DI]
    CMP SI, 0
    JE CHANGE_RECALCULATE_GAME_LINE_OFFSET_LEFT
    JMP CHANGE_RECALCULATE_GAME_LINE_OFFSET_RIGHT
    
    CHANGE_RECALCULATE_GAME_LINE_OFFSET_LEFT:
    MOV DX, 308 ; 320 - 12
    dec cx
    cmp cx, 0
    je END_RECALCULATE_GAME_LINE_OFFSET
    
    CALCULATE_OFFSET_FROM_THE_LEFT:
        SUB DX, 32 
        LOOP CALCULATE_OFFSET_FROM_THE_LEFT
    JMP END_RECALCULATE_GAME_LINE_OFFSET
    
    CHANGE_RECALCULATE_GAME_LINE_OFFSET_RIGHT:
    MOV DX, 12 ; Sempre vai ter pelo menos um, e esse um n?o adiciona o espa?amento entre fantasmas, por isso s? 12
    dec cx
    cmp cx, 0
    je END_RECALCULATE_GAME_LINE_OFFSET
    CALCULATE_OFFSET_FROM_THE_RIGHT:
    ADD DX, 32
        LOOP CALCULATE_OFFSET_FROM_THE_RIGHT
    JMP END_RECALCULATE_GAME_LINE_OFFSET

    END_RECALCULATE_GAME_LINE_OFFSET:  
    MOV BX, OFFSET LINE_OFFSET      
    PUSH DI
    CALL DOUBLE_DI
    MOV [BX+DI], DX
    POP DI
    
    POP DX
    POP CX
    POP BX
    RET
ENDP

; Debug ----------- \/
GAME_DEBUG_OFFSET PROC
    push ax
    push bx
    push cx
    PUSH DX
    push di
    push es
    
    MOV AL, DEBUG_MOVMENT_OFFSET
    CMP AL, 0
    JE SKIP_GAME_DEBUG_OFFSET
    
    mov di, 1
    LOOP_RED_SQUARE_OFFSET:         
        push di
        call double_di
        mov bx, offset LINE_OFFSET
        mov dx, [bx + di]
        pop di
        mov es, VIDEO_BUFFER_SEGMENT
        mov bx, offset INITIAL_POSITION_GAME_LINES  
        xor ax, ax
        mov al, [bx + di]
        push dx
        mov cx, 140h
        mul cx
        pop dx
        add ax, dx
        xor dx, dx
        dec bx
        mov dl, preto
        mov es:[bx], dl
        inc bx
        mov dl, vermelho   
        mov bx, ax
        mov es:[bx], dl
        inc bx
        mov es:[bx], dl
        inc bx
        mov es:[bx], dl
        add bx, 13dh
        mov dl, preto
        mov es:[bx], dl
        inc bx
        mov dl, vermelho  
        mov es:[bx], dl
        inc bx
        mov es:[bx], dl
        inc bx
        mov es:[bx], dl
        add bx, 13dh
        mov dl, preto
        mov es:[bx], dl
        inc bx
        mov dl, vermelho  
        mov es:[bx], dl
        inc bx
        mov es:[bx], dl
        inc bx
        mov es:[bx], dl
        
        inc di
        cmp di, 4
        jne LOOP_RED_SQUARE_OFFSET
        
    SKIP_GAME_DEBUG_OFFSET:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    RET
ENDP

DEBUG_START_OFFSET PROC
    PUSH AX 
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH ES        
    
    MOV AL, DEBUG_MOVMENT_OFFSET
    CMP AL, 0
    JE SKIP_DEBUG_START_OFFSET
          
    MOV ES, VIDEO_BUFFER_SEGMENT
 
    MOV AX, 120
    MOV BX, 320
    MUL BX
                                
    MOV DX, START_MOTION_OFFSET
    ADD AX, DX
    MOV AX, BX
    
    MOV CX, 3
    LOOP_OFFSET_BLOCK_START:   
        PUSH CX
        DEC BX
        MOV CX, 3
        MOV DL, PRETO
        MOV ES:[BX], DL
        INC BX
        LOOP_OFFSET_START:
            MOV DL, VERMELHO
            MOV ES:[BX], DL
            INC BX
            LOOP LOOP_OFFSET_START
        POP CX
        LOOP LOOP_OFFSET_BLOCK_START
        
             
            
    SKIP_DEBUG_START_OFFSET:
    POP ES 
    POP DX
    POP CX
    POP BX
    POP AX
    ENDP
ENDP
; Debug /\

UPDATE_GAME_TIMER PROC
    push ax
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    
    MOV AL, DEACTIVATE_GAME_TIMER
    CMP AL, 1
    JE END_CHANGE_GAME_SECOND_QUANTITY_ELAPSED
    
    mov al, GAME_SECOND_QUANTITY_ELAPSED
    mov ah ,GAME_SECOND_QUANTITY_ELAPSED_OBJ
    cmp al, ah
    JE A_SECOND_JUST_PASSED
    JMP INCREMENT_GAME_SECOND_QUANTITY
    
    A_SECOND_JUST_PASSED:
    XOR AH, AH
    MOV AL, GAME_TIMER
    DEC AL
    MOV GAME_TIMER, AL
    MOV BX, 10
    
    XOR DX, DX
    DIV BX
    ADD DL, '0' 
    PUSH DX   
    
    XOR DX, DX 
    XOR AH, AH
    DIV BX
    ADD DL, '0' 
    PUSH DX
    
    MOV BX, OFFSET GAME_TIMER_TEXT    
    POP DX
    MOV [BX], DL
    POP DX
    MOV [BX + 1], DL 
    
    MOV GAME_SECOND_QUANTITY_ELAPSED, 0
    
    JMP END_CHANGE_GAME_SECOND_QUANTITY_ELAPSED
    
    INCREMENT_GAME_SECOND_QUANTITY:
    inc al
    mov GAME_SECOND_QUANTITY_ELAPSED, al
    
    END_CHANGE_GAME_SECOND_QUANTITY_ELAPSED:
    POP DI
    POP DX
    POP CX
    POP BX
    pop ax
    RET
ENDP

RENDER_GAME_TIMER PROC
    push ax
    push bx
    push cx
    push dx
    
    mov AL, 0 ; https://i.pinimg.com/736x/9d/4a/3b/9d4a3b8bece01eb5aef7a78eb0d7be93.jpg
    mov BH, 0 ; N?mero da p?gina
    mov BL, 15 ; Cor => 15 = Branco
    
    mov DH, 0              ; Linha
    mov DL, 31              ; Coluna
    mov CX, GAME_TIMER_DESC_LEN     ; Tamanho
    mov BP, offset GAME_TIMER_DESC  ; Endere?o
                                            
    mov AH, 13H 
    int 10H    
    
    mov AL, 0 
    mov BH, 0 
    mov BL, 2 ; Cor => 2 = Verde
    
    mov DH, 0              ; Linha
    mov DL, 38              ; Coluna
    mov CX, GAME_TIMER_TEXT_LEN  ; Tamanho
    mov BP, OFFSET GAME_TIMER_TEXT  ; Endere?o
            
    mov AH, 13H 
    int 10H       
    
    pop dx
    pop cx
    pop bx
    pop ax
    RET
ENDP

MANIPULATE_SCORE_WITH_ARROW PROC
    PUSH AX
    PUSH BX
    
    ; Checar se alguma tecla foi clicada
    MOV AH, 01H
    INT 16H
    JZ END_MANIPULATE_SCORE_WITH_ARROW ; ZF = 0 => nao clicado | ZF = 1 => clicado
    
    ; Checar qual botao foi clicado (AL = ASCII Char)
    MOV AH, 00H                                      
    INT 16H
       
    CMP AX, 4800H ; Cima 
    JNE END_MANIPULATE_SCORE_WITH_ARROW
    
    MOV BX, 100
    CALL GENERATE_RANDOM_NUMBER
    MOV BX, AX
    MOV AX, GAME_SCORE
    ADD AX, BX
    MOV GAME_SCORE, AX
    
    END_MANIPULATE_SCORE_WITH_ARROW:
    POP BX
    POP AX
    RET
ENDP

CHECK_IF_TIMER_HAS_ENDED PROC
    PUSH AX
    PUSH BX
    
    MOV BL, GAME_END_TIME
    
    MOV AL, GAME_TIMER
    CMP AL, BL
    JE GAME_HAS_ENDED
    JMP END_CHECK_IF_TIMER_HAS_ENDED
    
    GAME_HAS_ENDED:
    MOV CURRENT_SCREEN, 3
    CALL RESET_GAME_SCREEN
    
    END_CHECK_IF_TIMER_HAS_ENDED:
    
    POP BX
    POP AX
    RET
ENDP

GAME_SCREEN proc
    PUSH DI
    
    cmp IS_GAME_FIRST_RENDER, 0
    je IT_IS_NOT_THE_FIRST_RENDER
    
    ; Primeiro render
    call GAME_SCREEN_RENDER_HUNTER
    xor DI, DI
    call RENDER_GAME_GHOSTS_LINE
    MOV IS_GAME_FIRST_RENDER, 0
    ; Primeiro render
    
    IT_IS_NOT_THE_FIRST_RENDER:    
    cmp SHOULD_RENDER_LINE_AGAIN, 0
    JE DO_NOT_NEED_TO_RE_RENDER_ANY_LINE
    
    XOR BX, BX
    MOV BL, SHOULD_RENDER_LINE_AGAIN
    MOV DI, BX ; SHOULD_RENDER_LINE_AGAIN tem a linha a ser renderizada novamente
    CALL RENDER_GAME_GHOSTS_LINE
    
    DO_NOT_NEED_TO_RE_RENDER_ANY_LINE:    
    MOV DI, 1
    MOVE_LINES_LOOP:
        CALL GET_START_POSITION_OF_LINE  ; BX tem a altura da linha atual conforme DI
        MOV DX, BX
        CALL MOVE_GAME_LINE
        INC DI
        CMP DI, 4
        JNE MOVE_LINES_LOOP

    CALL RENDER_SCORE
    CALL RENDER_GAME_TIMER
        
    CALL GAME_DELAY
    CALL UPDATE_GAME_TIMER
    CALL CHECK_IF_TIMER_HAS_ENDED
    CALL GAME_DEBUG_OFFSET
    
    CALL MANIPULATE_SCORE_WITH_ARROW
    POP DI
    ret
endp
           
END_SCREEN proc
    call SHOW_END_GAME_TEXT
    call END_GAME_BUTTONS
    call SHOW_END_SCREEN_SCORE
    call CHECK_END_GAME_ACTIONS
    
    ret
endp
       
inicio: 
    mov AX, @DATA
    mov DS, AX  
    mov ES, AX   

    mov AX, 13h  ; Video mode
    int 10h        
             
    LOOP_GAME:             
        MOV AL, CURRENT_SCREEN
        CMP AL, 1    
        JNE TEST_TELA_2
        CALL INITIAL_SCREEN    
        JMP END_LOOP_GAME
        
        TEST_TELA_2:       
        CMP AL, 2  
        JNE TEST_TELA_3
        CALL GAME_SCREEN
        JMP END_LOOP_GAME
        
        TEST_TELA_3:   
        CMP AL, 3  
        JNE END_LOOP_GAME
        CALL END_SCREEN
        
        END_LOOP_GAME:
        MOV AL, SHOULD_END_GAME
        CMP AL, 1 
        
        JNE LOOP_GAME
                
    mov AH, 4CH
    int 21H
    
end inicio          