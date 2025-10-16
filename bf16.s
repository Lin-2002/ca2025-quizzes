    .text
    .align  2
    .globl  main
# =============================================================
# MAIN：不使用 stack、不用 s 暫存器
# 每個測試都「直接載參數 → call → 印結果」
# =============================================================
main:
    # ---- bf16_add(0x3FC0, 0x4000) ----
    li      a0, 0x3FC0
    li      a1, 0x4000
    call    bf16_add
    slli a0, a0, 16
    srli a0, a0, 16

    call    ripes_print_uint

    # ---- bf16_sub(0x3FC0, 0x4000) ----
    li      a0, 0x3FC0
    li      a1, 0x4000
    call    bf16_sub
    slli a0, a0, 16
    srli a0, a0, 16

    call    ripes_print_uint

    # ---- bf16_mul(0x3FC0, 0x4000) ----
    li      a0, 0x3FC0
    li      a1, 0x4000
    call    bf16_mul
    slli a0, a0, 16
    srli a0, a0, 16

    call    ripes_print_uint

    # ---- bf16_div(0x4000, 0x3FC0) ----
    li      a0, 0x4000
    li      a1, 0x3FC0
    call    bf16_div
    slli a0, a0, 16
    srli a0, a0, 16

    call    ripes_print_uint

    # ---- bf16_sqrt(0x4000) ----
    li      a0, 0x4000
    call    bf16_sqrt
    slli a0, a0, 16
    srli a0, a0, 16

    call    ripes_print_uint

    # ---- bf16_isnan(0x7FC0) -> 1 ----
    li      a0, 0x7FC0
    call    bf16_isnan
    call    ripes_print_uint

    # ---- bf16_isinf(0x7F80) -> 1 ----
    li      a0, 0x7F80
    call    bf16_isinf
    call    ripes_print_uint

    # ---- bf16_iszero(+0=0x0000) -> 1 ----
    li      a0, 0x0000
    call    bf16_iszero
    call    ripes_print_uint

    # ---- bf16_iszero(-0=0x8000) -> 1 ----
    li      a0, 0x8000
    call    bf16_iszero
    call    ripes_print_uint

    # ---- bf16_to_f32(0x3FC0) → bitcast_f32_to_u32 ----
    li      a0, 0x3FC0
    call    bf16_to_f32          # a0 現在是 float(1.5)（用整數暫存器承載）
    call    bitcast_f32_to_u32   # 取出 u32 位元
    call    ripes_print_uint

    # ---- f32_to_bf16(3.5f = 0x40600000) ----
    li      a0, 0x40600000
    call    f32_to_bf16
    slli a0, a0, 16
    srli a0, a0, 16

    call    ripes_print_uint

    # ---- bitcast_u32_to_f32(1.0f) round-trip ----
    li      a0, 0x3F800000
    call    bitcast_u32_to_f32
    call    bitcast_f32_to_u32
    call    ripes_print_uint

    # ---- umul32(12345, 6789) ----
    li      a0, 12345
    li      a1, 6789
    call    umul32
    call    ripes_print_uint

    # ---- __mulsi3(111, 2222) ----
    li      a0, 111
    li      a1, 2222
    call    __mulsi3
    call    ripes_print_uint

    # ---- 退出 ----
    call    ripes_exit

1:  j       1b   # 不會到這；保險自旋

umul32:
	addi	sp,sp,-32
	sw	a0,12(sp)
	sw	a1,8(sp)
	sw	zero,28(sp)
	j	L2
L4:
	lw	a5,8(sp)
	andi	a5,a5,1
	beq	a5,zero,L3
	lw	a4,28(sp)
	lw	a5,12(sp)
	add	a5,a4,a5
	sw	a5,28(sp)
L3:
	lw	a5,12(sp)
	slli	a5,a5,1
	sw	a5,12(sp)
	lw	a5,8(sp)
	srli	a5,a5,1
	sw	a5,8(sp)
L2:
	lw	a5,8(sp)
	bne	a5,zero,L4
	lw	a5,28(sp)
	mv	a0,a5
	addi	sp,sp,32
	jr	ra
	.align	2
	.globl	__mulsi3
__mulsi3:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sw	a0,12(sp)
	sw	a1,8(sp)
	lw	a1,8(sp)
	lw	a0,12(sp)
	call	umul32
	mv	a5,a0
	mv	a0,a5
	lw	ra,28(sp)
	addi	sp,sp,32
	jr	ra
	.align	2
