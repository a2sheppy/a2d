        .setcpu "6502"

        .include "apple2.inc"
        .include "../inc/apple2.inc"
        .include "../inc/prodos.inc"
        .include "../mgtk.inc"
        .include "../desktop.inc"
        .include "../macros.inc"

        .include "opcodes.inc"

;;; ============================================================

        .org $800

        desktop_pattern := $65AA


entry:

;;; Copy the DA to AUX for easy bank switching
.scope
        lda     ROMIN2
        copy16  #$0800, STARTLO
        copy16  #da_end, ENDLO
        copy16  #$0800, DESTINATIONLO
        sec                     ; main>aux
        jsr     AUXMOVE
        lda     LCBANK1
        lda     LCBANK1
.endscope

.scope
        ;; run the DA
        sta     RAMRDON
        sta     RAMWRTON
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        jsr     init

        ;; tear down/exit
        sta     ALTZPON
        lda     LCBANK1
        lda     LCBANK1
        sta     RAMRDOFF
        sta     RAMWRTOFF
        rts
.endscope

;;; ============================================================

screen_width    := 560
screen_height   := 192

da_window_id    := 61
da_width        := 420
da_height       := 70
da_left         := (screen_width - da_width)/2
da_top          := (screen_height - da_height - 8)/2

str_title:
        PASCAL_STRING "Control Panel"

.proc winfo
window_id:      .byte   da_window_id
options:        .byte   MGTK::option_go_away_box
title:          .addr   str_title
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   da_width
mincontlength:  .word   da_height
maxcontwidth:   .word   da_width
maxcontlength:  .word   da_height
port:
viewloc:        DEFINE_POINT da_left, da_top
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        DEFINE_RECT 0, 0, da_width, da_height, maprect
pattern:        .res    8, $FF
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:          DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc


.proc winfo_fullscreen
window_id:      .byte   da_window_id+1
options:        .byte   MGTK::option_dialog_box
title:          .addr   str_title
hscroll:        .byte   MGTK::scroll_option_none
vscroll:        .byte   MGTK::scroll_option_none
hthumbmax:      .byte   32
hthumbpos:      .byte   0
vthumbmax:      .byte   32
vthumbpos:      .byte   0
status:         .byte   0
reserved:       .byte   0
mincontwidth:   .word   screen_width
mincontlength:  .word   screen_height
maxcontwidth:   .word   screen_width
maxcontlength:  .word   screen_height
port:
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   MGTK::screen_mapbits
mapwidth:       .word   MGTK::screen_mapwidth
maprect:        DEFINE_RECT 0, 0, screen_width, screen_height
pattern:        .res    8, 0
colormasks:     .byte   MGTK::colormask_and, MGTK::colormask_or
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   1
penheight:      .byte   1
penmode:        .byte   0
textback:       .byte   $7F
textfont:       .addr   DEFAULT_FONT
nextwinfo:      .addr   0
.endproc


;;; ============================================================


.proc event_params
kind:  .byte   0
;;; event_kind_key_down
key             := *
modifiers       := * + 1
;;; event_kind_update
window_id       := *
;;; otherwise
xcoord          := *
ycoord          := * + 2
        .res    4
.endproc

.proc findwindow_params
mousex:         .word   0
mousey:         .word   0
which_area:     .byte   0
window_id:      .byte   0
.endproc

.proc trackgoaway_params
clicked:        .byte   0
.endproc

.proc dragwindow_params
window_id:      .byte   0
dragx:          .word   0
dragy:          .word   0
moved:          .byte   0
.endproc

.proc winport_params
window_id:      .byte   da_window_id
port:           .addr   grafport
.endproc


.proc screentowindow_params
window_id:      .byte   da_window_id
screen: DEFINE_POINT 0, 0, screen
window: DEFINE_POINT 0, 0, window
.endproc
        mx := screentowindow_params::window::xcoord
        my := screentowindow_params::window::ycoord

