;************* kernal code *****************
[org 0x000]
[bits 16]

    [SEGMENT .text]

        mov ax, 0x0100                  ;location where kernal is loaded
        mov ds, ax
        mov es, ax

        cli
        mov ss, ax                      ;stact segment
        mov sp, 0xFFFF                  ;stack pointer at 64k limit
        sti

        push dx
        push es
        xor ax, ax                       ;setting ax to zero
        mov es, ax
        cli
        mov word [es:0x21*4], _int0x21   ; setup interrupt service
        mov [es:0x21*4+2], cs
        sti
        pop es
        pop dx

        mov si, strHeader                ; load message
        mov al, 0x01                     ; request sub-service 0x01
        int 0x21                         ; display message

        call _shell                         ; await keypress using BIOS
        int 0x19                         ; reboot

    _int0x21:
        _int0x21_ser0x01:       ;service 0x01
        cmp al, 0x01            ;see if service 0x01 wanted
        jne _int0x21_end        ;goto next check (now it is end)
        
        _int0x21_ser0x01_start:
        lodsb                   ; load next character
        or  al, al              ; test for NUL character
        jz  _int0x21_ser0x01_end
        mov ah, 0x0E            ; BIOS teletype
        mov bh, 0x00            ; display page 0
        mov bl, 0x07            ; text attribute
        int 0x10                ; invoke BIOS
        jmp _int0x21_ser0x01_start
        _int0x21_ser0x01_end:
        jmp _int0x21_end

        _int0x21_end:
        iret

    _shell:
        _shell_begin:
            call _display_end1            ;move to next line
        
            call _display_prompt          ;display prompt

            call _commands                ; get user's command

            call _split_command           ;split command into sub-string

            _command_empty:               ; check if there is no command
                mov si, strCmd_0
                cmp BYTE[si], 0x00        ; check command is equal to null
                jne _cmd_ver             ;if not null call next function
                jmp _cmd_done             ; if null then finish

;=======================display version===============================================

            _cmd_ver:                     ;display version
                    mov si, strCmd_0
                    mov di, cmdVer
                    mov cx, 4
                    repe cmpsb            ; compare if user command is equal to 'var'
                    jne _cmd_info         ; if not equal then call next function

                    call _display_end1
                    mov si, strOSName     ; display version
                    mov al, 0x01
                    int 0x21

                    call _display_space   ; display version
                    mov si, txtVer
                    mov al, 0x01
                    int 0x21
                    call _display_space   ; display version
                    mov si, strMajorVer
                    mov al, 0x01
                    int 0x21

                    mov si, strMinorVer   ; display version
                    mov al, 0x01
                    int 0x21

                    jmp _cmd_done

;====================display hardware informtion =====================================

            _cmd_info:
                mov si, strCmd_0
                mov di, cmdInfo
                mov cx, 5
                repe cmpsb                ; compare if user command is equal to 'info'
                jne _cmd_help             ; if not equal then call next function

                call _display_end1
                
                call _cmd_VendorID        ; display CPU vendor id
                call _cmd_ProcType        ; display CPU processor type
                call _cmd_SerialNo        ; display CPU serial nomber
               ; call _cmd_features        ; display CPU features

                call _display_end1
                jmp _cmd_done

                    _cmd_VendorID:        ;=======vendor ID==============
                        call _display_end1
                        mov si, strVendorID
                        mov al, 0x01
                        int 0x21

                        mov eax, 0
                        cpuid                    ; call cpuid command
                        mov [strcpuid],ebx      ; load last string
                        mov [strcpuid+4],edx     ; load middle string
                        mov [strcpuid+8],ecx     ; load first string

                        call _display_space

                        mov si, strcpuid         ;print CPU vender ID
                        mov al, 0x01
                        int 0x21
                        ret

                    _cmd_ProcType:         ;==========processor type============
                        call _display_end1
                        mov si, strProcType
                        mov al, 0x01
                        int 0x21

                    
                        mov eax, 0x80000002		   ; get first part of the brand
                        cpuid
                        mov  [strcputype], eax
                        mov  [strcputype+4], ebx
                        mov  [strcputype+8], ecx
                        mov  [strcputype+12], edx

                        mov eax, 0x80000003
                        cpuid                      ; call cpuid command
                        mov [strcputype+16], eax
                        mov [strcputype+20], ebx
                        mov [strcputype+24], ecx
                        mov [strcputype+28], edx

                        mov eax, 0x80000004
                        cpuid                      ; call cpuid command
                        mov [strcputype+32], eax
                        mov [strcputype+36], ebx
                        mov [strcputype+40], ecx
                        mov [strcputype+44], edx

                        call _display_space

                        mov si, strcputype           ;print processor type
                        mov al, 0x01
                        int 0x21
                        ret

                    _cmd_SerialNo:           ;=======serial number==========
                        call _display_end1
                        mov si, strSerNo
                        mov al, 0x01
                        int 0x21

                        mov eax, 3	             	; get first part of the brand
                        cpuid
                        and edx, 1
                        ;mov  [strcpusno], eax
                        ;mov  [strcpusno+4], ebx
                        mov  [strcpusno], ecx
                        mov  [strcpusno+32], edx
                        


                        mov si, strcpusno           ;print processor type
                        mov al, 0x01
                        int 0x21
                        ret

                    ; _cmd_features:       ;============== features ==============
                    ;     call _display_end1
                    ;     mov si, strFeature
                    ;     mov al, 0x001
                    ;     int 0x21

                    ;     mov eax, 0
                    ;     cpuid
                    ;     mov [strcpufeature], edx

                    ;     mov eax, 00000001h

