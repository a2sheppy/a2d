        .setcpu "65C02"
        .org $800

        .include "prodos.inc"
        .include "auxmem.inc"
        .include "a2d.inc"

zp_code_stash   := $0020        ; Scratch space used for "call 1000 main" trampoline

start:  jmp     copy2aux

save_stack:.byte   0

;;; Copy $800 through $13FF (the DA) to aux
.proc copy2aux
        tsx
        stx     save_stack
        sta     RAMWRTON
        ldy     #0
src:    lda     start,y         ; self-modified
dst:    sta     start,y         ; self-modified
        dey
        bne     src
        sta     RAMWRTOFF
        inc     src+2
        inc     dst+2
        sta     RAMWRTON
        lda     dst+2
        cmp     #$14
        bne     src
.endproc

;;; Copy the following "call_1000_main" routine to $20
.scope
        sta     RAMWRTON
        sta     RAMRDON
        ldx     #(call_1000_main_end - call_1000_main)
loop:   lda     call_1000_main,x
        sta     zp_code_stash,x
        dex
        bpl     loop
        jmp     call_init
.endscope

.proc call_1000_main
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     L1000
        sta     RAMRDON
        sta     RAMWRTON
        rts
.endproc
call_1000_main_end:

.proc call_init
        ;; run the DA
        jsr     init

        ;; tear down/exit
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     RAMRDOFF
        sta     RAMWRTOFF
        ldx     save_stack
        txs
        rts
.endproc

;;; ==================================================
;;; ProDOS MLI calls

.proc open_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL OPEN, open_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc read_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL READ, read_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc get_file_eof
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL GET_EOF, get_eof_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc set_file_mark
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL SET_MARK, set_mark_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

.proc close_file
        jsr     copy_params_aux_to_main
        sta     ALTZPOFF
        MLI_CALL CLOSE, close_params
        sta     ALTZPON
        jsr     copy_params_main_to_aux
        rts
.endproc

;;; ==================================================

;;; Copies param blocks from Aux to Main
.proc copy_params_aux_to_main
        ldy     #(params_end - params_start + 1)
        sta     RAMWRTOFF
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDOFF
        rts
.endproc

;;; Copies param blocks from Main to Aux
.proc copy_params_main_to_aux
        pha
        php
        sta     RAMWRTON
        ldy     #(params_end - params_start + 1)
loop:   lda     params_start - 1,y
        sta     params_start - 1,y
        dey
        bne     loop
        sta     RAMRDON
        plp
        pla
        rts
.endproc

;;; ----------------------------------------

params_start:
;;; This block gets copied between main/aux

;;; ProDOS MLI param blocks

.proc open_params
        .byte   3               ; param_count
        .addr   pathname        ; pathname
        .addr   $0C00           ; io_buffer
ref_num:.byte   0               ; ref_num
.endproc

default_buffer := $1200

.proc read_params
        .byte   4               ; param_count
ref_num:.byte   0               ; ref_num
buffer: .addr   default_buffer  ; data_buffer
        .word   $100            ; request_count
        .word   0               ; trans_count
.endproc

.proc get_eof_params
        .byte   2               ; param_count
ref_num:.byte   0               ; ref_num
        .byte   0,0,0           ; EOF (lo, mid, hi)
.endproc

.proc set_mark_params
        .byte   2               ; param_count
ref_num:.byte   0               ; ref_num
        .byte   0,0,0           ; position (lo, mid, hi)
.endproc

.proc close_params
        .byte   1               ; param_count
ref_num:.byte   0               ; ref_num
.endproc

pathname:                       ; 1st byte is length, rest is full path
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00

L0945:  .byte   $00
L0946:  .byte   $00
L0947:  .byte   $00
L0948:  .byte   $00
L0949:  .byte   $00
L094A:  .byte   $00,$00,$00,$00

params_end:
;;; ----------------------------------------

        .byte   $00,$00,$00,$00

L0952:  .byte   $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
L095A:  .byte   $00
L095B:  .byte   $FA
L095C:  .byte   $01

.proc line_pos
left:   .word   0
base:   .word   0
.endproc

