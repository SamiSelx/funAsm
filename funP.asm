
Data SEGMENT      
    
    TDec    dw  200 dup(?)      ; Tableau pour stocker les nombres d?cimaux (dd car on a valeur maximal 99999)
    taille  db  ?               ; Variable pour stocker la taille du tableau
    defaultTaille db 5          ; Taille par d?faut si la saisie est incorrecte
    NewTDec     dw  200 dup(?)  ; Tableau pour stocker les r?sultats divis?s par 16    
    
    tabAffichage    db  200 dup(?)  ; tableau pour l'affichage NewTDec en Hexadecimal
    chaine  db  50,?,50 dup(?)      ; tableau contient nombre saisie
    tab db  '0123456789ABCDEF'      ; tableau pour convertir un nombre en hexadecimal utilsant "xlat"
    cmpt db  0                      ; indice de la table

    ; Messages
    mesSizeErr  db  "La taille saisie est erron?e. $"
    mesDigitErr db  0ah,0dh,"Taille incorrecte. ",0ah,0dh,"$"
    mesInput    db  0ah,0dh,"Veuillez saisir la taille du Tableau : $"
    mesElement  db  0ah,0dh,"Veuillez saisir un element du tableau : $"
    mesSuccess  db  0ah,0dh,"Saisie termin?e avec succ?s.$"
    mesNewTDec  db  0ah,0dh,"Tableau NewTDec (en Hexad?cimal) :",0ah,0dh,"$" 
    
Data ENDS  


;===================================================;
;           DECLARATION DE LA PILE                  ;
;===================================================;
                        
; declaration de la pile pour eviter l'utilisation de pile systeme  

Ma_Pile SEGMENT STACK
    
    dw  256 dup(?)              ; Definition de la pile
    tos label   word
     
Ma_Pile ENDS    

;===================================================;

Code SEGMENT
    assume  CS:Code, DS:Data    

;===================================================;
;           DECLARATION DE PROCEDURES               ;
;===================================================; 

; Procedure pour saisir la taille du tableau

SaisieTailleChaine PROC NEAR
    mov CX, 3                   ; Nombre de tentatives autoris?es
saisie_taille:
    mov DX, OFFSET mesInput     ; passage par registre   
    call AfficheMessage

    mov AH, 01h                 ; Saisie d'un caractere
    int 21h
    sub AL, '0'                 ; Convertir en valeur numerique
    
    ; Verifier si la taille est inf?rieure a 1
    cmp AL, 0                   
    jbe taille_invalide
    cmp AL, 9
    ja taille_invalide
    
    ; Stocker la taille valide (taille compris entre 1 et 9)
    mov taille, Al
    
    ; Quitter procedure              
    RET

taille_invalide:
    mov DX, OFFSET mesSizeErr   ; Affichage du message d'erreur
    call AfficheMessage
    
    loop saisie_taille           

    ; Apres 3 tentatives
    mov Al, defaultTaille  
    mov taille, Al 
    
    RET
SaisieTailleChaine ENDP                          
;===================================================;
; Procedure pour lecture d'un chaine de caractere
lireChaine  PROC    NEAR
    mov ah,0ah
    int 21h
    RET
lireChaine  ENDP    
;===================================================;  

;===================================================;
; Procedure pour saisir les elements du tableau
SaisieChaineNum PROC NEAR  
    
    xor cx,cx 
    ; Nombre d'elements a saisir
    mov Cl, taille                                            
    
    mov di,0             
    
saisie_elements:
    mov DX, OFFSET mesElement   ; Affichage du message
    call AfficheMessage
    
    
    lea dx,chaine
    call lireChaine
    
    
    ; Verifier la validite de la chaine numerique saisie
    mov SI, DX                  ; Pointeur sur la cha?ne saisie
    mov BX, 0                   ; Compteur de chiffres numeriques

    count_digits:
    mov AL, [SI + 2]                ; Lire le caractere
    cmp AL, 0DH                 ; Verifier la fin de la cha?ne
    je end_count_digits

    cmp AL, '0'
    jb invalid_digit            ; Caractere non numerique
    cmp AL, '9'
    ja invalid_digit            ; Caractere non numerique

    inc SI
    inc BX
    jmp count_digits

invalid_digit:
    mov DX, OFFSET mesDigitErr  ; Affichage du message d'erreur
    call AfficheMessage
    jmp saisie_elements

end_count_digits:
    cmp BX, 3                   ; Verifier si la taille
    jb erreur                
    cmp BX, 5                   
    ja erreur
   
    ;sinon remplire dans table TDec

    ; convertir un chaine de caractere au nombre et le mettre poid fort dans DX et Faible de AX
    call convertChNum
    mov word ptr TDec[di],ax
    mov word ptr TDec[di + 2],dx
    add di,4     
    
    loop saisie_elements  
    
    RET                 

erreur:
    mov DX, OFFSET mesDigitErr  ; Affichage du message d'erreur
    call AfficheMessage
    jmp saisie_elements


