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
    PRETO    db 0
    VERDE    db 0AH ;2
    CIANO    db 0BH ;3
    VERMELHO db 0CH ;4
    MAGENTA  db 0DH ;5
    AMARELO  db 0EH ;6 (MARROM)
    
    ; Game flags
    CURRENT_SCREEN db 3 ; 1 | 2 | 3 = Start | Game | End
    
    ; Tela inicial
    START_IS_GAME_TITLE_RENDERED db 0 ; 0 ou 1
    TITLE_SELECTED_BTN db 1 ; 1 ou 2     
    START_BTN_1 db 'Jogar$'
    START_BTN_2 db 'Sair$'  
    SHOULD_END_GAME db 0 ; 0 | 1
    
    ; Tela de fim de jogo
    END_BTN_1 db 'Voltar$'
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
    mov CX, title1_len     ; Tamanho
    mov BP, offset title1  ; Endere?o
    
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
    PUSH DX    

    MOV DH, 15
    MOV DL, 11
    CALL SET_CURSOR
    
    XOR AX, AX
    MOV DX, offset SCORE_TEXT
    MOV AH, 09H
    INT 21H    
    
    POP DX
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
            ; SER? QUE N TEM QUE VOLTAR O DS?
            call SET_DS_NORMAL_SEGMENT  
            PUSH BX 
            MOV BX, DX
            MOV BX, [BX]  ; DX nao acessa a memoria
            CMP BL, ' '   ; compara o proximo char da mascara                   
            POP BX
            call SET_DS_VIDEO_BUFFER
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
 
    POP DI
    POP AX
    POP DX
    POP CX
    POP DS
    RET
endp
             
; DH = Y (linha). 
; DL = X (coluna). 
; CH = Cor
; DI = 1 = fantasma | 2 = hunter
DRAW proc
    PUSH AX
    PUSH DS     
    PUSH CX 
    PUSH DX
    PUSH BX
    PUSH DI
           
    MOV CL, DL  ; Salva o conteudo de DL em CL como um auxiliar pois a multiplicacao destroi o conteudo de DX
            
    XOR AX, AX
    MOV AL, DH   ; Salva o conteudo de DH (linha a ser printada) para multiplicacao
    MOV BX, 320  ; Precisa ser um registrador para o comando MUL
    MUL BX       ; multiplica por 320 para encontrar a posi??o de mem?ria na qual o pixel deve ser posto       
    
    XOR BX, BX
    MOV BL, CL  ; Move a linha para BL (com BX zerado) para poder somar registradores de 16 bits (soma equivalente)
    ADD AX, BX  ; Soma com a coluna para encontrar a posi??o correta   
    
    MOV BX, AX  ; Salva a posicao exata do pixel em BX                        

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
    
    mov AX, 13h  ; Seta o modo para v?deo de novo para limpar a tela automaticamente 
    int 10h            
            
    pop AX
    ret
endp
        
DRAW_INITIAL_SCREEN_GHOSTS proc   
    PUSH DX
               
    MOV DH, 120 ; ALTURA DE TODOS
    MOV DL, 75
    
    MOV DI, 2 ; Desenhar o ca?ador
    MOV CH, AMARELO
    call DRAW
    
    MOV DI, 1 ; Desenhar apenas fantasmas a partir de agora
    
    MOV CH, VERDE
    ADD DL, 38
    call DRAW
                       
    MOV CH, CIANO
    ADD DL, 38
    call DRAW
    
    MOV CH, VERMELHO
    ADD DL, 38
    call DRAW 
    
    MOV CH, MAGENTA
    ADD DL, 38
    call DRAW
    
    POP DX
    ret
endp
         
INITIAL_SCREEN proc
    MOV AL, START_IS_GAME_TITLE_RENDERED
    CMP AL, 0            
    JNE START_NEXT_OPERATION ; Se j? renderizou o titulo, n?o renderize novamente
    
    call SHOW_TITLE                           
    call TITLE_BTNS      
                                                                                 
    call DRAW_INITIAL_SCREEN_GHOSTS
                                                                                 
    START_NEXT_OPERATION:  
    call CHANGE_OPTION  
    
    ret
endp
           
GAME_SCREEN proc
    mov CURRENT_SCREEN, 3

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