window_width:  .word   0
window_height: .word   0

L0965:  .byte   $00
L0966:  .byte   $00,$00
L0968:  .byte   $00
L0969:  .byte   $00
L096A:  .byte   $00
L096B:  .byte   $00
L096C:  .byte   $00
L096D:  .byte   $00

track_scroll_delta:
        .byte   $00

fixed_mode_flag:
        .byte   $00   ; 0 = proportional, otherwise = fixed

button_state:
        .byte   $00

.proc mouse_data                ; queried by main input loop
xcoord: .word   0
ycoord: .word   0
elem:   .byte   0
win:    .byte   0
.endproc

        ;; param block used in dead code (resize button handler?)
L0977:  .byte   $64             ; ??? window id again?
xcoord1:.word   0               ; ???
ycoord1:.word   0               ; ???
        .byte   0               ; ???

.proc close_btn                 ; queried after close clicked to see if aborted/finished
state:  .byte   0               ; 0 = aborted, 1 = clicked
        .byte   0,0
.endproc

.proc query_client_params       ; queried after a client click to identify target
xcoord: .word   0
ycoord: .word   0
part:   .byte   0               ; 0 = client, 1 = scroll bar, 2 = ?????
scroll: .byte   0               ; 1 = up, 2 = down, 3 = above, 4 = below, 5 = thumb
.endproc

        ;; param block used in dead code (resize?)
L0986:  .byte   $00
L0987:  .byte   $00

.proc update_scroll_params      ; called to update scroll bar position
type:   .byte   $00             ; 1 = vertical, 2 = horizontal ?
pos:    .byte   $00             ; new position (0...250)
.endproc

;;; Used when dragging vscroll thumb
.proc thumb_drag_params
type:   .byte   0               ; vscroll = 1, hscroll = 2 ??
xcoord: .word   0
ycoord: .word   0
pos:    .byte   0               ; position (0...255)
moved:  .byte   0               ; 0 if not moved, 1 if moved
.endproc

.proc text_string
addr:   .addr   0               ; address
len:    .byte   0               ; length
.endproc

        window_id := $64
.proc window_params
id:     .byte   window_id       ; window identifier
flags:  .byte   2               ; window flags (2=include close box)

L0996:  .word   $1000           ; ???
L0998:  .byte   $00,$C1         ; ???

L099A:  .byte   $20             ; hscroll?
L099B:  .byte   $00,$FF         ; more hscroll?

vscroll_pos:
        .byte   0

        ;; unreferenced
        .byte   $00,$00,$C8,$00,$33,$00,$00 ; ???
        .byte   $02,$96,$00                 ; ???
.endproc

.proc text_box                  ; or whole window ??
left:   .word   10
top:    .word   28
        .word   $2000           ; ??? never changed
        .word   $80             ; ??? never changed
unk1:   .word   0               ; ???
unk2:   .word   0               ; ???
width:  .word   $200
height: .word   $96
.endproc

        ;; unused?
        .byte   $00,$00,$00,$00,$00,$00,$00
        .byte   $00,$FF,$00,$00,$00,$00,$00,$01
        .byte   $01,$00,$7F,$00,$88,$00,$00

        ;; gets copied over text_box after mode is drawn
.proc default_box
left:   .word   10
top:    .word   28
        .word   $2000
        .word   $80
unk1:   .word   0
unk2:   .word   0
width:  .word   $200
height: .word   $96
.endproc

.proc init
L09DE:  sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        lda     #$00
        sta     pathname
        lda     $DF21
        beq     L09F6
        lda     $DF20
        bne     L09F7
L09F6:  rts

L09F7:  asl     a
        tax
        lda     $DFB3,x
        sta     $06
        lda     $DFB4,x
        sta     $07
        ldy     #$00
        lda     ($06),y
        tax
        inc     $06
        bne     L0A0E
        inc     $07
L0A0E:  lda     #$05
        sta     $08
        lda     #$09
        sta     $09
        jsr     L0A72
        lda     #$2F
        ldy     #$00
        sta     ($08),y
        inc     pathname        ; ???
        inc     $08
        bne     L0A28
        inc     $09