bitcast_f32_to_u32:
	addi	sp,sp,-32
	sw	a0,12(sp)
	lw	a5,12(sp)
	sw	a5,28(sp)
	lw	a5,28(sp)
	mv	a0,a5
	addi	sp,sp,32
	jr	ra
	.align	2
bitcast_u32_to_f32:
	addi	sp,sp,-32
	sw	a0,12(sp)
	lw	a5,12(sp)
	sw	a5,28(sp)
	lw	a5,28(sp)
	mv	a0,a5
	addi	sp,sp,32
	jr	ra
	.align	2
bf16_isnan:
	addi	sp,sp,-16
	sh	a0,12(sp)
	lhu	a5,12(sp)
	mv	a4,a5
	li	a5,32768
	addi	a5,a5,-128
	and	a4,a4,a5
	li	a5,32768
	addi	a5,a5,-128
	bne	a4,a5,L13
	lhu	a5,12(sp)
	andi	a5,a5,127
	beq	a5,zero,L13
	li	a5,1
	j	L14
L13:
	li	a5,0
L14:
	andi	a5,a5,1
	andi	a5,a5,0xff
	mv	a0,a5
	addi	sp,sp,16
	jr	ra
	.align	2
bf16_isinf:
	addi	sp,sp,-16
	sh	a0,12(sp)
	lhu	a5,12(sp)
	mv	a4,a5
	li	a5,32768
	addi	a5,a5,-128
	and	a4,a4,a5
	li	a5,32768
	addi	a5,a5,-128
	bne	a4,a5,L17
	lhu	a5,12(sp)
	andi	a5,a5,127
	bne	a5,zero,L17
	li	a5,1
	j	L18
L17:
	li	a5,0
L18:
	andi	a5,a5,1
	andi	a5,a5,0xff
	mv	a0,a5
	addi	sp,sp,16
	jr	ra
	.align	2
bf16_iszero:
	addi	sp,sp,-16
	sh	a0,12(sp)
	lhu	a5,12(sp)
	mv	a4,a5
	li	a5,32768
	addi	a5,a5,-1
	and	a5,a4,a5
	seqz	a5,a5
	andi	a5,a5,0xff
	mv	a0,a5
	addi	sp,sp,16
	jr	ra
	.align	2
f32_to_bf16:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sw	a0,12(sp)
	lw	a0,12(sp)
	call	bitcast_f32_to_u32
	sw	a0,28(sp)
	lw	a5,28(sp)
	srli	a5,a5,23
	andi	a4,a5,255
	li	a5,255
	bne	a4,a5,L23
	lw	a5,28(sp)
	srli	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
	j	L25
L23:
	lw	a5,28(sp)
	srli	a5,a5,16
	andi	a4,a5,1
	lw	a5,28(sp)
	add	a4,a4,a5
	li	a5,32768
	addi	a5,a5,-1
	add	a5,a4,a5
	sw	a5,28(sp)
	lw	a5,28(sp)
	srli	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
L25:
	mv	a0,a5
	lw	ra,44(sp)
	addi	sp,sp,48
	jr	ra
	.align	2
bf16_to_f32:
	addi	sp,sp,-48
	sw	ra,44(sp)
	sh	a0,12(sp)
	lhu	a5,12(sp)
	slli	a5,a5,16
	sw	a5,28(sp)
	lw	a0,28(sp)
	call	bitcast_u32_to_f32
	mv	a5,a0
	mv	a0,a5
	lw	ra,44(sp)
	addi	sp,sp,48
	jr	ra
	.align	2
bf16_add:
	addi	sp,sp,-48
	sh	a0,12(sp)
	sh	a1,8(sp)
	lhu	a5,12(sp)
	srli	a5,a5,15
	sh	a5,34(sp)
	lhu	a5,8(sp)
	srli	a5,a5,15
	sh	a5,32(sp)
	lhu	a5,12(sp)
	srli	a5,a5,7
	slli	a5,a5,16
	srli	a5,a5,16
	slli	a5,a5,16
	srai	a5,a5,16
	andi	a5,a5,255
	sh	a5,30(sp)
	lhu	a5,8(sp)
	srli	a5,a5,7
	slli	a5,a5,16
	srli	a5,a5,16
	slli	a5,a5,16
	srai	a5,a5,16
	andi	a5,a5,255
	sh	a5,28(sp)
	lhu	a5,12(sp)
	andi	a5,a5,127
	sh	a5,46(sp)
	lhu	a5,8(sp)
	andi	a5,a5,127
	sh	a5,44(sp)
	lh	a4,30(sp)
	li	a5,255
	bne	a4,a5,L29
	lhu	a5,46(sp)
	beq	a5,zero,L30
	lhu	a5,12(sp)
	j	L52