.proc grafport
viewloc:        DEFINE_POINT 0, 0
mapbits:        .word   0
mapwidth:       .word   0
cliprect:       DEFINE_RECT 0, 0, 0, 0
pattern:        .res    8, 0
colormasks:     .byte   0, 0
penloc:         DEFINE_POINT 0, 0
penwidth:       .byte   0
penheight:      .byte   0
penmode:        .byte   0
textback:       .byte   0
textfont:       .addr   0
.endproc

;;; ============================================================
;;; Desktop Pattern Editor Resources

pedit_x := 16
pedit_y := 8

fatbit_w := 8
fatbit_ws := 3                  ; shift
fatbit_h := 4
fatbit_hs := 2                  ; shift
fatbits_rect:
        DEFINE_RECT pedit_x, pedit_y, pedit_x + 8 * fatbit_w + 1, pedit_y + 8 * fatbit_h + 1, fatbits_rect

str_desktop_pattern:
        DEFINE_STRING "Desktop Pattern"
pattern_label_pos:
        DEFINE_POINT pedit_x + 35, pedit_y + 47

preview_l       := pedit_x + 79
preview_t       := pedit_y
preview_r       := preview_l + 81
preview_b       := preview_t + 33
preview_s       := preview_t + 6

preview_rect:
        DEFINE_RECT preview_l+1, preview_s + 1, preview_r - 1, preview_b - 1

preview_line:
        DEFINE_RECT preview_l, preview_s, preview_r, preview_s

preview_frame:
        DEFINE_RECT preview_l, preview_t, preview_r, preview_b

        arr_w := 6
        arr_h := 5
        arr_inset := 5

        rarr_l := preview_r - arr_inset - arr_w
        rarr_t := preview_t+1
        rarr_r := rarr_l + arr_w - 1
        rarr_b := rarr_t + arr_h - 1

        larr_l := preview_l + arr_inset + 1
        larr_t := preview_t + 1
        larr_r := larr_l + arr_w - 1
        larr_b := larr_t + arr_h - 1

.proc larr_params
viewloc:        DEFINE_POINT larr_l, larr_t
mapbits:        .addr   larr_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, arr_w-1, arr_h-1
.endproc

.proc rarr_params
viewloc:        DEFINE_POINT rarr_l, rarr_t
mapbits:        .addr   rarr_bitmap
mapwidth:       .byte   1
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, arr_w-1, arr_h-1
.endproc

larr_rect:      DEFINE_RECT larr_l, larr_t, larr_r, larr_b
rarr_rect:      DEFINE_RECT rarr_l, rarr_t, rarr_r, rarr_b

larr_bitmap:
        .byte   px(%0000110)
        .byte   px(%0011110)
        .byte   px(%1111110)
        .byte   px(%0011110)
        .byte   px(%0000110)
rarr_bitmap:
        .byte   px(%1100000)
        .byte   px(%1111000)
        .byte   px(%1111110)
        .byte   px(%1111000)
        .byte   px(%1100000)

;;; ============================================================
;;; Double-Click Speed Resources

        ;; Selected index (1-3, or 0 for 'no match')
dblclick_speed:
        .byte   1

        ;; Computed counter values
dblclick_values:
dblclick_value1:
        .word   0
dblclick_value2:
        .word   0
dblclick_value3:
        .word   0

dblclick_x := 210
dblclick_y := 8

str_dblclick_speed:
        DEFINE_STRING "Double-Click Speed"

dblclick_label_pos:
        DEFINE_POINT dblclick_x + 45, dblclick_y + 47

.proc dblclick_params
viewloc:        DEFINE_POINT dblclick_x, dblclick_y
mapbits:        .addr   dblclick_bitmap
mapwidth:       .byte   8
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 53, 33
.endproc

dblclick_arrow_pos1:
        DEFINE_POINT dblclick_x + 65, dblclick_y + 7
dblclick_arrow_pos2:
        DEFINE_POINT dblclick_x + 65, dblclick_y + 22
dblclick_arrow_pos3:
        DEFINE_POINT dblclick_x + 110, dblclick_y + 10
dblclick_arrow_pos4:
        DEFINE_POINT dblclick_x + 110, dblclick_y + 22
dblclick_arrow_pos5:
        DEFINE_POINT dblclick_x + 155, dblclick_y + 13