L0A28:  lda     $DF22
        asl     a
        tax
        lda     $DD9F,x
        sta     $06
        lda     $DDA0,x
        sta     $07
        ldy     #$02
        lda     ($06),y
        and     #$70
        bne     L0A40
        rts

L0A40:  clc
        lda     $06
        adc     #$09
        sta     window_params::L0996
        lda     $07
        adc     #$00
        sta     window_params::L0996+1
        ldy     #$09
        lda     ($06),y
        tax
        dex
        dex
        clc
        lda     $06
        adc     #$0B
        sta     $06
        bcc     L0A61
        inc     $07
L0A61:  jsr     L0A72
        lda     #$1E
        sta     $27
        lda     #$40
        sta     $28
        jsr     zp_code_stash
        jmp     open_file_and_init_window
.endproc

.proc L0A72                     ; ???
        ldy     #$00
loop:   lda     ($06),y
        sta     ($08),y
        iny
        inc     pathname        ; ???
        dex
        bne     loop
        tya
        clc
        adc     $08
        sta     $08
        bcc     end
        inc     $09
end:    rts
.endproc

.proc open_file_and_init_window
        lda     #0
        sta     fixed_mode_flag

        ;; copy bytes (length at $8801) from $8802 to $10FF ???
        ldx     $8801
        sta     RAMWRTOFF
loop:   lda     $8802,x
        sta     L10FF,x
        dex
        bne     loop
        sta     RAMWRTON

        ;; open file, get length
        jsr     open_file
        lda     open_params::ref_num
        sta     read_params::ref_num
        sta     set_mark_params::ref_num
        sta     get_eof_params::ref_num
        sta     close_params::ref_num
        jsr     get_file_eof

        ;; create window
        A2D_CALL A2D_CREATE_WINDOW, window_params
        A2D_CALL $04, text_box
        jsr     L1088
        jsr     calc_and_draw_mode
        jsr     draw_content
        A2D_CALL $2B, 0
.endproc

input_loop:
        A2D_CALL A2D_GET_BUTTON, button_state
        lda     button_state
        cmp     #1              ; was clicked?
        bne     input_loop      ; nope, keep waiting

        A2D_CALL A2D_GET_MOUSE, mouse_data
        lda     mouse_data::win ; in our window?
        cmp     #window_id
        bne     input_loop

        ;; which part of the window?
        lda     mouse_data::elem
        cmp     #A2D_ELEM_CLOSE
        beq     on_close_btn_down

        ldx     mouse_data::xcoord      ; stash mouse location
        stx     xcoord1
        stx     query_client_params::xcoord
        ldx     mouse_data::xcoord+1
        stx     xcoord1+1
        stx     query_client_params::xcoord+1
        ldx     mouse_data::ycoord
        stx     ycoord1
        stx     query_client_params::ycoord

        cmp     #A2D_ELEM_TITLE
        beq     title
        cmp     #A2D_ELEM_RESIZE
        beq     input_loop
        jsr     on_client_click
        jmp     input_loop

title:  jsr     on_title_bar_click
        jmp     input_loop

.proc on_close_btn_down
        A2D_CALL A2D_BTN_CLICK, close_btn     ; wait to see if the click completes
        lda     close_btn::state ; did click complete?
        beq     input_loop      ; nope
        jsr     close_file
        A2D_CALL A2D_DESTROY_WINDOW, window_params
        jsr     UNKNOWN_CALL    ; hides the cursor?
        .byte   $0C
        .addr   0
        rts                     ; exits input loop
.endproc

;;; How would control get here???? Dead code???
.proc maybe_dead_code           ; window move routine, maybe?
        A2D_CALL $45, L0977     ; run resize loop?
        jsr     L10FD
        jsr     L1088

        max_width := 512
        lda     #>max_width
        cmp     text_box::width+1
        bne     skip
        lda     #<max_width
        cmp     text_box::width
skip:   bcs     wider

        lda     #<max_width
        sta     text_box::width
        lda     #>max_width
        sta     text_box::width+1
        sec
        lda     text_box::width
        sbc     window_width
        sta     text_box::unk1
        lda     text_box::width+1
        sbc     window_width+1
        sta     text_box::unk1+1