L30:
	lh	a4,28(sp)
	li	a5,255
	bne	a4,a5,L32
	lhu	a5,44(sp)
	bne	a5,zero,L33
	lhu	a4,34(sp)
	lhu	a5,32(sp)
	beq	a4,a5,L33
	li	a5,-32768
	xori	a5,a5,-64
	j	L52
L33:
	lhu	a5,8(sp)
	j	L52
L32:
	lhu	a5,12(sp)
	j	L52
L29:
	lh	a4,28(sp)
	li	a5,255
	bne	a4,a5,L35
	lhu	a5,8(sp)
	j	L52
L35:
	lh	a5,30(sp)
	bne	a5,zero,L36
	lhu	a5,46(sp)
	bne	a5,zero,L36
	lhu	a5,8(sp)
	j	L52
L36:
	lh	a5,28(sp)
	bne	a5,zero,L37
	lhu	a5,44(sp)
	bne	a5,zero,L37
	lhu	a5,12(sp)
	j	L52
L37:
	lh	a5,30(sp)
	beq	a5,zero,L38
	lhu	a5,46(sp)
	ori	a5,a5,128
	sh	a5,46(sp)
L38:
	lh	a5,28(sp)
	beq	a5,zero,L39
	lhu	a5,44(sp)
	ori	a5,a5,128
	sh	a5,44(sp)
L39:
	lhu	a4,30(sp)
	lhu	a5,28(sp)
	sub	a5,a4,a5
	slli	a5,a5,16
	srli	a5,a5,16
	sh	a5,26(sp)
	lh	a5,26(sp)
	ble	a5,zero,L40
	lhu	a5,30(sp)
	sh	a5,40(sp)
	lh	a4,26(sp)
	li	a5,8
	ble	a4,a5,L41
	lhu	a5,12(sp)
	j	L52
L41:
	lhu	a4,44(sp)
	lh	a5,26(sp)
	sra	a5,a4,a5
	sh	a5,44(sp)
	j	L42
L40:
	lh	a5,26(sp)
	bge	a5,zero,L43
	lhu	a5,28(sp)
	sh	a5,40(sp)
	lh	a4,26(sp)
	li	a5,-8
	bge	a4,a5,L44
	lhu	a5,8(sp)
	j	L52
L44:
	lhu	a4,46(sp)
	lh	a5,26(sp)
	neg	a5,a5
	sra	a5,a4,a5
	sh	a5,46(sp)
	j	L42
L43:
	lhu	a5,30(sp)
	sh	a5,40(sp)