dblclick_arrow_pos6:
        DEFINE_POINT dblclick_x + 155, dblclick_y + 23

dblclick_button_w := 15
dblclick_button_h := 7
dblclick_button_rect1:
        DEFINE_RECT dblclick_x + 175, dblclick_y + 25, dblclick_x + 175 + dblclick_button_w, dblclick_y + 25 + dblclick_button_h
dblclick_button_rect2:
        DEFINE_RECT dblclick_x + 130, dblclick_y + 25, dblclick_x + 130 + dblclick_button_w, dblclick_y + 25 + dblclick_button_h
dblclick_button_rect3:
        DEFINE_RECT dblclick_x + 85, dblclick_y + 25, dblclick_x + 85 + dblclick_button_w, dblclick_y + 25 + dblclick_button_h

dblclick_bitmap:
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000011),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0001111),px(%1100000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0111111),px(%1111000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000)
        .byte   px(%0000000),px(%0000000),px(%0000111),px(%1111111),px(%1111111),px(%1000000),px(%0000000),px(%0000000)
        .byte   px(%0000111),px(%1111111),px(%1111100),px(%0000000),px(%0000000),px(%1111111),px(%1111111),px(%1000000)
        .byte   px(%0011100),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%1110000)
        .byte   px(%1110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011100)
        .byte   px(%1100000),px(%0111111),px(%1111111),px(%1111111),px(%1111111),px(%1111111),px(%1111000),px(%0001100)
        .byte   px(%1100000),px(%0110000),px(%0000000),px(%0000000),px(%0000000),px(%0000000),px(%0011000),px(%0001100)
        .byte   px(%1100000),px(%0110000),px(%0000000),px(%0011111),px(%1110000),px(%0000000),px(%0011000),px(%0001100)
        .byte   px(%1100000),px(%0110000),px(%0000001),px(%1110000),px(%0011110),px(%0000000),px(%0011000),px(%0001100)
        .byte   px(%1100000),px(%0110000),px(%0000111),px(%0110000),px(%0011011),px(%1000000),px(%0011000),px(%0001100)
        .byte   px(%1100000),px(%0110101),px(%0101110),px(%0110000),px(%0011001),px(%1101010),px(%1011000),px(%0001100)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0110000),px(%0011001),px(%1000000),px(%0011000),px(%0001100)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0110000),px(%0011001),px(%1000000),px(%0011000),px(%0001100)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0011111),px(%1110001),px(%1000000),px(%0011000),px(%0001100)
        .byte   px(%1100000),px(%0110000),px(%0000110),px(%0000000),px(%0000001),px(%1000000),px(%0011000),px(%0001100)
        .byte   px(%1100000),px(%0111111),px(%1111110),px(%0000000),px(%0000001),px(%1111111),px(%1111000),px(%0001100)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%0000001),px(%1000000),px(%0000000),px(%0001100)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%0000001),px(%1000000),px(%0000000),px(%0001100)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%0000001),px(%1000000),px(%0000000),px(%0001100)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%0000001),px(%1000000),px(%0000000),px(%0001100)
        .byte   px(%1100000),px(%0000000),px(%0000110),px(%0000000),px(%0000001),px(%1000000),px(%0000000),px(%0001100)

.proc darrow_params
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   darr_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, 16, 7
.endproc

darr_bitmap:
        .byte   px(%0000011),px(%1111100),px(%0000000)
        .byte   px(%0000011),px(%1111100),px(%0000000)
        .byte   px(%0000011),px(%1111100),px(%0000000)
        .byte   px(%1111111),px(%1111111),px(%1110000)
        .byte   px(%0011111),px(%1111111),px(%1000000)
        .byte   px(%0000111),px(%1111110),px(%0000000)
        .byte   px(%0000001),px(%1111000),px(%0000000)
        .byte   px(%0000000),px(%0100000),px(%0000000)

.proc checked_params
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   checked_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, dblclick_button_w, dblclick_button_h
.endproc