wider:  lda     window_params::L0998
        ldx     window_width
        cpx     #<max_width
        bne     L0B89
        ldx     window_width+1
        cpx     #>max_width
        bne     L0B89
        and     #$FE
        jmp     L0B8B

L0B89:  ora     #$01
L0B8B:  sta     window_params::L0998
        sec
        lda     #<max_width
        sbc     window_width
        sta     $06
        lda     #>max_width
        sbc     window_width+1
        sta     $07
        jsr     L10DF
        sta     L0987
        lda     #$02
        sta     L0986
        A2D_CALL $49, L0986     ; change to clamped size ???
        jsr     calc_and_draw_mode
        jmp     L0DF9
.endproc

;;; Non-title (client) area clicked
.proc on_client_click
        A2D_CALL A2D_QUERY_CLIENT, query_client_params
        lda     query_client_params::part
        cmp     #A2D_VSCROLL
        beq     on_vscroll_click
        cmp     #A2D_HSCROLL
        bne     end
        jmp     on_hscroll_click
end:    rts
.endproc

.proc on_vscroll_click
L0BC9:  lda     #A2D_VSCROLL
        sta     thumb_drag_params::type
        sta     update_scroll_params::type
        lda     query_client_params::scroll
        cmp     #A2D_SCROLL_PART_THUMB
        beq     on_vscroll_thumb_click
        cmp     #A2D_SCROLL_PART_BELOW
        beq     on_vscroll_below_click
        cmp     #A2D_SCROLL_PART_ABOVE
        beq     on_vscroll_above_click
        cmp     #A2D_SCROLL_PART_UP
        beq     on_vscroll_up_click
        cmp     #A2D_SCROLL_PART_DOWN
        bne     end
        jmp     on_vscroll_down_click
end:    rts
.endproc

.proc on_vscroll_thumb_click
        jsr     do_thumb_drag
        lda     thumb_drag_params::moved
        beq     end
        lda     thumb_drag_params::pos
        sta     update_scroll_params::pos
        jsr     L0D7C
        jsr     update_vscroll
        jsr     draw_content
        lda     L0947
        beq     end
        lda     L0949
        bne     end
        jsr     L0E1D
end:    rts
.endproc

.proc on_vscroll_above_click
loop:   lda     window_params::vscroll_pos
        beq     end
        jsr     calc_track_scroll_delta
        sec
        lda     window_params::vscroll_pos
        sbc     track_scroll_delta
        bcs     store
        lda     #$00            ; underflow
store:  sta     update_scroll_params::pos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc on_vscroll_up_click
loop :  lda     window_params::vscroll_pos
        beq     end
        sec
        sbc     #1
        sta     update_scroll_params::pos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

vscroll_max := $FA

.proc on_vscroll_below_click
loop:   lda     window_params::vscroll_pos
        cmp     #vscroll_max    ; pos == max ?
        beq     end
        jsr     calc_track_scroll_delta
        clc
        lda     window_params::vscroll_pos
        adc     track_scroll_delta ; pos + delta
        bcs     overflow
        cmp     #vscroll_max+1  ; > max ?
        bcc     store           ; nope, it's good
overflow:
        lda     #vscroll_max    ; set to max
store:  sta     update_scroll_params::pos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc on_vscroll_down_click
loop:   lda     window_params::vscroll_pos
        cmp     #vscroll_max
        beq     end
        clc
        adc     #1
        sta     update_scroll_params::pos
        jsr     update_scroll_pos
        bcc     loop            ; repeat while button down
end:    rts
.endproc

.proc update_scroll_pos         ; Returns with carry set if mouse released
        jsr     L0D7C
        jsr     update_vscroll
        jsr     draw_content
        jsr     was_button_released
        clc
        bne     end
        sec
end:    rts
.endproc

.proc calc_track_scroll_delta
        lda     window_height           ; ceil(??? / 50)
        ldx     #0
loop:   inx
        sec
        sbc     #50
        cmp     #50
        bcs     loop
        stx     track_scroll_delta
        rts
.endproc