;========================help menu=============================

            _cmd_help:
                mov si, strCmd_0
                mov di, cmdHelp
                mov cx, 5
                repe cmpsb                     ; check if command is equal to 'help'
                jne _cmd_exit                  ; if it is not then call exit function


                call _display_end1
                mov si, strHelpMsg1            ; display help message one
                mov al, 0x01
                int 0x21

                call _display_end1
                mov si, strHelpMsg2            ; display help message two
                mov al, 0x01
                int 0x21

                call _display_end1
                mov si, strHelpMsg3            ; display help message three
                mov al, 0x01
                int 0x21


;=========================exit==================================

            _cmd_exit:
                call _display_end1
                mov si, strCmd_0
                mov di, cmdExit
                mov cx, 5
                repe cmpsb                      ; check if command is equal to 'exit'
                jne _cmd_error                  ; if it is not, then call next function

                je _shell_end                   ; exit from shell

            _cmd_error:
                call _display_end1
                mov si, cmdErrorMsg             ; command is incorrect
                mov al, 0x01
                int 0x21

            _cmd_done:
                jmp _shell_begin
            
            _shell_end:
                ret
;=======================================================================
;============================commands===================================

    _commands:
        mov BYTE[charCount], 0x00         ; set count
        mov di, strUserCmd

        _commands_begin:
            mov ah, 0x10                  ; get char
            int 0x16

            cmp al, 0x00                  ; check if enter extended key (ex:F1,F2,HOME...)
            je _ex_key                    ; if equal jump to _ex_key function

            cmp al, 0xE0                  ;check if enter new extended key
            je _ex_key                    ; if equal jump to _ex_key function

            cmp al, 0x08                  ; check if enter backspace
            je _back_key                  ; if equal jump to this function

            cmp al, 0x0D                  ; check if enter button pressed
            je _enter_key                 ; if equal jump to this function

            mov bh, [cmdMaxLen]           ; check if greater than max length
            mov bl, [charCount]           
            cmp bh, bl
            je _commands_begin            ; if it is equal then call back

            mov [di], al                  ;char add to buffer
            inc di                        ;increment buffer pointer
            inc BYTE[charCount]           ;increment count

            mov ah, 0X0E                  ;display charecter
            mov bl, 0x07
            int 0x10
            jmp _commands_begin

        _ex_key:                          ;extended key
            jmp _commands_begin

        _back_key:
            mov bh, 0x00                  ;check if count = 0
            mov bl, [charCount]
            cmp bh, bl
            je  _commands_begin           ;if count is zero then call back
            
            dec BYTE [charCount]          ;decrement count
            dec di

            ;check if beginning of line
            mov ah, 0x03                  ;read cursor position
            mov bh, 0x00
            int 0x10

            cmp dl, 0x00
            jne _move_back                  ; if not equal call _move_back
            dec dh
            mov dl, 79
            mov ah, 0x02
            int 0x10

            mov ah, 0x09                  ; display without moving cursor
            mov al, ' '
            mov bh, 0x00
            mov bl, 0x07
            mov cx, 1                     ; times to display
            int 0x10
            jmp _commands_begin           ; jump begin

         _move_back:
            mov ah, 0x0E                  ; BIOS teletype acts on backspace
            mov bh, 0x00
            mov bl, 0x07
            int 0x10
            mov ah, 0x09                  ; display without moving cursor
            mov al, ' '
            mov bh, 0x00
            mov bl, 0x07
            mov cx, 1                     ; times to display
            int 0x10
            jmp _commands_begin           ; jump begin

            _enter_key:
            mov BYTE [di], 0x00
            ret