checked_bitmap:
        .byte   px(%0000111),px(%1111100),px(%0000000)
        .byte   px(%0011100),px(%0000111),px(%0000000)
        .byte   px(%1110001),px(%1110001),px(%1100000)
        .byte   px(%1100111),px(%1111100),px(%1100000)
        .byte   px(%1100111),px(%1111100),px(%1100000)
        .byte   px(%1110001),px(%1110001),px(%1100000)
        .byte   px(%0011100),px(%0000111),px(%0000000)
        .byte   px(%0000111),px(%1111100),px(%0000000)


.proc unchecked_params
viewloc:        DEFINE_POINT 0, 0
mapbits:        .addr   unchecked_bitmap
mapwidth:       .byte   3
reserved:       .byte   0
cliprect:       DEFINE_RECT 0, 0, dblclick_button_w, dblclick_button_h
.endproc

unchecked_bitmap:
        .byte   px(%0000111),px(%1111100),px(%0000000)
        .byte   px(%0011100),px(%0000111),px(%0000000)
        .byte   px(%1110000),px(%0000001),px(%1100000)
        .byte   px(%1100000),px(%0000000),px(%1100000)
        .byte   px(%1100000),px(%0000000),px(%1100000)
        .byte   px(%1110000),px(%0000001),px(%1100000)
        .byte   px(%0011100),px(%0000111),px(%0000000)
        .byte   px(%0000111),px(%1111100),px(%0000000)

;;; ============================================================

.proc init
        jsr     init_pattern
        jsr     init_dblclick
        MGTK_CALL MGTK::OpenWindow, winfo
        jsr     draw_window
        MGTK_CALL MGTK::FlushEvents
        ;; fall through
.endproc

.proc input_loop
        MGTK_CALL MGTK::GetEvent, event_params
        bne     exit
        lda     event_params::kind
        cmp     #MGTK::event_kind_button_down
        beq     handle_down
        cmp     #MGTK::event_kind_key_down
        beq     handle_key
        jmp     input_loop
.endproc

.proc exit
        MGTK_CALL MGTK::CloseWindow, winfo
        DESKTOP_CALL DT_REDRAW_ICONS
        rts
.endproc

;;; ============================================================

.proc handle_key
        lda     event_params::key
        cmp     #CHAR_ESCAPE
        beq     exit
        bne     input_loop
.endproc

;;; ============================================================

.proc handle_down
        copy16  event_params::xcoord, findwindow_params::mousex
        copy16  event_params::ycoord, findwindow_params::mousey
        MGTK_CALL MGTK::FindWindow, findwindow_params
        bne     exit
        lda     findwindow_params::window_id
        cmp     winfo::window_id
        bne     input_loop
        lda     findwindow_params::which_area
        cmp     #MGTK::area_close_box
        beq     handle_close
        cmp     #MGTK::area_dragbar
        beq     handle_drag
        cmp     #MGTK::area_content
        beq     handle_click
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_close
        MGTK_CALL MGTK::TrackGoAway, trackgoaway_params
        lda     trackgoaway_params::clicked
        beq     input_loop
        bne     exit
.endproc

;;; ============================================================

.proc handle_drag
        copy    winfo::window_id, dragwindow_params::window_id
        copy16  event_params::xcoord, dragwindow_params::dragx
        copy16  event_params::ycoord, dragwindow_params::dragy
        MGTK_CALL MGTK::DragWindow, dragwindow_params
common: lda     dragwindow_params::moved
        bpl     :+

        ;; Draw DeskTop's windows
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

        ;; Draw DeskTop icons
        DESKTOP_CALL DT_REDRAW_ICONS

:       jmp     input_loop

.endproc


;;; ============================================================

.proc handle_click
        copy16  event_params::xcoord, screentowindow_params::screen::xcoord
        copy16  event_params::ycoord, screentowindow_params::screen::ycoord
        MGTK_CALL MGTK::ScreenToWindow, screentowindow_params

        MGTK_CALL MGTK::MoveTo, screentowindow_params::window
        MGTK_CALL MGTK::InRect, fatbits_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     handle_bits_click

:       MGTK_CALL MGTK::InRect, larr_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     handle_larr_click