;;; Unused in STF DA, so most of this is speculation
.proc on_hscroll_click
        lda     #A2D_HSCROLL
        sta     thumb_drag_params::type
        sta     update_scroll_params::type
        lda     query_client_params::scroll
        cmp     #A2D_SCROLL_PART_THUMB
        beq     on_hscroll_thumb_click
        cmp     #A2D_SCROLL_PART_AFTER
        beq     on_hscroll_after_click
        cmp     #A2D_SCROLL_PART_BEFORE
        beq     on_hscroll_before_click
        cmp     #A2D_SCROLL_PART_LEFT
        beq     on_hscroll_left_click
        cmp     #A2D_SCROLL_PART_RIGHT
        beq     on_hscroll_right_click
        rts
.endproc

.proc on_hscroll_thumb_click
        jsr     do_thumb_drag
        lda     thumb_drag_params::moved
        beq     end
        lda     thumb_drag_params::pos
        jsr     L10EC
        lda     $06
        sta     text_box::unk1
        lda     $07
        sta     text_box::unk1+1
        clc
        lda     text_box::unk1
        adc     window_width
        sta     text_box::width
        lda     text_box::unk1+1
        adc     window_width+1
        sta     text_box::width+1
        jsr     L0DD1
        jsr     draw_content
end:    rts
.endproc

.proc on_hscroll_after_click
        ldx     #2
        lda     window_params::L099A
        jmp     hscroll_common
.endproc

.proc on_hscroll_before_click
        ldx     #254
        lda     #0
        jmp     hscroll_common
.endproc

.proc on_hscroll_right_click
        ldx     #1
        lda     window_params::L099A
        jmp     hscroll_common
.endproc

.proc on_hscroll_left_click
        ldx     #255
        lda     #0
        ;; fall through
.endproc

.proc hscroll_common
        sta     compare+1
        stx     delta+1
loop:   lda     window_params::L099B
compare:cmp     #$0A            ; self-modified
        bne     continue
        rts

continue:
        clc
        lda     window_params::L099B
delta:  adc     #1              ; self-modified
        bmi     overflow
        cmp     window_params::L099A
        beq     store
        bcc     store
        lda     window_params::L099A
        jmp     store

overflow:
        lda     #0

store:  sta     window_params::L099B
        jsr     L0D5E
        jsr     L0DD1
        jsr     draw_content
        jsr     was_button_released
        bne     loop
        rts
.endproc

        ;; Used at start of thumb drag
.proc do_thumb_drag
        lda     mouse_data::xcoord
        sta     thumb_drag_params::xcoord
        lda     mouse_data::xcoord+1
        sta     thumb_drag_params::xcoord+1
        lda     mouse_data::ycoord
        sta     thumb_drag_params::ycoord
        A2D_CALL A2D_DRAG_SCROLL, thumb_drag_params
        rts
.endproc

;;; Checks button state; z clear if button was released, set otherwise
.proc was_button_released
        A2D_CALL A2D_GET_BUTTON, button_state
        lda     button_state
        cmp     #2
        rts
.endproc

;;; only used from hscroll code?
.proc L0D5E
        lda     window_params::L099B
        jsr     L10EC
        clc
        lda     $06
        sta     text_box::unk1
        adc     window_width
        sta     text_box::width
        lda     $07
        sta     text_box::unk1+1
        adc     window_width+1
        sta     text_box::width+1
        rts
.endproc

.proc L0D7C                     ; ?? part of vscroll
        lda     #0
        sta     text_box::unk2
        sta     text_box::unk2+1
        ldx     update_scroll_params::pos
loop:   beq     L0D9B
        clc
        lda     text_box::unk2
        adc     #50
        sta     text_box::unk2
        bcc     skip
        inc     text_box::unk2+1
skip:   dex
        jmp     loop
.endproc

.proc L0D9B                     ; ?? part of vscroll
        clc
        lda     text_box::unk2
        adc     window_height
        sta     text_box::height
        lda     text_box::unk2+1
        adc     window_height+1
        sta     text_box::height+1
        jsr     L10A5
        lda     #0
        sta     L096A
        sta     L096B
        ldx     update_scroll_params::pos