SaisieChaineNum ENDP
;===================================================;
                                                        
                                                        
;===================================================;
convertChNum    PROC    NEAR 
    ; sauvegarder contexts
    push bx
    push si
    push cx   
    mov si,2
    xor ax,ax 
    xor dx,dx 
    xor bx,bx
    mov cx,10 
    
convert: 
    mov bl,chaine[si] 
    cmp bl,0DH
    jz fin  
    ; convertir caractere au nombre
    sub bl,30h
    
    ; multiple nombre fois et l'ajoute a nombre precedent
    mul cx
    add ax,bx
    adc dx,0
    inc si
     
    jmp convert
    
    
fin: pop cx
     pop si 
     pop bx
    
    RET
convertChNum    ENDP    

;===================================================;
                   
; Procedure pour diviser chaque element de TDec par 16                   
Division2_4 PROC NEAR
    xor cx,cx
    mov Cl, taille              
    lea DI, NewTDec             ; Pointeur vers le tableau NewTDec
    mov si,0
divide_loop:      
    mov  ax,word ptr TDec[si]
    mov dx,word ptr TDec[si+2]
    call diviseNum
    mov word ptr NewTDec[si],ax
    mov word ptr NewTDec[si+2],dx             

    add si,4                                        
    loop divide_loop
    
                
    RET
Division2_4 ENDP                                     

;===================================================;
                                                      
;===================================================;

diviseNum   PROC    NEAR
    push cx
    
    mov cx,4
    ; Effectuez un decalage vers la droite (SHR) sur DX:AX pour diviser par 16 (on fait ca 4 fois)
divise:                                    

    ; Decalage de 1 bit vers la droite de DX
    shr dx, 1                                           
    
    ; Decalage de 1 bit vers la droite de AX avec retenu (retenu de DX mettre dans poid fort de AX)
    rcr ax, 1         
    
    loop divise 
    
    pop cx
    
    RET
diviseNum   ENDP    

;===================================================;


;===================================================;               

; Affiche le tableau NewTDec en hexadecimal
AfficheTDecHex  PROC    NEAR        
    
    mov DX, OFFSET mesNewTDec   ; Affichage du message
    call AfficheMessage 
    
    xor cx,cx
    mov Cl, taille              ; Nombre d'elements a afficher
    mov si,0            

display_loop:
    
    mov ax, word ptr NewTDec[SI]
    
    ; passage par registre (AX)                
    call convertirElementEnHexa            

    add si,4                     
    loop display_loop
    
    ; mettre dernier indice dans bx       
    xor bx,bx
    mov bl,cmpt
    
    ; ajoute a la fin du tableau tabAffichage le caractere "$"
    mov tabAffichage[bx],24h
    ; passage par registre (DX)
    lea dx,tabAffichage
    call AfficheMessage
             
    RET
AfficheTDecHex ENDP

;===================================================;
  
;===================================================;

convertirElementEnHexa   PROC    NEAR
    
    ; sauvegarder contexts
    push cx
    push bx
    push dx
    push si      
    
    ; mettre offset tab dans BX pour utilisation de l'instruction xlat
    lea bx,tab                  
    
    xor dx,dx
    mov dl,cmpt
    mov si,dx
    mov dx,ax
    mov ch,12
    
    
    ; boucle pour obtien la valeur dans AX en hexa et le charger dans le tableau tabAffichage 
    
repDec:
    mov ax,dx
    mov cl,ch
    shr ax,cl
    and ax,0FH
    xlat
    mov tabAffichage[si],al
    inc si
    sub ch,4
    cmp cl,0  
    
    jnz repDec 
    
    ; Ajouter caractere 'H' a la fin
    mov tabAffichage[si],48h          
    
    ; sauter la ligne pour l'affichage
    mov tabAffichage[si + 1],0ah
    mov tabAffichage[si + 2],0dh
    
    ; sauvegarder le compteur de la  dans la variable cmpt
    add si,3
    mov bx,si
    mov cmpt,bl
    
    pop si
    pop dx
    pop bx
    pop cx
             
    
    RET
convertirElementEnHexa   ENDP    

;===================================================;

;===================================================;

; Procedure pour afficher un message a l'ecran
AfficheMessage PROC NEAR
    mov AH, 09h                 ; Affichage d'une chaine
    int 21h
    RET
AfficheMessage ENDP

;===================================================;                                
                               
;===================================================; 
;               PROGRAMME PRINCIPAL                 ;
;===================================================;

Start:
    mov AX, Data              
    mov DS, AX

    mov AX, Ma_Pile            
    mov SS, AX
    LEA SP, tos                 

    call SaisieTailleChaine     
    call SaisieChaineNum  

    
    
     
    call Division2_4
    call AfficheTDecHex
      

    mov DX, OFFSET mesSuccess   
    call AfficheMessage
    
    
    ; press key to continue..
    mov ah,08h
    int 21h

    mov AH, 4Ch                 
    int 21h

Code ENDS
END Start

;===================================================;