:       MGTK_CALL MGTK::InRect, rarr_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     handle_rarr_click

:       MGTK_CALL MGTK::InRect, preview_rect
        cmp     #MGTK::inrect_inside
        bne     :+
        jmp     handle_pattern_click

:       MGTK_CALL MGTK::InRect, dblclick_button_rect1
        cmp     #MGTK::inrect_inside
        bne     :+
        lda     #1
        jmp     handle_dblclick_click

:       MGTK_CALL MGTK::InRect, dblclick_button_rect2
        cmp     #MGTK::inrect_inside
        bne     :+
        lda     #2
        jmp     handle_dblclick_click

:       MGTK_CALL MGTK::InRect, dblclick_button_rect3
        cmp     #MGTK::inrect_inside
        bne     :+
        lda     #3
        jmp     handle_dblclick_click

:       jmp     input_loop
.endproc

;;; ============================================================

.proc handle_rarr_click
        inc     pattern_index
        lda     pattern_index
        cmp     #pattern_count
        bcc     :+
        lda     #0
:       sta     pattern_index
        jmp     update_pattern
.endproc

.proc handle_larr_click
        dec     pattern_index
        lda     pattern_index
        bpl     :+
        lda     #pattern_count-1
:       sta     pattern_index
        jmp     update_pattern
.endproc

.proc update_pattern
        ptr := $06
        lda     pattern_index
        asl
        tay
        copy16  patterns,y, ptr
        ldy     #7
:       lda     (ptr),y
        sta     pattern,y
        dey
        bpl     :-

        jsr     update_bits
        jmp     input_loop
.endproc

;;; ============================================================

.proc handle_bits_click
        sub16   mx, fatbits_rect::x1, mx
        sub16   my, fatbits_rect::y1, my
        dec16   mx
        dec16   my

        ldy     #fatbit_ws
:       lsr16   mx
        dey
        bne     :-
        cmp16   mx, #8
        bcs     done

        ldy     #fatbit_hs
:       lsr16   my
        dey
        bne     :-
        cmp16   my, #8
        bcs     done

        ldx     mx
        ldy     my
        lda     pattern,y
        eor     mask,x
        sta     pattern,y

        jsr     update_bits
done:   jmp     input_loop

mask:   .byte   1<<0, 1<<1, 1<<2, 1<<3, 1<<4, 1<<5, 1<<6, 1<<7
.endproc

.proc update_bits
        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     draw_bits
        MGTK_CALL MGTK::ShowCursor
        rts
.endproc

;;; ============================================================

.proc handle_dblclick_click
        sta     dblclick_speed
        tay
        dey
        tya
        asl                     ; *= 2
        tay

        sta     RAMWRTOFF        ; Store into main
        lda     dblclick_values,y
        sta     dblclick_counter_lo
        iny
        lda     dblclick_values,y
        sta     dblclick_counter_hi
        sta     RAMWRTON

        MGTK_CALL MGTK::GetWinPort, winport_params
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor
        jsr     draw_dblclick_buttons
        MGTK_CALL MGTK::ShowCursor
        jmp     input_loop
.endproc

;;; ============================================================

dblclick_counter_lo := $860B
dblclick_counter_hi := $8610

.proc init_dblclick
        ;; Routine to patch
        dblclick_routine := $860A
        dblclick_routine_len := 78

        ;; Counter value
        dblclick_machine_type := $D2AB

        ;; Compute counter values
        lda     dblclick_machine_type
        sta     dblclick_value1
        lda     #0
        sta     dblclick_value1+1
        asl16   dblclick_value1 ; Normal is 2x machine_type
        copy16  dblclick_value1, dblclick_value2
        asl16   dblclick_value2 ; Setting 2 is 4x machine time
        copy16  dblclick_value2, dblclick_value3
        asl16   dblclick_value3 ; Setting 3 is 32x machine type (!!!)
        asl16   dblclick_value3
        asl16   dblclick_value3

        ;; Do we need to patch DeskTop?
        sta     RAMRDOFF        ; we're running in aux, routine lives in main
        lda     sig
        sta     RAMRDON
        cmp     #OPC_NOP
        beq     done_patch

        ;; Yes, patch it...
        sta     RAMWRTOFF
        ldy     #dblclick_routine_len - 1