loop:   beq     end
        clc
        lda     L096A
        adc     #5
        sta     L096A
        bcc     skip
        inc     L096B
skip:   dex
        jmp     loop
end:    rts
.endproc

L0DD1:  lda     #2
        sta     update_scroll_params::type
        lda     text_box::unk1
        sta     $06
        lda     text_box::unk1+1
        sta     $07
        jsr     L10DF
        sta     update_scroll_params::pos
        A2D_CALL A2D_UPDATE_SCROLL, update_scroll_params
        rts

.proc update_vscroll            ; update_scroll_params::pos set by caller
        lda     #1
        sta     update_scroll_params::type
        A2D_CALL A2D_UPDATE_SCROLL, update_scroll_params
        rts
.endproc

.proc L0DF9                     ; only called from dead code
        jsr     UNKNOWN_CALL
        .byte   $0C
        .addr   0
        A2D_CALL $04, text_box
        lda     window_params::L0998
        ror     a
        bcc     skip
        jsr     L0DD1
skip:   lda     window_params::vscroll_pos
        sta     update_scroll_params::pos
        jsr     update_vscroll
        jsr     draw_content
        jmp     input_loop
.endproc

L0E1D:  A2D_CALL $08, L0952
        A2D_CALL $11, text_box::unk1
        A2D_CALL $08, L094A
        rts

;;; Draw content ???
.proc draw_content
        lda     #0
        sta     L0949
        jsr     L1129
        jsr     set_file_mark
        lda     #<default_buffer
        sta     read_params::buffer
        sta     $06
        lda     #>default_buffer
        sta     read_params::buffer+1
        sta     $07
        lda     #$00
        sta     L0945
        sta     L0946
        sta     L0947
        sta     line_pos::base+1
        sta     L096C
        sta     L096D
        sta     L0948
        lda     #$0A
        sta     line_pos::base
        jsr     L0EDB
L0E68:  lda     L096D
        cmp     L096B
        bne     L0E7E
        lda     L096C
        cmp     L096A
        bne     L0E7E
        jsr     L0E1D
        inc     L0948
L0E7E:  A2D_CALL A2D_SET_TEXT_POS, line_pos
        sec
        lda     #$FA
        sbc     line_pos::left
        sta     L095B
        lda     #$01
        sbc     line_pos::left+1
        sta     L095C
        jsr     L0EF3
        bcs     L0ED7
        clc
        lda     text_string::len
        adc     $06
        sta     $06
        bcc     L0EA6
        inc     $07
L0EA6:  lda     L095A
        bne     L0E68
        clc
        lda     line_pos::base
        adc     #$0A
        sta     line_pos::base
        bcc     L0EB9
        inc     line_pos::base+1
L0EB9:  jsr     L0EDB
        lda     L096C
        cmp     L0968
        bne     L0ECC
        lda     L096D
        cmp     L0969
        beq     L0ED7
L0ECC:  inc     L096C
        bne     L0ED4
        inc     L096D
L0ED4:  jmp     L0E68

L0ED7:  jsr     L1109
        rts
.endproc

.proc L0EDB                     ; ???
        lda     #$FA
        sta     L095B
        lda     #$01
        sta     L095C
        lda     #$03
        sta     line_pos::left
        lda     #$00
        sta     line_pos::left+1
        sta     L095A
        rts
.endproc

L0EF3:  lda     #$FF
        sta     L0F9B
        lda     #$00
        sta     L0F9C
        sta     L0F9D
        sta     L095A
        sta     text_string::len
        lda     $06
        sta     text_string::addr
        lda     $07
        sta     text_string::addr+1
L0F10:  lda     L0945
        bne     L0F22
        lda     L0947
        beq     L0F1F
        jsr     L0FF6
        sec
        rts

L0F1F:  jsr     L100C
L0F22:  ldy     text_string::len
        lda     ($06),y
        and     #$7F            ; clear high bit
        sta     ($06),y
        inc     L0945
        cmp     #$0D            ; return character
        beq     L0F86
        cmp     #$20            ; space character
        bne     L0F41
        sty     L0F9B
        pha
        lda     L0945
        sta     L0946
        pla