;==========================================================================
;======================= slipt commands ===================================

    _split_command:
        mov si, strUserCmd 

        _split_mb0_start:
            cmp BYTE [si], 0x20         ; check space
            je _split_mb0_nb           ; if it is space then next
            jmp _split_mb0_end         ; if there is no space then end this function

            _split_mb0_nb:
                inc si                 ; increment by one
                jmp _split_mb0_start   

            _split_mb0_end:
                mov di, strCmd_0

        _split_1_start:                ; get first string
            cmp BYTE [si], 0x20         ; check space
            je _split_1_end

            cmp BYTE [si], 0x00         ; check null
            je _split_1_end

            mov al, [si]
            mov [di], al
            inc si
            inc di
            jmp _split_1_start

        _split_1_end:
            mov BYTE [di], 0x00

        _split_mb1_start:
            cmp BYTE [si], 0x20         ; check space
            je _split_mb1_nb           
            jmp _split_mb1_end

            _split_mb1_nb:             ; next byte
                inc si
                jmp _split_mb1_start
            
            _split_mb1_end:
                mov di, strCmd_1

        _split_2_start:                ; get second string
            cmp BYTE [si], 0x20          ;check space
            je _split_2_end

            cmp BYTE [si], 0x00          ; check null
            je _split_2_end

            mov al, [si]
            mov [di], al
            inc si
            inc di
            jmp _split_2_start

        _split_2_end:
            mov BYTE[di], 0x00

        _split_mb2_start:
            cmp BYTE[si], 0x20          ; check space
            je _split_mb2_nb            
            jmp _split_mb2_end

            _split_mb2_nb:              ; next byte
                inc si
                jmp _split_mb2_start

            _split_mb2_end:
                mov di, strCmd_2
        ;---------- third string---------

        _split_3_start:                ; get second string
            cmp BYTE [si], 0x20          ;check space
            je _split_3_end

            cmp BYTE [si], 0x00          ; check null
            je _split_3_end

            mov al, [si]
            mov [di], al
            inc si
            inc di
            jmp _split_3_start

        _split_3_end:
            mov BYTE [di], 0x00

        _split_mb3_start:
            cmp BYTE [si], 0x20          ; check space
            je _split_mb3_nb            
            jmp _split_mb3_end

            _split_mb3_nb:              ; next byte
                inc si
                jmp _split_mb3_start

            _split_mb3_end:
                mov di, strCmd_3

        ;---------- fourth string----------


        _split_4_start:                ; get second string
            cmp BYTE [si], 0x20          ;check space
            je _split_4_end

            cmp BYTE [si], 0x00          ; check null
            je _split_4_end

            mov al, [si]
            mov [di], al
            inc si
            inc di
            jmp _split_4_start

        _split_4_end:
            mov BYTE [di], 0x00

        _split_mb4_start:
            cmp BYTE [si], 0x20          ; check space
            je _split_mb4_nb            
            jmp _split_mb4_end

            _split_mb4_nb:              ; next byte
                inc si
                jmp _split_mb4_start

            _split_mb4_end:
                mov di, strCmd_4
        
        ;----------last string --------------

        _split_5_start:                ; get second string
            cmp BYTE [si], 0x20          ;check space
            je _split_5_end

            cmp BYTE [si], 0x00          ; check null
            je _split_5_end

            mov al, [si]
            mov [di], al
            inc si
            inc di
            jmp _split_5_start

        _split_5_end:
            mov BYTE[di], 0x00

        ret
;---------------------------------------------------------------

    _display_space:
        mov ah, 0x0E            ; BIOS teletype
        mov al, 0x20            
        mov bh, 0x00            ; display pade 0
        mov bl, 0x07            ; text attribute
        int 0x10                ; invoke BIOS
        ret

	_display_end1:
        mov ah, 0x0E		; BIOS teletype acts on newline!
        mov al, 0x0D
        mov bh, 0x00
        mov bl, 0x07
        int 0x10

        mov ah, 0x0E		; BIOS teletype acts on linefeed!
        mov al, 0x0A
        mov bh, 0x00
        mov bl, 0x07
        int 0x10
        ret

    _display_prompt:
        mov si, strTag
        mov al, 0x01
        int 0x21
        ret


[SEGMENT .data]
        strHeader db "Welcome to SAN OS, version 0.01", 0x00
        cmdMaxLen db 255          ; maximum lenth of command
        strTag db "SAN>>", 0x00

        strOSName db "SAN", 0x00        ; operation system name
        strMajorVer db "0", 0x00
        strMinorVer db ".01", 0x00
                            ; internal commands
        cmdVer db "ver", 0x00           ; to get version
        cmdInfo db "info", 0x00         ; to get more information
        cmdHelp db "help", 0x00         ; to get help manu
        cmdExit db "exit", 0x00         ; for exit

        txtVer db "version", 0x00 ; message
        cmdErrorMsg db "Command is invalid!", 0x00

        strVendorID db "CPU Vendor ID :", 0x00           ;hardware info
        strProcType db "Processor Type :", 0x00
        strSerNo    db "Processor Serial Number :", 0x00
        strFeature  db "Processor Features :", 0x00

        strHelpMsg1 db "type => ver ,to get version", 0x00                ;help messages
        strHelpMsg2 db "type => info ,to get harware informations", 0x00
        strHelpMsg3 db "type => exit ,for a reboot", 0x00

[SEGMENT .bss]
        strUserCmd resb 256 ; buffers for user commands
        charCount resb 1    ; count of characters
        strCmd_0 rest 256   ; buffers for the command components
        strCmd_1 rest 256
        strCmd_2 rest 256
        strCmd_3 rest 256
        strCmd_4 rest 256
        strcpuid rest 16    ; buffers for hardware details
        strcputype rest 64
        strcpusno rest 64
        strcpufeature rest 4
        curfeat resd 4
;==============================================================
;kernel  code end