:       lda     routine,y
        sta     dblclick_routine,y
        dey
        bpl     :-
        ;; And patch the patch with the default value
        lda     dblclick_value1
        sta     dblclick_counter_lo
        lda     dblclick_value1+1
        sta     dblclick_counter_hi
        sta     RAMWRTON

done_patch:
        ;; Load current from main
        sta     RAMRDOFF
        lda     dblclick_counter_lo
        sta     current_counter
        lda     dblclick_counter_hi
        sta     current_counter+1
        sta     RAMRDON

        ;; TODO: Use a loop
        lda     current_counter
        cmp     dblclick_value1
        bne     :+
        lda     current_counter+1
        cmp     dblclick_value1+1
        bne     :+

        lda     #1
        sta     dblclick_speed
        rts

:       lda     current_counter
        cmp     dblclick_value2
        bne     :+
        lda     current_counter+1
        cmp     dblclick_value2+1
        bne     :+

        lda     #2
        sta     dblclick_speed
        rts

:       lda     current_counter
        cmp     dblclick_value3
        bne     :+
        lda     current_counter+1
        cmp     dblclick_value3+1
        bne     :+

        lda     #3
        sta     dblclick_speed
        rts

:       lda     #0
        sta     dblclick_speed
        rts


;;; ------------------------------------------------------------
;;; The following routine is patched into DeskTop MAIN at
;;; $860A...$8657 and replaces the mouse time delta routine
;;; with a 16-bit counter (original is 9 bit).

.proc routine
        orig_org := *
        .org $860A ;dblclick_routine

        get_event  := $48E6
        peek_event := $48F0
        event_kind := $D208

start:
        counter_lo := *+1
        lda     #0              ; patched by DA
        sta     counter
        counter_hi := *+1
        lda     #0              ; patched by DA
        sta     counter+1
sig:    nop                     ; Used as signature

        ;; Decrement counter, bail if time delta exceeded
loop:   lda     counter
        bne     :+
        dec     counter+1
:       dec     counter
        lda     counter
        ora     counter+1
        beq     exit
        jsr     peek_event

        ;; Check coords, bail if pixel delta exceeded
        jsr     check_delta
        bmi     exit            ; moved past delta; no double-click

        lda     event_kind
        cmp     #MGTK::event_kind_no_event
        beq     loop
        cmp     #MGTK::event_kind_drag
        beq     loop
        cmp     #MGTK::event_kind_button_up
        bne     :+
        jsr     get_event
        jmp     loop
:       cmp     #MGTK::event_kind_button_down
        bne     exit

        jsr     get_event
        return  #0              ; double-click

exit:   return  #$FF            ; not double-click

        PAD_TO $8658

        check_delta := $8658
        counter := $869E

end:
        .org orig_org + end - start
.endproc
        sig := routine::sig
        .assert .sizeof(routine) = dblclick_routine_len, error, "Routine length mismatch"
        .assert dblclick_counter_lo = routine::counter_lo, error, "Offset mismatch"
        .assert dblclick_counter_hi = routine::counter_hi, error, "Offset mismatch"

current_counter:
        .word   0
.endproc


;;; ============================================================

.proc init_pattern
        ldy     #7
:       lda     desktop_pattern,y
        sta     pattern,y
        dey
        bpl     :-
        rts
.endproc

.proc handle_pattern_click
        ;; TODO: Replace this horrible hack
        ldy     #7
:       lda     pattern,y
        sta     desktop_pattern,y
        dey
        bpl     :-

        MGTK_CALL MGTK::OpenWindow, winfo_fullscreen
        MGTK_CALL MGTK::CloseWindow, winfo_fullscreen

        ;; Draw DeskTop's windows
        sta     RAMRDOFF
        sta     RAMWRTOFF
        jsr     JUMP_TABLE_REDRAW_ALL
        sta     RAMRDON
        sta     RAMWRTON

        ;; Draw DA's window
        jsr     draw_window

        ;; Draw DeskTop icons
        DESKTOP_CALL DT_REDRAW_ICONS


        jmp input_loop