L0F41:  cmp     #$09
        bne     L0F48
        jmp     L0F9E

L0F48:  tay
        lda     $8803,y
        clc
        adc     L0F9C
        sta     L0F9C
        bcc     L0F58
        inc     L0F9D
L0F58:  lda     L095C
        cmp     L0F9D
        bne     L0F66
        lda     L095B
        cmp     L0F9C
L0F66:  bcc     L0F6E
        inc     text_string::len
        jmp     L0F10

L0F6E:  lda     #$00
        sta     L095A
        lda     L0F9B
        cmp     #$FF
        beq     L0F83
        sta     text_string::len
        lda     L0946
        sta     L0945
L0F83:  inc     text_string::len
L0F86:  jsr     L0FF6
        ldy     text_string::len
        lda     ($06),y
        cmp     #$09
        beq     L0F96
        cmp     #$0D
        bne     L0F99
L0F96:  inc     text_string::len
L0F99:  clc
        rts

L0F9B:  .byte   0
L0F9C:  .byte   0
L0F9D:  .byte   0
.proc L0F9E                     ; ???
        lda     #1
        sta     L095A
        clc
        lda     L0F9C
        adc     line_pos::left
        sta     line_pos::left
        lda     L0F9D
        adc     line_pos::left+1
        sta     line_pos::left+1
        ldx     #0
loop:   lda     times70+1,x
        cmp     line_pos::left+1
        bne     L0FC6
        lda     times70,x
        cmp     line_pos::left
L0FC6:  bcs     L0FD1
        inx
        inx
        cpx     #14
        beq     done
        jmp     loop
L0FD1:  lda     times70,x
        sta     line_pos::left
        lda     times70+1,x
        sta     line_pos::left+1
        jmp     L0F86
done:   lda     #0
        sta     L095A
        jmp     L0F86

times70:.word   70
        .word   140
        .word   210
        .word   280
        .word   350
        .word   420
        .word   490
.endproc

;;; Draws a line of content
L0FF6:  lda     L0948
        beq     L100B
        lda     text_string::len
        beq     L100B
L1000:  A2D_CALL A2D_DRAW_TEXT, text_string
        lda     #1
        sta     L0949
L100B:  rts

L100C:  lda     text_string::addr+1
        cmp     #$12            ; #>default_buffer?
        beq     L102B
        ldy     #$00
L1015:  lda     $1300,y
        sta     default_buffer,y
        iny
        bne     L1015
        dec     text_string::addr+1
        lda     text_string::addr
        sta     $06
        lda     text_string::addr+1
        sta     $07
L102B:  lda     #$00
        sta     L0945
        jsr     L103E
        lda     read_params::buffer+1
        cmp     #$12            ; #>default_buffer?
        bne     L103D
        inc     read_params::buffer+1
L103D:  rts

L103E:
.scope
        lda     read_params::buffer
        sta     store+1
        lda     read_params::buffer+1
        sta     store+2
        lda     #$20
        ldx     #$00
        sta     RAMWRTOFF
store:  sta     default_buffer,x         ; self-modified
        inx
        bne     store
        sta     RAMWRTON
        lda     #$00
        sta     L0947
        jsr     read_file
        pha
        lda     #$00
        sta     STARTLO
        sta     DESTINATIONLO
        lda     #$FF
        sta     ENDLO
        lda     read_params::buffer+1
        sta     DESTINATIONHI
        sta     STARTHI
        sta     ENDHI
        sec                     ; main>aux
        jsr     AUXMOVE
        pla
        beq     end
        cmp     #$4C
        beq     done
        brk                     ; ????
done:   lda     #$01
        sta     L0947
end:    rts
.endscope

L1088:  sec
        lda     text_box::width
        sbc     text_box::unk1
        sta     window_width
        lda     text_box::width+1
        sbc     text_box::unk1+1
        sta     window_width+1
        sec
        lda     text_box::height
        sbc     text_box::unk2
        sta     window_height
L10A5:  lda     text_box::height
        sta     L0965
        lda     text_box::height+1
        sta     L0966
        lda     #$00
        sta     L0968
        sta     L0969