L42:
	lhu	a4,34(sp)
	lhu	a5,32(sp)
	bne	a4,a5,L45
	lhu	a5,34(sp)
	sh	a5,42(sp)
	lhu	a4,46(sp)
	lhu	a5,44(sp)
	add	a5,a4,a5
	sw	a5,36(sp)
	lw	a5,36(sp)
	andi	a5,a5,256
	beq	a5,zero,L46
	lw	a5,36(sp)
	srli	a5,a5,1
	sw	a5,36(sp)
	lhu	a5,40(sp)
	addi	a5,a5,1
	slli	a5,a5,16
	srli	a5,a5,16
	sh	a5,40(sp)
	lh	a4,40(sp)
	li	a5,254
	ble	a4,a5,L46
	lh	a5,42(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	li	a5,32768
	addi	a5,a5,-128
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
	j	L52
L45:
	lhu	a4,46(sp)
	lhu	a5,44(sp)
	bltu	a4,a5,L47
	lhu	a5,34(sp)
	sh	a5,42(sp)
	lhu	a4,46(sp)
	lhu	a5,44(sp)
	sub	a5,a4,a5
	sw	a5,36(sp)
	j	L48
L47:
	lhu	a5,32(sp)
	sh	a5,42(sp)
	lhu	a4,44(sp)
	lhu	a5,46(sp)
	sub	a5,a4,a5
	sw	a5,36(sp)
L48:
	lw	a5,36(sp)
	bne	a5,zero,L50
	li	a5,0
	j	L52
L51:
	lw	a5,36(sp)
	slli	a5,a5,1
	sw	a5,36(sp)
	lhu	a5,40(sp)
	addi	a5,a5,-1
	slli	a5,a5,16
	srli	a5,a5,16
	sh	a5,40(sp)
	lh	a5,40(sp)
	bgt	a5,zero,L50
	li	a5,0
	j	L52
L50:
	lw	a5,36(sp)
	andi	a5,a5,128
	beq	a5,zero,L51
L46:
	lh	a5,42(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	lhu	a5,40(sp)
	slli	a5,a5,7
	slli	a3,a5,16
	srai	a3,a3,16
	li	a5,32768
	addi	a5,a5,-128
	and	a5,a3,a5
	slli	a5,a5,16
	srai	a5,a5,16
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a4,a5,16
	srli	a4,a4,16
	lw	a5,36(sp)
	slli	a5,a5,16
	srli	a5,a5,16
	andi	a5,a5,127
	slli	a5,a5,16
	srli	a5,a5,16
	or	a5,a4,a5
	slli	a5,a5,16
	srli	a5,a5,16
L52:
	mv	a0,a5
	addi	sp,sp,48
	jr	ra
	.align	2
bf16_sub:
	addi	sp,sp,-32
	sw	ra,28(sp)
	sh	a0,12(sp)
	sh	a1,8(sp)
	lhu	a4,8(sp)
	li	a5,-32768
	xor	a5,a4,a5
	slli	a5,a5,16
	srli	a5,a5,16
	sh	a5,8(sp)
	lhu	a5,8(sp)
	mv	a1,a5
	lhu	a5,12(sp)
	mv	a0,a5
	call	bf16_add
	mv	a5,a0
	mv	a0,a5
	lw	ra,28(sp)
	addi	sp,sp,32
	jr	ra
	.align	2
bf16_mul:
	addi	sp,sp,-64
	sw	ra,60(sp)
	sh	a0,12(sp)
	sh	a1,8(sp)
	lhu	a5,12(sp)
	srli	a5,a5,15
	sh	a5,26(sp)
	lhu	a5,8(sp)
	srli	a5,a5,15
	sh	a5,24(sp)
	lhu	a5,12(sp)
	srli	a5,a5,7
	slli	a5,a5,16
	srli	a5,a5,16
	slli	a5,a5,16
	srai	a5,a5,16
	andi	a5,a5,255
	sh	a5,46(sp)
	lhu	a5,8(sp)
	srli	a5,a5,7
	slli	a5,a5,16
	srli	a5,a5,16
	slli	a5,a5,16
	srai	a5,a5,16
	andi	a5,a5,255
	sh	a5,44(sp)
	lhu	a5,12(sp)
	andi	a5,a5,127
	sh	a5,42(sp)
	lhu	a5,8(sp)
	andi	a5,a5,127
	sh	a5,40(sp)
	lhu	a5,26(sp)
	mv	a4,a5
	lhu	a5,24(sp)
	xor	a5,a4,a5
	sh	a5,22(sp)
	lh	a4,46(sp)
	li	a5,255
	bne	a4,a5,L56
	lhu	a5,42(sp)
	beq	a5,zero,L57
	lhu	a5,12(sp)
	j	L81
L57:
	lh	a5,44(sp)
	bne	a5,zero,L59
	lhu	a5,40(sp)
	bne	a5,zero,L59
	li	a5,-32768
	xori	a5,a5,-64
	j	L81
L59:
	lh	a5,22(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	li	a5,32768
	addi	a5,a5,-128
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
	j	L81
L56:
	lh	a4,44(sp)
	li	a5,255
	bne	a4,a5,L61
	lhu	a5,40(sp)
	beq	a5,zero,L62
	lhu	a5,8(sp)
	j	L81
L62:
	lh	a5,46(sp)
	bne	a5,zero,L64
	lhu	a5,42(sp)
	bne	a5,zero,L64
	li	a5,-32768
	xori	a5,a5,-64
	j	L81
L64:
	lh	a5,22(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	li	a5,32768
	addi	a5,a5,-128
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
	j	L81
L61:
	lh	a5,46(sp)
	bne	a5,zero,L65
	lhu	a5,42(sp)
	beq	a5,zero,L66
L65:
	lh	a5,44(sp)
	bne	a5,zero,L67
	lhu	a5,40(sp)
	bne	a5,zero,L67
L66:
	lhu	a5,22(sp)
	slli	a5,a5,15
	slli	a5,a5,16
	srli	a5,a5,16
	j	L81
L67:
	sh	zero,38(sp)
	lh	a5,46(sp)
	bne	a5,zero,L68
	j	L69
L70:
	lhu	a5,42(sp)
	slli	a5,a5,1
	sh	a5,42(sp)
	lh	a5,38(sp)
	slli	a5,a5,16
	srli	a5,a5,16
	addi	a5,a5,-1
	slli	a5,a5,16
	srli	a5,a5,16
	sh	a5,38(sp)
L69:
	lhu	a5,42(sp)
	andi	a5,a5,128
	beq	a5,zero,L70
	li	a5,1
	sh	a5,46(sp)
	j	L71
L68:
	lhu	a5,42(sp)
	ori	a5,a5,128
	sh	a5,42(sp)
L71:
	lh	a5,44(sp)
	bne	a5,zero,L72
	j	L73
L74:
	lhu	a5,40(sp)
	slli	a5,a5,1
	sh	a5,40(sp)
	lh	a5,38(sp)
	slli	a5,a5,16
	srli	a5,a5,16
	addi	a5,a5,-1
	slli	a5,a5,16
	srli	a5,a5,16
	sh	a5,38(sp)
L73:
	lhu	a5,40(sp)
	andi	a5,a5,128
	beq	a5,zero,L74
	li	a5,1
	sh	a5,44(sp)
	j	L75
L72:
	lhu	a5,40(sp)
	ori	a5,a5,128
	sh	a5,40(sp)
L75:
	lhu	a5,42(sp)
	lhu	a4,40(sp)
	mv	a1,a4
	mv	a0,a5
	call	umul32
	sw	a0,32(sp)
	lh	a4,46(sp)
	lh	a5,44(sp)
	add	a5,a4,a5
	addi	a4,a5,-127
	lh	a5,38(sp)
	add	a5,a4,a5
	sw	a5,28(sp)
	lw	a4,32(sp)
	li	a5,32768
	and	a5,a4,a5
	beq	a5,zero,L76
	lw	a5,32(sp)
	srli	a5,a5,8
	andi	a5,a5,127
	sw	a5,32(sp)
	lw	a5,28(sp)
	addi	a5,a5,1
	sw	a5,28(sp)
	j	L77
L76:
	lw	a5,32(sp)
	srli	a5,a5,7
	andi	a5,a5,127
	sw	a5,32(sp)
L77:
	lw	a4,28(sp)
	li	a5,254
	ble	a4,a5,L78
	lh	a5,22(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	li	a5,32768
	addi	a5,a5,-128
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
	j	L81
L78:
	lw	a5,28(sp)
	bgt	a5,zero,L79
	lw	a4,28(sp)
	li	a5,-6
	bge	a4,a5,L80
	lhu	a5,22(sp)
	slli	a5,a5,15
	slli	a5,a5,16
	srli	a5,a5,16
	j	L81
L80:
	li	a4,1
	lw	a5,28(sp)
	sub	a5,a4,a5
	lw	a4,32(sp)
	srl	a5,a4,a5
	sw	a5,32(sp)
	sw	zero,28(sp)
L79:
	lh	a5,22(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	lw	a5,28(sp)
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,7
	slli	a3,a5,16
	srai	a3,a3,16
	li	a5,32768
	addi	a5,a5,-128
	and	a5,a3,a5
	slli	a5,a5,16
	srai	a5,a5,16
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a4,a5,16
	srli	a4,a4,16
	lw	a5,32(sp)
	slli	a5,a5,16
	srli	a5,a5,16
	andi	a5,a5,127
	slli	a5,a5,16
	srli	a5,a5,16
	or	a5,a4,a5
	slli	a5,a5,16
	srli	a5,a5,16
L81:
	mv	a0,a5
	lw	ra,60(sp)
	addi	sp,sp,64
	jr	ra
	.align	2
bf16_div:
	addi	sp,sp,-64
	sh	a0,12(sp)
	sh	a1,8(sp)
	lhu	a5,12(sp)
	srli	a5,a5,15
	sh	a5,42(sp)
	lhu	a5,8(sp)
	srli	a5,a5,15
	sh	a5,40(sp)
	lhu	a5,12(sp)
	srli	a5,a5,7
	slli	a5,a5,16
	srli	a5,a5,16
	slli	a5,a5,16
	srai	a5,a5,16
	andi	a5,a5,255
	sh	a5,38(sp)
	lhu	a5,8(sp)
	srli	a5,a5,7
	slli	a5,a5,16
	srli	a5,a5,16
	slli	a5,a5,16
	srai	a5,a5,16
	andi	a5,a5,255
	sh	a5,36(sp)
	lhu	a5,12(sp)
	andi	a5,a5,127
	sh	a5,62(sp)
	lhu	a5,8(sp)
	andi	a5,a5,127
	sh	a5,60(sp)
	lhu	a5,42(sp)
	mv	a4,a5
	lhu	a5,40(sp)
	xor	a5,a4,a5
	sh	a5,34(sp)
	lh	a4,36(sp)
	li	a5,255
	bne	a4,a5,L83
	lhu	a5,60(sp)
	beq	a5,zero,L84
	lhu	a5,8(sp)
	j	L109
L84:
	lh	a4,38(sp)
	li	a5,255
	bne	a4,a5,L86
	lhu	a5,62(sp)
	bne	a5,zero,L86
	li	a5,-32768
	xori	a5,a5,-64
	j	L109
L86:
	lhu	a5,34(sp)
	slli	a5,a5,15
	slli	a5,a5,16
	srli	a5,a5,16
	j	L109
L83:
	lh	a5,36(sp)
	bne	a5,zero,L88
	lhu	a5,60(sp)
	bne	a5,zero,L88
	lh	a5,38(sp)
	bne	a5,zero,L89
	lhu	a5,62(sp)
	bne	a5,zero,L89
	li	a5,-32768
	xori	a5,a5,-64
	j	L109
L89:
	lh	a5,34(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	li	a5,32768
	addi	a5,a5,-128
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
	j	L109
L88:
	lh	a4,38(sp)
	li	a5,255
	bne	a4,a5,L91
	lhu	a5,62(sp)
	beq	a5,zero,L92
	lhu	a5,12(sp)
	j	L109
L92:
	lh	a5,34(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	li	a5,32768
	addi	a5,a5,-128
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
	j	L109
L91:
	lh	a5,38(sp)
	bne	a5,zero,L94
	lhu	a5,62(sp)
	bne	a5,zero,L94
	lhu	a5,34(sp)
	slli	a5,a5,15
	slli	a5,a5,16
	srli	a5,a5,16
	j	L109
L94:
	lh	a5,38(sp)
	beq	a5,zero,L95
	lhu	a5,62(sp)
	ori	a5,a5,128
	sh	a5,62(sp)
L95:
	lh	a5,36(sp)
	beq	a5,zero,L96
	lhu	a5,60(sp)
	ori	a5,a5,128
	sh	a5,60(sp)
L96:
	lhu	a5,62(sp)
	slli	a5,a5,15
	sw	a5,56(sp)
	lhu	a5,60(sp)
	sw	a5,28(sp)
	sw	zero,52(sp)
	sw	zero,48(sp)
	j	L97
L99:
	lw	a5,52(sp)
	slli	a5,a5,1
	sw	a5,52(sp)
	li	a4,15
	lw	a5,48(sp)
	sub	a5,a4,a5
	lw	a4,28(sp)
	sll	a5,a4,a5
	lw	a4,56(sp)
	bltu	a4,a5,L98
	li	a4,15
	lw	a5,48(sp)
	sub	a5,a4,a5
	lw	a4,28(sp)
	sll	a5,a4,a5
	lw	a4,56(sp)
	sub	a5,a4,a5
	sw	a5,56(sp)
	lw	a5,52(sp)
	ori	a5,a5,1
	sw	a5,52(sp)
L98:
	lw	a5,48(sp)
	addi	a5,a5,1
	sw	a5,48(sp)
L97:
	lw	a4,48(sp)
	li	a5,15
	ble	a4,a5,L99
	lh	a4,38(sp)
	lh	a5,36(sp)
	sub	a5,a4,a5
	addi	a5,a5,127
	sw	a5,44(sp)
	lh	a5,38(sp)
	bne	a5,zero,L100
	lw	a5,44(sp)
	addi	a5,a5,-1
	sw	a5,44(sp)
L100:
	lh	a5,36(sp)
	bne	a5,zero,L101
	lw	a5,44(sp)
	addi	a5,a5,1
	sw	a5,44(sp)
L101:
	lw	a4,52(sp)
	li	a5,32768
	and	a5,a4,a5
	beq	a5,zero,L104
	lw	a5,52(sp)
	srli	a5,a5,8
	sw	a5,52(sp)
	j	L103
L106:
	lw	a5,52(sp)
	slli	a5,a5,1
	sw	a5,52(sp)
	lw	a5,44(sp)
	addi	a5,a5,-1
	sw	a5,44(sp)
L104:
	lw	a4,52(sp)
	li	a5,32768
	and	a5,a4,a5
	bne	a5,zero,L105
	lw	a4,44(sp)
	li	a5,1
	bgt	a4,a5,L106
L105:
	lw	a5,52(sp)
	srli	a5,a5,8
	sw	a5,52(sp)
L103:
	lw	a5,52(sp)
	andi	a5,a5,127
	sw	a5,52(sp)
	lw	a4,44(sp)
	li	a5,254
	ble	a4,a5,L107
	lh	a5,34(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	li	a5,32768
	addi	a5,a5,-128
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
	j	L109
L107:
	lw	a5,44(sp)
	bgt	a5,zero,L108
	lhu	a5,34(sp)
	slli	a5,a5,15
	slli	a5,a5,16
	srli	a5,a5,16
	j	L109
L108:
	lh	a5,34(sp)
	slli	a5,a5,15
	slli	a4,a5,16
	srai	a4,a4,16
	lw	a5,44(sp)
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,7
	slli	a3,a5,16
	srai	a3,a3,16
	li	a5,32768
	addi	a5,a5,-128
	and	a5,a3,a5
	slli	a5,a5,16
	srai	a5,a5,16
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a4,a5,16
	srli	a4,a4,16
	lw	a5,52(sp)
	slli	a5,a5,16
	srli	a5,a5,16
	andi	a5,a5,127
	slli	a5,a5,16
	srli	a5,a5,16
	or	a5,a4,a5
	slli	a5,a5,16
	srli	a5,a5,16
L109:
	mv	a0,a5
	addi	sp,sp,64
	jr	ra
	.align	2
bf16_sqrt:
	addi	sp,sp,-80
	sw	ra,76(sp)
	sh	a0,12(sp)
	lhu	a5,12(sp)
	srli	a5,a5,15
	sh	a5,42(sp)
	lhu	a5,12(sp)
	srli	a5,a5,7
	slli	a5,a5,16
	srli	a5,a5,16
	slli	a5,a5,16
	srai	a5,a5,16
	andi	a5,a5,255
	sh	a5,40(sp)
	lhu	a5,12(sp)
	andi	a5,a5,127
	sh	a5,38(sp)
	lh	a4,40(sp)
	li	a5,255
	bne	a4,a5,L111
	lhu	a5,38(sp)
	beq	a5,zero,L112
	lhu	a5,12(sp)
	j	L129
L112:
	lhu	a5,42(sp)
	beq	a5,zero,L114
	li	a5,-32768
	xori	a5,a5,-64
	j	L129
L114:
	lhu	a5,12(sp)
	j	L129
L111:
	lh	a5,40(sp)
	bne	a5,zero,L115
	lhu	a5,38(sp)
	bne	a5,zero,L115
	li	a5,0
	j	L129
L115:
	lhu	a5,42(sp)
	beq	a5,zero,L116
	li	a5,-32768
	xori	a5,a5,-64
	j	L129
L116:
	lh	a5,40(sp)
	bne	a5,zero,L117
	li	a5,0
	j	L129
L117:
	lh	a5,40(sp)
	addi	a5,a5,-127
	sw	a5,32(sp)
	lhu	a5,38(sp)
	ori	a5,a5,128
	slli	a5,a5,16
	srli	a5,a5,16
	sw	a5,56(sp)
	lw	a5,32(sp)
	andi	a5,a5,1
	beq	a5,zero,L118
	lw	a5,56(sp)
	slli	a5,a5,1
	sw	a5,56(sp)
	lw	a5,32(sp)
	addi	a5,a5,-1
	srai	a5,a5,1
	addi	a5,a5,127
	sw	a5,60(sp)
	j	L119
L118:
	lw	a5,32(sp)
	srai	a5,a5,1
	addi	a5,a5,127
	sw	a5,60(sp)
L119:
	li	a5,90
	sw	a5,52(sp)
	li	a5,256
	sw	a5,48(sp)
	li	a5,128
	sw	a5,44(sp)
	j	L120
L122:
	lw	a4,52(sp)
	lw	a5,48(sp)
	add	a5,a4,a5
	srli	a5,a5,1
	sw	a5,24(sp)
	lw	a1,24(sp)
	lw	a0,24(sp)
	call	umul32
	mv	a5,a0
	srli	a5,a5,7
	sw	a5,20(sp)
	lw	a4,20(sp)
	lw	a5,56(sp)
	bgtu	a4,a5,L121
	lw	a5,24(sp)
	sw	a5,44(sp)
	lw	a5,24(sp)
	addi	a5,a5,1
	sw	a5,52(sp)
	j	L120
L121:
	lw	a5,24(sp)
	addi	a5,a5,-1
	sw	a5,48(sp)
L120:
	lw	a4,52(sp)
	lw	a5,48(sp)
	bleu	a4,a5,L122
	lw	a4,44(sp)
	li	a5,255
	bleu	a4,a5,L123
	lw	a5,44(sp)
	srli	a5,a5,1
	sw	a5,44(sp)
	lw	a5,60(sp)
	addi	a5,a5,1
	sw	a5,60(sp)
	j	L124
L123:
	lw	a4,44(sp)
	li	a5,127
	bgtu	a4,a5,L124
	j	L125
L126:
	lw	a5,44(sp)
	slli	a5,a5,1
	sw	a5,44(sp)
	lw	a5,60(sp)
	addi	a5,a5,-1
	sw	a5,60(sp)
L125:
	lw	a4,44(sp)
	li	a5,127
	bgtu	a4,a5,L124
	lw	a4,60(sp)
	li	a5,1
	bgt	a4,a5,L126
L124:
	lw	a5,44(sp)
	slli	a5,a5,16
	srli	a5,a5,16
	andi	a5,a5,127
	sh	a5,30(sp)
	lw	a4,60(sp)
	li	a5,254
	ble	a4,a5,L127
	li	a5,-32768
	xori	a5,a5,-128
	j	L129
L127:
	lw	a5,60(sp)
	bgt	a5,zero,L128
	li	a5,0
	j	L129
L128:
	lw	a5,60(sp)
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,7
	slli	a4,a5,16
	srai	a4,a4,16
	li	a5,32768
	addi	a5,a5,-128
	and	a5,a4,a5
	slli	a4,a5,16
	srai	a4,a4,16
	lh	a5,30(sp)
	or	a5,a4,a5
	slli	a5,a5,16
	srai	a5,a5,16
	slli	a5,a5,16
	srli	a5,a5,16
L129:
	mv	a0,a5
	lw	ra,76(sp)
	addi	sp,sp,80
	jr	ra
	.align	2
ripes_print_uint:
	addi	sp,sp,-16
	sw	a0,12(sp)
	lw	a5,12(sp)
 #APP
# 257 "src/bf16_1.c" 1
	mv a0,a5
li a7,1
ecall
# 0 "" 2
 #NO_APP
	nop
	addi	sp,sp,16
	jr	ra
	.align	2
ripes_exit:
 #APP
# 260 "src/bf16_1.c" 1
	li a7,10
ecall
# 0 "" 2
 #NO_APP
	nop
	ret
.text
	.align	2
	.globl	main

__keep:
	.word	bf16_add
	.word	bf16_div
	.word	bf16_isinf
	.word	bf16_isnan
	.word	bf16_iszero
	.word	bf16_mul
	.word	bf16_sqrt
	.word	bf16_sub
	.word	bf16_to_f32
	.word	bitcast_f32_to_u32
	.word	bitcast_u32_to_f32
	.word	f32_to_bf16
	.word	ripes_exit
	.word	ripes_print_uint
	.word	umul32