.endproc

;;; ============================================================

penXOR:         .byte   MGTK::penXOR
pencopy:        .byte   MGTK::pencopy
penBIC:         .byte   MGTK::penBIC
notpencopy:     .byte   MGTK::notpencopy


;;; ============================================================

.proc draw_window
        ;; Defer if content area is not visible
        MGTK_CALL MGTK::GetWinPort, winport_params
        cmp     #MGTK::error_window_obscured
        bne     :+
        rts
:
        MGTK_CALL MGTK::SetPort, grafport
        MGTK_CALL MGTK::HideCursor


        ;; ==============================
        ;; Desktop Pattern

        MGTK_CALL MGTK::MoveTo, pattern_label_pos
        MGTK_CALL MGTK::DrawText, str_desktop_pattern

        MGTK_CALL MGTK::SetPenMode, penBIC
        MGTK_CALL MGTK::FrameRect, fatbits_rect
        MGTK_CALL MGTK::PaintBits, larr_params
        MGTK_CALL MGTK::PaintBits, rarr_params

        MGTK_CALL MGTK::SetPenMode, penXOR
        MGTK_CALL MGTK::FrameRect, preview_frame

        MGTK_CALL MGTK::SetPenMode, penBIC
        MGTK_CALL MGTK::FrameRect, preview_line

        jsr     draw_bits

        ;; ==============================
        ;; Double-Click Speed

        MGTK_CALL MGTK::MoveTo, dblclick_label_pos
        MGTK_CALL MGTK::DrawText, str_dblclick_speed


.macro copy32 arg1, arg2
        .scope
        ldy     #3
loop:   lda     arg1,y
        sta     arg2,y
        dey
        bpl     loop
        .endscope
.endmacro

        MGTK_CALL MGTK::SetPenMode, notpencopy
        ;; TODO: Loop here
        copy32 dblclick_arrow_pos1, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos2, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos3, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos4, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos5, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params
        copy32 dblclick_arrow_pos6, darrow_params::viewloc
        MGTK_CALL MGTK::PaintBits, darrow_params

        jsr     draw_dblclick_buttons

        MGTK_CALL MGTK::SetPenMode, notpencopy
        MGTK_CALL MGTK::PaintBits, dblclick_params

done:   MGTK_CALL MGTK::ShowCursor
        rts

.endproc

.proc draw_dblclick_buttons
        MGTK_CALL MGTK::SetPenMode, notpencopy

        ldax    #dblclick_button_rect1
        ldy     #1
        jsr     draw_dblclick_button
        ldax    #dblclick_button_rect2
        ldy     #2
        jsr     draw_dblclick_button
        ldax    #dblclick_button_rect3
        ldy     #3
        jsr     draw_dblclick_button
        rts
.endproc

;;; A,X = pos ptr, Y = selected index (1,2,3)
.proc draw_dblclick_button
        ptr := $06

        stax    ptr
        cpy     dblclick_speed
        beq     checked

unchecked:
        ldy     #3
:       lda     (ptr),y
        sta     unchecked_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, unchecked_params
        rts

checked:
        ldy     #3
:       lda     (ptr),y
        sta     checked_params::viewloc,y
        dey
        bpl     :-
        MGTK_CALL MGTK::PaintBits, checked_params
        rts
.endproc


bitpos:    DEFINE_POINT    0, 0, bitpos

.proc draw_bits
        MGTK_CALL MGTK::SetPenMode, pencopy
        MGTK_CALL MGTK::SetPattern, pattern
        MGTK_CALL MGTK::PaintRect, preview_rect

        MGTK_CALL MGTK::SetPattern, winfo::pattern
        MGTK_CALL MGTK::SetPenSize, size

        copy    #0, ypos
        add16   fatbits_rect::y1, #1, bitpos::ycoord

yloop:  copy    #0, xpos
        add16   fatbits_rect::x1, #1, bitpos::xcoord
        ldy     ypos
        lda     pattern, y
        sta     row