L10B9:  lda     L0966
        bne     L10C5
        lda     L0965
        cmp     #$0A
        bcc     L10DE
L10C5:  sec
        lda     L0965
        sbc     #$0A
        sta     L0965
        bcs     L10D3
        dec     L0966
L10D3:  inc     L0968
        bne     L10B9
        inc     L0969
        jmp     L10B9

L10DE:  rts

L10DF:  ldx     #$04
L10E1:  clc
        ror     $07
        ror     $06
        dex
        bne     L10E1
        lda     $06
        rts

L10EC:  sta     $06
        lda     #$00
        sta     $07
        ldx     #$04
L10F4:  clc
        rol     $06
        rol     $07
        dex
        bne     L10F4
        rts

L10FD:  lda     #$15
L10FF:  sta     $27
        lda     #$40
        sta     $28
        jsr     zp_code_stash
        rts

;;; if fixed mode, do a main->aux copy of a code block ???
.proc L1109
        lda     fixed_mode_flag ; if not fixed (i.e. proportional)
        beq     end             ; then exit

        lda     #$00            ; start := $1100
        sta     STARTLO
        lda     #$7E
        sta     ENDLO           ; end := $117E
        lda     #$11
        sta     STARTHI
        sta     ENDHI

        dest := $8803
        lda     #>dest
        sta     DESTINATIONHI
        lda     #<dest
        sta     DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
end:    rts
.endproc

.proc L1129                     ; ???
        lda     fixed_mode_flag ; if not fixed (i.e. proportional)
        beq     end             ; then exit
        ldx     $8801
        lda     #$07
loop:   sta     $8802,x
        dex
        bne     loop
end:    rts
.endproc

;;; On Title Bar Click - if it's on the Fixed/Proportional label,
;;; toggle it and update.
.proc on_title_bar_click
        lda     mouse_data::xcoord+1           ; mouse x high byte?
        cmp     mode_box_left+1
        bne     :+
        lda     mouse_data::xcoord
        cmp     mode_box_left
:       bcc     ignore
        lda     fixed_mode_flag
        beq     set_flag
        dec     fixed_mode_flag ; clear flag (mode = proportional)
        jsr     L1109
        jmp     redraw

set_flag:
        inc     fixed_mode_flag ; set flag (mode = fixed)
redraw: jsr     draw_mode
        jsr     draw_content
        sec                     ; Click consumed
        rts

ignore: clc                     ; Click ignored
        rts
.endproc

fixed_str:      A2D_DEFSTRING "Fixed        "
prop_str:       A2D_DEFSTRING "Proportional"
        label_width := 50
        title_bar_height := 12
.proc mode_box                  ; bounding box for mode label
left:   .word   0
top:    .word   0
        .word   $2000           ; ??
        .word   $80             ; ??
        .word   0               ; ??
        .word   0               ; ??
width:  .word   80
height: .word   10
.endproc
mode_box_left := mode_box::left ; forward refs to mode_box::left don't work?

.proc mode_pos
left:   .word   0               ; horizontal text offset
base:   .word   10              ; vertical text offset (to baseline)
.endproc

.proc calc_and_draw_mode
        sec
        lda     text_box::top
        sbc     #title_bar_height
        sta     mode_box::top
        clc
        lda     text_box::left
        adc     window_width
        pha
        lda     text_box::left+1
        adc     window_width+1
        tax
        sec
        pla
        sbc     #<label_width
        sta     mode_box::left
        txa
        sbc     #>label_width
        sta     mode_box::left+1
        ;; fall through...
.endproc

.proc draw_mode
        A2D_CALL $06, mode_box  ; guess: setting up draw location ???
        A2D_CALL A2D_SET_TEXT_POS, mode_pos
        lda     fixed_mode_flag
        beq     else            ; is proportional?
        A2D_CALL A2D_DRAW_TEXT, fixed_str
        jmp     endif
else:   A2D_CALL A2D_DRAW_TEXT, prop_str

endif:  ldx     #$0F
loop:   lda     default_box,x
        sta     text_box,x
        dex
        bpl     loop
        A2D_CALL $06, text_box
        rts
.endproc
