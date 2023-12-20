    ; function: Whether the year is leap year
    ; input: DM+0 = year
    ; output: DM+1 = 1 if leap year, 0 otherwise

    sll   $zero, $zero, 0

isLeap(int):
    addi  $s0, $zero, 0         ; start DM address = 0, store to $s0
    lw    $s1, 0($s0)           ; year = DM+0
    add   $s2, $zero, $s1       ; n = year
    addi  $s3, $zero, 100       ; m = 100
    addi  $s4, $zero, 0         ; cnt = 0
    addi  $s5, $zero, 0         ; res = 0


    andi  $t0, $s1, 3           ; tt = year & 3
    bne   $t0, $zero, SAVE_0    ; if tt != 0, goto SAVE_0

    j     LEAP_1                ; goto LEAP_1

LEAP_0:
    addi  $s4, $s4, 1           ; cnt = cnt + 1

LEAP_1:
    sub   $s2, $s2, $s3         ; n = n - m
    sra   $t0, $s2, 31          ; tt = n >> 31
    beq   $t0, $zero, LEAP_0    ; if tt == 0 (n >= 0), goto LEAP_0

    andi  $s4, $s4, 3           ; cnt = cnt & 3
    add   $s2, $s2, $s3         ; n = n + m
    beq   $s2, $zero, N_IS_0    ; if n == 0 (can mod 100), goto N_IS_0

    addi  $s5, $zero, 1         ; res = 1
    j     SAVE_0                ; goto SAVE_0

N_IS_0:
    bne   $s4, $zero, SAVE_0    ; if cnt != 0 (cannot mod 400), goto SAVE_0
    addi  $s5, $zero, 1         ; res = 1

SAVE_0:
    sw    $s5, 1($s0)           ; DM+1 = res

    sll   $zero, $zero, 0