xloop:  ror     row
        bcc     zero
        lda     #MGTK::pencopy
        bpl     store
zero:   lda     #MGTK::notpencopy
store:  sta     mode

        MGTK_CALL MGTK::SetPenMode, mode
        MGTK_CALL MGTK::MoveTo, bitpos
        MGTK_CALL MGTK::LineTo, bitpos

next_x: inc     xpos
        lda     xpos
        cmp     #8
        beq     next_y

        add16   bitpos::xcoord, #fatbit_w, bitpos::xcoord
        jmp     xloop

next_y: inc     ypos
        lda     ypos
        cmp     #8
        beq     done

        add16   bitpos::ycoord, #fatbit_h, bitpos::ycoord
        jmp     yloop

done:   rts

xpos:   .byte   0
ypos:   .byte   0
row:    .byte   0

mode:   .byte   0
size:   .byte fatbit_w, fatbit_h

.endproc

;;; ============================================================

pattern:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

pattern_index:  .byte   0
pattern_count := 15
patterns:
        .addr pattern_checkerboard, pattern_dark, pattern_vdark, pattern_black
        .addr pattern_olives, pattern_scales, pattern_stripes
        .addr pattern_light, pattern_vlight, pattern_xlight, pattern_white
        .addr pattern_cane, pattern_brick, pattern_curvy, pattern_abrick

pattern_checkerboard:
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010
        .byte   %01010101
        .byte   %10101010

pattern_dark:
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001
        .byte   %01000100
        .byte   %00010001

pattern_vdark:
        .byte   %10001000
        .byte   %00000000
        .byte   %00100010
        .byte   %00000000
        .byte   %10001000
        .byte   %00000000
        .byte   %00100010
        .byte   %00000000

pattern_black:
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000

pattern_olives:
        .byte   %00010001
        .byte   %01101110
        .byte   %00001110
        .byte   %00001110
        .byte   %00010001
        .byte   %11100110
        .byte   %11100000
        .byte   %11100000

pattern_scales:
        .byte   %11111110
        .byte   %11111110
        .byte   %01111101
        .byte   %10000011
        .byte   %11101111
        .byte   %11101111
        .byte   %11010111
        .byte   %00111000

pattern_stripes:
        .byte   %01110111
        .byte   %10111011
        .byte   %11011101
        .byte   %11101110
        .byte   %01110111
        .byte   %10111011
        .byte   %11011101
        .byte   %11101110

pattern_light:
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011
        .byte   %11101110
        .byte   %10111011

pattern_vlight:
        .byte   %11101110
        .byte   %11111111
        .byte   %10111011
        .byte   %11111111
        .byte   %11101110
        .byte   %11111111
        .byte   %10111011
        .byte   %11111111

pattern_xlight:
        .byte   %11111110
        .byte   %11111111
        .byte   %11101111
        .byte   %11111111
        .byte   %11111110
        .byte   %11111111
        .byte   %11101111
        .byte   %11111111

pattern_white:
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111

pattern_cane:
        .byte   %11100000
        .byte   %11010001
        .byte   %10111011
        .byte   %00011101
        .byte   %00001110
        .byte   %00010111
        .byte   %10111011
        .byte   %01110001

pattern_brick:
        .byte   %00000000
        .byte   %11111110
        .byte   %11111110
        .byte   %11111110
        .byte   %00000000
        .byte   %11101111
        .byte   %11101111
        .byte   %11101111

pattern_curvy:
        .byte   %00111111
        .byte   %11011110
        .byte   %11101101
        .byte   %11110011
        .byte   %11001111
        .byte   %10111111
        .byte   %01111111
        .byte   %01111111

pattern_abrick:
        .byte   %11101111
        .byte   %11000111
        .byte   %10111011
        .byte   %01111100
        .byte   %11111110
        .byte   %01111111
        .byte   %10111111
        .byte   %11011111

;;; ============================================================

da_end  = *
.assert * < $1B00, error, "DA too big"
        ;; I/O Buffer starts at MAIN $1C00
        ;; ... but icon tables start at AUX $1B00
