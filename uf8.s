    .data
in0:    .word  12345      # 測試輸入
enc0:   .word  0          # uf8_encode(in0) 結果（低 8 位有效）
dec0:   .word  0          # uf8_decode(enc0) 結果
clz0:   .word  0          # clz(in0) 結果

    .text
# ---------- 程式入口 ----------
    .globl _start
_start:
    jal     main
halt:
    jal     x0, halt      # 停在這裡方便觀察

# ---------- main ----------
    .globl main
main:
    # a0 = in0
    la      t0, in0
    lw      a0, 0(t0)

    # 呼叫 uf8_encode(a0)
    jal     uf8_encode

    # enc0 = a0
    la      t1, enc0
    sw      a0, 0(t1)

    # 呼叫 uf8_decode(enc0 & 0xFF)
    andi    a0, a0, 0xFF
    jal     uf8_decode
    la      t2, dec0
    sw      a0, 0(t2)

    # 再測 clz(in0)
    la      t3, in0
    lw      a0, 0(t3)
    jal     clz
    la      t4, clz0
    sw      a0, 0(t4)

    # 返回 _start（會停在 halt）
    jalr    x0, ra, 0


# ---------- clz ----------
    .globl clz
clz:
    addi    sp,sp,-48
    sw      ra,44(sp)
    sw      s0,40(sp)
    addi    s0,sp,48
    sw      a0,-36(s0)        # U = a0

    li      a5,32
    sw      a5,-20(s0)        # Y = 32
    li      a5,16
    sw      a5,-24(s0)        # X = 16

L3:
    lw      a5,-24(s0)        # a5 = X
    lw      a4,-36(s0)        # a4 = U
    srl     a5,a4,a5          # T = U >> X
    sw      a5,-28(s0)        # T

    lw      a5,-28(s0)
    beq     a5,x0,L2          # if (T==0) skip update
    lw      a4,-20(s0)        # Y
    lw      a5,-24(s0)        # X
    sub     a5,a4,a5          # Y = Y - X
    sw      a5,-20(s0)
    lw      a5,-28(s0)        # T
    sw      a5,-36(s0)        # U = T

L2:
    lw      a5,-24(s0)        # X
    srli    a5,a5,1           # X >>= 1  (termination guaranteed)
    sw      a5,-24(s0)
    lw      a5,-24(s0)
    bne     a5,x0,L3          # while (X != 0)

    lw      a4,-20(s0)        # Y
    lw      a5,-36(s0)        # U
    sub     a5,a4,a5          # return Y - U
    addi    a0,a5,0

    lw      ra,44(sp)
    lw      s0,40(sp)
    addi    sp,sp,48
    jalr    x0, ra, 0         # return


# ---------- uf8_decode ----------
    .globl uf8_decode
uf8_decode:
    addi    sp,sp,-48
    sw      ra,44(sp)
    sw      s0,40(sp)
    addi    s0,sp,48

    addi    a5,a0,0           # mv a5,a0
    sb      a5,-33(s0)
    lbu     a5,-33(s0)
    andi    a5,a5,15
    sw      a5,-20(s0)
    lbu     a5,-33(s0)
    srli    a5,a5,4
    sb      a5,-21(s0)
    lbu     a5,-21(s0)
    li      a4,15
    sub     a5,a4,a5
    li      a4,32768
    addi    a4,a4,-1
    sra     a5,a4,a5
    slli    a5,a5,4
    sw      a5,-28(s0)
    lbu     a5,-21(s0)
    lw      a4,-20(s0)
    sll     a4,a4,a5
    lw      a5,-28(s0)
    add     a5,a4,a5
    addi    a0,a5,0           # mv a0,a5

    lw      ra,44(sp)
    lw      s0,40(sp)
    addi    sp,sp,48
    jalr    x0, ra, 0


# ---------- uf8_encode ----------
    .globl uf8_encode
uf8_encode:
    addi    sp,sp,-64
    sw      ra,60(sp)
    sw      s0,56(sp)
    addi    s0,sp,64
    sw      a0,-52(s0)

    lw      a4,-52(s0)
    li      a5,15
    bltu    a5,a4,L8          # (bgtu a4,a5,L8) → bltu a5,a4,L8
    lw      a5,-52(s0)
    andi    a5,a5,0xff
    jal     x0, L9

L8:
    lw      a0,-52(s0)
    jal     clz               # (call clz) → jal clz
    addi    a5,a0,0           # mv a5,a0
    sw      a5,-32(s0)
    li      a4,31
    lw      a5,-32(s0)
    sub     a5,a4,a5
    sw      a5,-36(s0)
    sb      x0,-17(s0)
    sw      x0,-24(s0)
    lw      a4,-36(s0)
    li      a5,4
    bge     a5,a4,L16         # (ble a4,a5,L16) → bge a5,a4,L16

    lw      a5,-36(s0)
    andi    a5,a5,0xff
    addi    a5,a5,-4
    sb      a5,-17(s0)
    lbu     a4,-17(s0)
    li      a5,15
    bgeu    a5,a4,L11         # (bleu a4,a5,L11) → bgeu a5,a4,L11
    li      a5,15
    sb      a5,-17(s0)
L11:
    sb      x0,-25(s0)
    jal     x0, L12

L13:
    lw      a5,-24(s0)
    slli    a5,a5,1
    addi    a5,a5,16
    sw      a5,-24(s0)
    lbu     a5,-25(s0)
    addi    a5,a5,1
    sb      a5,-25(s0)

L12:
    lbu     a4,-25(s0)
    lbu     a5,-17(s0)
    bltu    a4,a5,L13
    jal     x0, L14

L15:
    lw      a5,-24(s0)
    addi    a5,a5,-16
    srli    a5,a5,1
    sw      a5,-24(s0)
    lbu     a5,-17(s0)
    addi    a5,a5,-1
    sb      a5,-17(s0)

L14:
    lbu     a5,-17(s0)
    beq     a5,x0,L16
    lw      a4,-52(s0)
    lw      a5,-24(s0)
    bltu    a4,a5,L15
    jal     x0, L16

L19:
    lw      a5,-24(s0)
    slli    a5,a5,1
    addi    a5,a5,16
    sw      a5,-40(s0)
    lw      a4,-52(s0)
    lw      a5,-40(s0)
    bltu    a4,a5,L20
    lw      a5,-40(s0)
    sw      a5,-24(s0)
    lbu     a5,-17(s0)
    addi    a5,a5,1
    sb      a5,-17(s0)

L16:
    lbu     a4,-17(s0)
    li      a5,14
    bgeu    a5,a4,L19         # (bleu a4,a5,L19) → bgeu a5,a4,L19
    jal     x0, L18

L20:
    nop

L18:
    lw      a4,-52(s0)
    lw      a5,-24(s0)
    sub     a4,a4,a5
    lbu     a5,-17(s0)
    srl     a5,a4,a5
    sb      a5,-41(s0)
    lb      a5,-17(s0)
    slli    a5,a5,4
    slli    a4,a5,24
    srai    a4,a4,24
    lb      a5,-41(s0)
    or      a5,a4,a5
    slli    a5,a5,24
    srai    a5,a5,24
    andi    a5,a5,0xff

L9:
    addi    a0,a5,0           # mv a0,a5
    lw      ra,60(sp)
    lw      s0,56(sp)
    addi    sp,sp,64
    jalr    x0, ra, 0
