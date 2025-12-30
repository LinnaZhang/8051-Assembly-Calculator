; 定义LCD控制引脚
LCD_RS   BIT P2.6
LCD_RW   BIT P2.5
LCD_E    BIT P2.7
LCD_DATA EQU P0

KEY_PORT EQU P1

; 定义变量存储区
NUM1     DATA 30H    ; 第一个操作数
NUM2     DATA 31H    ; 第二个操作数
NEGATIVE_INPUT_FLAG1 DATA 3CH ; 操作数1负数输入标志 0=正数 1=负数
NEGATIVE_INPUT_FLAG2 DATA 3DH ; 操作数2负数输入标志 0=正数 1=负数
RESULT   DATA 32H    ; 运算结果
REMAINDER DATA 3BH    ; 余数
OPERATOR DATA 33H    ; 运算符
TEMP     DATA 34H    ; 临时存储
INPUT_FLAG DATA 35H  ; 输入标志(0:输入NUM1, 1:输入NUM2)
KEY_VALUE DATA 36H   ; 键值存储
KEY_FLAG  DATA 37H   ; 按键标志位
CALC_DONE DATA 38H   ; 计算完成标志(0:未完成, 1:已完成)
SIGN_FLAG DATA 39H   ; 负数标志位 0=正数 1=负数
ERROR_FLAG DATA 3AH  ; 错误类型标志
; 操作数存在标志
NUM1_EXIST DATA 40H
NUM2_EXIST DATA 41H


; 错误类型定义
OVERFLOW_ERROR_FLAG EQU 1
SYNTAX_ERROR_FLAG   EQU 2
MATH_ERROR_FLAG     EQU 3
GENERAL_ERROR_FLAG  EQU 4

ORG 0000H
LJMP MAIN

; 初始化
ORG 0030H
MAIN:
    MOV SP, #60H
    LCALL LCD_INIT
    LCALL CLEAR_ALL
    MOV KEY_FLAG, #0
    
MAIN_LOOP:
    LCALL KEY_SCAN
    CJNE A, #0FFH, PROCESS_KEY_VALID
    SJMP MAIN_LOOP
;    
PROCESS_KEY_VALID:
    MOV KEY_VALUE, A
    LCALL WAIT_KEY_RELEASE
    MOV A, KEY_VALUE
    LCALL PROCESS_KEY
    SJMP MAIN_LOOP

; 按键扫描程序 - 检测是否有按键按下
KEY_SCAN:
    MOV KEY_PORT, #0F0H  ; 设置低4位为输出0，高4位为输入1
    MOV A, KEY_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, KEY_PRESSED
    MOV KEY_FLAG, #0     ; 没有按键按下，重置标志位
    MOV A, #0FFH
    RET   

KEY_PRESSED:    ; 检查按键是否已经被处理过
    MOV A, KEY_FLAG
    JZ KEY_ALREADY_PROCESSED_NEXT
    LJMP KEY_ALREADY_PROCESSED
KEY_ALREADY_PROCESSED_NEXT: ;延时，再次确认按键
    ; 延迟消抖
    LCALL DELAY_10MS
    
    ; 再次确认按键
    MOV KEY_PORT, #0F0H
    MOV A, KEY_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, KEY_CONFIRMED
    
    ; 按键释放，返回
    MOV A, #0FFH
    RET

KEY_CONFIRMED:
    ; 设置按键已确认标志
    MOV KEY_FLAG, #1
    
    ; 扫描第一行
    MOV KEY_PORT, #0FEH
    MOV A, KEY_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, KEY_ROW1
    
    ; 扫描第二行
    MOV KEY_PORT, #0FDH
    MOV A, KEY_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, KEY_ROW2
    
    ; 扫描第三行
    MOV KEY_PORT, #0FBH
    MOV A, KEY_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, KEY_ROW3
    
    ; 扫描第四行
    MOV KEY_PORT, #0F7H
    MOV A, KEY_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, KEY_ROW4
    
    MOV A, #0FFH
    RET

KEY_ROW1:
    CJNE A, #0E0H, KEY_ROW1_COL2
    MOV A, #1  ; 数字键1
    RET
KEY_ROW1_COL2:
    CJNE A, #0D0H, KEY_ROW1_COL3
    MOV A, #2  ; 数字键2
    RET
KEY_ROW1_COL3:
    CJNE A, #0B0H, KEY_ROW1_COL4
    MOV A, #3  ; 数字键3
    RET
KEY_ROW1_COL4:
    MOV A, #10  ; 加法运算符+
    RET

KEY_ROW2:
    CJNE A, #0E0H, KEY_ROW2_COL2
    MOV A, #4  ; 数字键4
    RET
KEY_ROW2_COL2:
    CJNE A, #0D0H, KEY_ROW2_COL3
    MOV A, #5  ; 数字键5
    RET
KEY_ROW2_COL3:
    CJNE A, #0B0H, KEY_ROW2_COL4
    MOV A, #6  ; 数字键6
    RET
KEY_ROW2_COL4:
    MOV A, #11  ; 减法运算符-
    RET

KEY_ROW3:
    CJNE A, #0E0H, KEY_ROW3_COL2
    MOV A, #7  ; 数字键7
    RET
KEY_ROW3_COL2:
    CJNE A, #0D0H, KEY_ROW3_COL3
    MOV A, #8  ; 数字键8
    RET
KEY_ROW3_COL3:
    CJNE A, #0B0H, KEY_ROW3_COL4
    MOV A, #9  ; 数字键9
    RET
KEY_ROW3_COL4:
    MOV A, #12  ; 乘法运算符*
    RET

KEY_ROW4:
    CJNE A, #0E0H, KEY_ROW4_COL2
    MOV A, #0  ; 数字键0
    RET
KEY_ROW4_COL2:
    CJNE A, #0D0H, KEY_ROW4_COL3
    MOV A, #13  ; 清除键CLR
    RET
KEY_ROW4_COL3:
    CJNE A, #0B0H, KEY_ROW4_COL4
    MOV A, #14  ; 等于键=
    RET
KEY_ROW4_COL4:
    MOV A, #15  ; 除法运算符/
    RET

KEY_ALREADY_PROCESSED:
    MOV A, #0FFH
    RET


; 等待按键释放
WAIT_KEY_RELEASE:
    MOV KEY_PORT, #0F0H
    MOV A, KEY_PORT
    ANL A, #0F0H
    CJNE A, #0F0H, WAIT_KEY_RELEASE  ; 按键未释放继续等待
    LCALL DELAY_10MS  ; 延迟消抖
    RET

; 处理按键功能
PROCESS_KEY:        ;清除键处理
    ; 检查是否为清除键
    CJNE A, #13, PROCESS_EQUAL_KEY  ; CLR键
    LCALL CLEAR_ALL
    RET

PROCESS_EQUAL_KEY:            ;等号处理
    CJNE A, #14, PROCESS_ADD_KEY  ; =键
    LCALL CALCULATE
    RET

PROCESS_ADD_KEY:          ;加法运算符处理
    CJNE A, #10, PROCESS_SUB_KEY
    ; +运算符处理
    MOV A, CALC_DONE
    JZ OPERATOR_AFTER_CALC_NEXT  ; 计算完成后再次输入运算符处理
    LCALL OPERATOR_AFTER_CALC
OPERATOR_AFTER_CALC_NEXT:
    ; 检查是否是第一次输入运算符
    MOV A, INPUT_FLAG
    CJNE A, #1, OPERATOR_FIRST_TIME
    ; 显示语法错误
    MOV ERROR_FLAG, #SYNTAX_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET
    
OPERATOR_FIRST_TIME:
    MOV OPERATOR, #'+'
    MOV INPUT_FLAG, #1  ; 设置输入标志为NUM2
    MOV A, #'+'
    LCALL LCD_WRITE_DATA
    RET

PROCESS_SUB_KEY:
    CJNE A, #11, PROCESS_MUL_KEY
    ;检查是否需要连续运算
    MOV A, CALC_DONE
    JZ PROCESS_SUB_KEY_continue
    LCALL OPERATOR_AFTER_CALC
PROCESS_SUB_KEY_continue:
    ; 检查是否是第一个运算符
    MOV A, NUM2_EXIST
    JZ CHECK_NEGATIVE_INPUT
    ; 如果NUM2_EXIST不为0，说明已经输入了第二个操作数，不能再输入运算符
    ; 显示语法错误
    MOV ERROR_FLAG, #SYNTAX_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET

CHECK_NEGATIVE_INPUT:
    ; 检查是否是数字输入阶段的第一个字符
    MOV A, INPUT_FLAG
    JZ CHECK_NEGATIVE_NUM1  ; 输入NUM1阶段
    ; 输入NUM2阶段
    MOV A, OPERATOR
    JNZ CHECK_NEGATIVE_INPUT_CONTINUE
    ; 当前不存在操作符
    JMP PROCESS_MINUS_AS_OPERATOR
CHECK_NEGATIVE_INPUT_CONTINUE:
    ; -是负号
    JMP CHECK_NEGATIVE_NUM2
    
CHECK_NEGATIVE_NUM1:
    MOV A, NUM1_EXIST
    JNZ PROCESS_MINUS_AS_OPERATOR  ; NUM1_EXIST不为0说明不是第一个字符
    ; 是负号输入
    MOV A, NEGATIVE_INPUT_FLAG1
    JZ SET_NEGATIVE_FLAG_NUM1
    ; 已经设置过负号标志
    MOV ERROR_FLAG, #SYNTAX_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET
    
SET_NEGATIVE_FLAG_NUM1:
    MOV NEGATIVE_INPUT_FLAG1, #1
    MOV A, #'-'
    LCALL LCD_WRITE_DATA
    RET
CHECK_NEGATIVE_NUM2:
    ; MOV A, NUM2_EXIST
    ; JNZ PROCESS_MINUS_AS_OPERATOR  ; NUM2_EXIST不为0说明不是第一个字符
    MOV A, NEGATIVE_INPUT_FLAG2
    JZ SET_NEGATIVE_FLAG_NUM2
    ; 已经设置过负号标志
    MOV ERROR_FLAG, #SYNTAX_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET
SET_NEGATIVE_FLAG_NUM2:
    MOV NEGATIVE_INPUT_FLAG2, #1
    MOV A, #'-'
    LCALL LCD_WRITE_DATA
    RET
PROCESS_MINUS_AS_OPERATOR:
    MOV OPERATOR, #'-'
    MOV INPUT_FLAG, #1
    MOV A, #'-'
    LCALL LCD_WRITE_DATA
    RET

PROCESS_MUL_KEY:
    CJNE A, #12, PROCESS_DIV_KEY
    ; *运算符处理
    MOV A, CALC_DONE
    JZ OPERATOR_FIRST_TIME3
    LCALL OPERATOR_AFTER_CALC
    
OPERATOR_FIRST_TIME3:
    MOV A, INPUT_FLAG
    CJNE A, #1, OPERATOR_FIRST_TIME3_OK
    MOV ERROR_FLAG, #SYNTAX_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET
    
OPERATOR_FIRST_TIME3_OK:
    MOV OPERATOR, #'*'
    MOV INPUT_FLAG, #1
    MOV A, #'*'
    LCALL LCD_WRITE_DATA
    RET

PROCESS_DIV_KEY:
    CJNE A, #15, NOT_DIV
    ; /运算符处理
    MOV A, CALC_DONE
    JZ OPERATOR_FIRST_TIME4
    LCALL OPERATOR_AFTER_CALC
    
OPERATOR_FIRST_TIME4:
    MOV A, INPUT_FLAG
    CJNE A, #1, OPERATOR_FIRST_TIME4_OK
    MOV ERROR_FLAG, #SYNTAX_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET
    
OPERATOR_FIRST_TIME4_OK:
    MOV OPERATOR, #'/'
    MOV INPUT_FLAG, #1
    MOV A, #'/'
    LCALL LCD_WRITE_DATA
    RET

NOT_DIV:
    ; 数字键处理
    MOV TEMP, A
    
    ; 检查是否在计算完成后输入数字
    MOV A, CALC_DONE
    JZ NOT_AFTER_CALC
    LCALL CLEAR_ALL  ; 计算完成后输入数字则清空所有数据
    
NOT_AFTER_CALC:
    ; 检查数字是否超过255
    MOV A, INPUT_FLAG
    JZ CHECK_NUM1

CHECK_NUM2:
    ;设置num2存在
    MOV NUM2_EXIST, #1
    MOV A, NUM2
    MOV B, #10
    MUL AB
    ; 检查乘法结果是否超过255
    MOV R0, B  ; 高位
    CJNE R0, #0, NUM2_OVERFLOW_ERROR
    MOV TEMP, A  ; 保存乘法结果
    MOV A, KEY_VALUE  ; 新输入的数字
    ADD A, TEMP
    JC NUM2_OVERFLOW_ERROR
    MOV NUM2, A
    SJMP DISPLAY_NUMBER

NUM2_OVERFLOW_ERROR:
    MOV ERROR_FLAG, #OVERFLOW_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET

CHECK_NUM1:
    MOV NUM1_EXIST, #1
    MOV A, NUM1
    MOV B, #10
    MUL AB
    ; 检查乘法结果是否超过255
    MOV R0, B  ; 高位
    CJNE R0, #0, NUM1_OVERFLOW_ERROR
    MOV TEMP, A  ; 保存乘法结果
    MOV A, KEY_VALUE  ; 新输入的数字
    ADD A, TEMP
    JC NUM1_OVERFLOW_ERROR
    MOV NUM1, A
    SJMP DISPLAY_NUMBER

NUM1_OVERFLOW_ERROR:
    MOV ERROR_FLAG, #OVERFLOW_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET

DISPLAY_NUMBER:
    MOV A, KEY_VALUE
    ADD A, #'0'
    LCALL LCD_WRITE_DATA
    RET

; 计算完成后输入运算符的处理
OPERATOR_AFTER_CALC:
    ; 清屏
    LCALL LCD_CLEAR
    MOV NUM1, RESULT
    MOV NEGATIVE_INPUT_FLAG1, SIGN_FLAG
    MOV NUM1_EXIST, #1

    ;清空其他存储变量
    MOV NUM2, #0
    MOV RESULT, #0
    MOV REMAINDER, #0
    MOV OPERATOR, #0
    MOV INPUT_FLAG, #0
    MOV KEY_FLAG, #0
    MOV CALC_DONE, #0
    MOV SIGN_FLAG, #0
    MOV ERROR_FLAG, #0
    MOV NEGATIVE_INPUT_FLAG2, #0
    MOV NUM2_EXIST, #0
    ;在屏幕上显示NUM1的负号（若NEGATIVE_INPUT_FLAG1 = 1）
    MOV A, NEGATIVE_INPUT_FLAG1
    JZ DISPLAY_NUM1_VALUE
    MOV A, #'-'
    LCALL LCD_WRITE_DATA
DISPLAY_NUM1_VALUE:
    ; 在屏幕上显示NUM1
    MOV A, NUM1
    LCALL DISPLAY_RESULT_NUMBER
    RET

; LCD初始化
LCD_INIT:
    LCALL DELAY_15MS
    MOV LCD_DATA, #38H
    CLR LCD_RS
    CLR LCD_RW
    SETB LCD_E
    CLR LCD_E
    LCALL DELAY_5MS
    
    MOV LCD_DATA, #0CH
    CLR LCD_RS
    CLR LCD_RW
    SETB LCD_E
    CLR LCD_E
    LCALL DELAY_5MS
    
    MOV LCD_DATA, #06H
    CLR LCD_RS
    CLR LCD_RW
    SETB LCD_E
    CLR LCD_E
    LCALL DELAY_5MS
    
    MOV LCD_DATA, #01H
    CLR LCD_RS
    CLR LCD_RW
    SETB LCD_E
    CLR LCD_E
    LCALL DELAY_5MS
    RET

; 清屏
LCD_CLEAR:
    MOV LCD_DATA, #01H
    CLR LCD_RS
    CLR LCD_RW
    SETB LCD_E
    CLR LCD_E
    LCALL DELAY_5MS
    RET

; 写命令到LCD
LCD_WRITE_CMD:
    CLR LCD_RS
    CLR LCD_RW
    MOV LCD_DATA, A
    SETB LCD_E
    CLR LCD_E
    LCALL DELAY_5MS
    RET

; 写数据到LCD
LCD_WRITE_DATA:
    SETB LCD_RS
    CLR LCD_RW
    MOV LCD_DATA, A
    SETB LCD_E
    CLR LCD_E
    LCALL DELAY_5MS
    RET

; 设置LCD显示位置
LCD_SET_POS:
    CLR LCD_RS
    CLR LCD_RW
    ORL A, #80H
    MOV LCD_DATA, A
    SETB LCD_E
    CLR LCD_E
    LCALL DELAY_5MS
    RET

; 在LCD上显示字符串
LCD_DISPLAY_STRING:
    PUSH ACC
LCD_DISPLAY_LOOP:
    CLR A
    MOVC A, @A+DPTR
    JZ LCD_DISPLAY_END
    LCALL LCD_WRITE_DATA
    INC DPTR
    SJMP LCD_DISPLAY_LOOP
LCD_DISPLAY_END:
    POP ACC
    RET

; 清除所有数据
CLEAR_ALL:
    MOV NUM1, #0
    MOV NUM2, #0
    MOV RESULT, #0
    MOV REMAINDER, #0
    MOV OPERATOR, #0
    MOV INPUT_FLAG, #0
    MOV KEY_FLAG, #0
    MOV CALC_DONE, #0
    MOV SIGN_FLAG, #0
    MOV ERROR_FLAG, #0
    MOV NEGATIVE_INPUT_FLAG1, #0
    MOV NEGATIVE_INPUT_FLAG2, #0
    MOV NUM1_EXIST, #0
    MOV NUM2_EXIST, #0
    LCALL LCD_CLEAR
    RET

; 计算结果
CALCULATE:
    MOV A, OPERATOR
    JZ TO_SYNAX_ERROR
    MOV A, NUM1_EXIST
    JZ TO_SYNAX_ERROR
    MOV A, NUM2_EXIST
    JZ TO_SYNAX_ERROR
    ; 如果所有条件都满足，应该跳转到实际计算部分
    LJMP CHECK_ADD

TO_SYNAX_ERROR:
    MOV ERROR_FLAG, #SYNTAX_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET
;加号
CHECK_ADD:
    MOV A, OPERATOR
    CJNE A, #'+', CHECK_SUB
    
    ; 检查NUM1是否为负数
    MOV A, NEGATIVE_INPUT_FLAG1
    JNZ CHECK_ADD_NUM1_NEGATIVE
    
    ; NUM1为正数
    MOV A, NEGATIVE_INPUT_FLAG2
    JNZ CHECK_ADD_NUM1_POS_NUM2_NEG
    ; NUM1正，NUM2正
    LJMP DO_ADD
    
CHECK_ADD_NUM1_POS_NUM2_NEG:
    ; NUM1正，NUM2负
    LJMP DO_SUB
    
CHECK_ADD_NUM1_NEGATIVE:
    ; NUM1为负数
    MOV A, NEGATIVE_INPUT_FLAG2
    JNZ CHECK_ADD_BOTH_NEGATIVE
    ; NUM1负，NUM2正
    MOV R0, NUM1
    MOV NUM1, NUM2
    MOV NUM2, R0
    LJMP DO_SUB
    
CHECK_ADD_BOTH_NEGATIVE:
    ; NUM1负，NUM2负
    MOV SIGN_FLAG, #1
    LJMP DO_ADD
    
;减号
CHECK_SUB:
    CJNE A, #'-', CHECK_MUL
    
    ;四种情况：num1正num2正、num1正num2负、num1负num2正、num1负num2负
    
    ; 检查NUM1是否为负数
    MOV A, NEGATIVE_INPUT_FLAG1
    JNZ CHECK_SUB_NUM1_NEGATIVE
    
    ; NUM1为正数
    MOV A, NEGATIVE_INPUT_FLAG2
    JNZ CHECK_SUB_NUM1_POS_NUM2_NEG
    ; NUM1正，NUM2正 - 执行普通减法
    LJMP DO_SUB
    
CHECK_SUB_NUM1_POS_NUM2_NEG:
    ; NUM1正，NUM2负 - 相当于加法 NUM1 + |NUM2|
    LJMP DO_ADD
    
CHECK_SUB_NUM1_NEGATIVE:
    ; NUM1为负数
    MOV A, NEGATIVE_INPUT_FLAG2
    JNZ CHECK_SUB_BOTH_NEGATIVE
    ; NUM1负，NUM2正 - 相当于 -(NUM1 + NUM2)
    MOV SIGN_FLAG, #1
    LJMP DO_ADD
    
CHECK_SUB_BOTH_NEGATIVE:
    ; NUM1负，NUM2负 - 相当于 |NUM2| - |NUM1|
    MOV R0, NUM1
    MOV NUM1, NUM2
    MOV NUM2, R0
    LJMP DO_SUB

; 乘号 
CHECK_MUL:
    CJNE A, #'*', CHECK_DIV
    
    ; 使用异或运算判断结果符号
    MOV A, NEGATIVE_INPUT_FLAG1
    XRL A, NEGATIVE_INPUT_FLAG2  ; 异或运算
    JZ CHECK_MUL_RESULT_POSITIVE ; 如果结果为0，说明符号相同，结果为正
    
    ; 符号不同，结果为负
    MOV SIGN_FLAG, #1
    
CHECK_MUL_RESULT_POSITIVE:
    LJMP DO_MUL

; 除号
CHECK_DIV:
    CJNE A, #'/', TO_CALC_END
    
    ; 使用异或运算判断结果符号
    MOV A, NEGATIVE_INPUT_FLAG1
    XRL A, NEGATIVE_INPUT_FLAG2  ; 异或运算
    JZ CHECK_DIV_RESULT_POSITIVE ; 如果结果为0，说明符号相同，结果为正
    
    ; 符号不同，结果为负
    MOV SIGN_FLAG, #1
    
CHECK_DIV_RESULT_POSITIVE:
    LJMP DO_DIV
    
; 计算结束
TO_CALC_END:
    LJMP CALC_END

;运算执行
DO_ADD:
    ; 加法运算
    MOV A, NUM1
    ADD A, NUM2
    MOV RESULT, A
    JNC DISPLAY_RESULT
    ; 结果大于255溢出
    MOV ERROR_FLAG, #OVERFLOW_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET

DO_SUB:
    MOV A, NUM1
    CLR C
    SUBB A, NUM2
    MOV RESULT, A
    JNC DO_SUB_POSITIVE      ; 结果为正数
    ; 结果为负数
    MOV SIGN_FLAG, #1     ; 设置负数标志
    CPL A                 ; 求反
    ADD A, #1             ; 加1得到补码
    MOV RESULT, A
    SJMP DISPLAY_RESULT
DO_SUB_POSITIVE:
    MOV SIGN_FLAG, #0
    SJMP DISPLAY_RESULT

DO_MUL:
    MOV A, NUM1
    MOV B, NUM2
    MUL AB
    ; 检查结果是否超过255
    MOV R0, B  ; 保存高位到临时变量
    CJNE R0, #0, MUL_OVERFLOW_ERROR ; 如果高位不为0，则结果超过255
    MOV RESULT, A  ; 直接将A中的低位结果存入RESULT
    SJMP DISPLAY_RESULT
    
MUL_OVERFLOW_ERROR:
    MOV ERROR_FLAG, #OVERFLOW_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET

DO_DIV:
    MOV A, NUM2
    JZ DIV_ZERO  ; 除数为0错误
    MOV A, NUM1
    MOV B, NUM2
    DIV AB
    MOV RESULT, A     ; 保存商
    MOV REMAINDER, B  ; 保存余数
    LJMP DISPLAY_DIV_RESULT

DIV_ZERO:
    MOV ERROR_FLAG, #MATH_ERROR_FLAG
    LCALL SHOW_SPECIFIC_ERROR
    RET

DISPLAY_RESULT:     ; 结果从第二行开始输出
    MOV A, #40H        
    LCALL LCD_SET_POS
    MOV A, #'='
    LCALL LCD_WRITE_DATA
    
    ; 如果是负数先显示负号
    MOV A, SIGN_FLAG
    JZ SKIP_NEGATIVE_SIGN
    MOV A, #'-'
    LCALL LCD_WRITE_DATA
SKIP_NEGATIVE_SIGN:

    ; 将结果转换为ASCII码显示
    MOV A, RESULT
    LCALL DISPLAY_RESULT_NUMBER
    
    ; 设置计算完成标志
    MOV CALC_DONE, #1
    ; 清除负数输入标志
    MOV NEGATIVE_INPUT_FLAG1, #0
    RET

; 将结果数字显示在LCD上
DISPLAY_RESULT_NUMBER:
    MOV B, #100
    DIV AB
    MOV TEMP, B  ; 存储余数
    ; 检查百位是否为0
    JZ NO_HUNDREDS2
    ADD A, #'0'
    LCALL LCD_WRITE_DATA
    MOV A, #1  ; 设置十位标志
    SJMP DISPLAY_TENS2
NO_HUNDREDS2:
    MOV A, #0  ; 清除十位标志
    
DISPLAY_TENS2:
    MOV B, A  ; 保存十位标志
    MOV A, TEMP
    MOV TEMP, B  ; TEMP中存储十位标志
    MOV B, #10
    DIV AB
    ; 如果百位不为0则显示十位，否则检查十位是否为0
    MOV R0, A  ; 保存十位数字
    MOV A, TEMP  ; 获取十位标志
    JNZ DISPLAY_TENS_DIGIT2  ; 百位不为0则显示十位
    MOV A, R0
    JZ NO_TENS2  ; 百位为0且十位为0则不显示十位
    
DISPLAY_TENS_DIGIT2:
    MOV A, R0
    ADD A, #'0'
    LCALL LCD_WRITE_DATA
    
NO_TENS2:
    ; 显示个位
    MOV A, B
    ADD A, #'0'
    LCALL LCD_WRITE_DATA
    RET
CALC_END:
    RET

; 显示除法结果(商...余数)
DISPLAY_DIV_RESULT:
    MOV A, #40H        ; 结果从第二行开始输出
    LCALL LCD_SET_POS
    
    ;显示等号
    MOV A, #'='
    LCALL LCD_WRITE_DATA
    
    ; 如果是负数先显示负号
    MOV A, SIGN_FLAG
    JZ SKIP_NEGATIVE_SIGN_DIV
    MOV A, #'-'
    LCALL LCD_WRITE_DATA
SKIP_NEGATIVE_SIGN_DIV:

    ; 显示商
    MOV A, RESULT
    LCALL DISPLAY_RESULT_NUMBER
    
    ; 检查余数是否为0，如果为0则不显示余数部分
    MOV A, REMAINDER
    JZ SKIP_REMAINDER_DISPLAY  ; 如果余数为0，跳过余数显示
    
    ; 显示分隔符"..."
    MOV A, #'.'
    LCALL LCD_WRITE_DATA
    MOV A, #'.'
    LCALL LCD_WRITE_DATA
    MOV A, #'.'
    LCALL LCD_WRITE_DATA
    
    ; 如果是负数余数也显示负号
    MOV A, SIGN_FLAG
    JZ SKIP_NEGATIVE_REMAINDER
    MOV A, #'-'
    LCALL LCD_WRITE_DATA
    
SKIP_NEGATIVE_REMAINDER:
    ; 显示余数
    MOV A, REMAINDER
    LCALL DISPLAY_RESULT_NUMBER
    
SKIP_REMAINDER_DISPLAY:
    ; 设置计算完成标志
    MOV CALC_DONE, #1
    ; 清除负数输入标志
    MOV NEGATIVE_INPUT_FLAG1, #0
    RET

; 显示特定错误信息
SHOW_SPECIFIC_ERROR:
    LCALL LCD_CLEAR
    
    ; 根据错误标志显示相应错误信息
    MOV A, ERROR_FLAG
    CJNE A, #OVERFLOW_ERROR_FLAG, CHECK_SYNTAX_ERROR
    MOV DPTR, #OVERFLOW_MSG
    SJMP DISPLAY_ERROR_MSG
    
CHECK_SYNTAX_ERROR:
    CJNE A, #SYNTAX_ERROR_FLAG, CHECK_MATH_ERROR
    MOV DPTR, #SYNTAX_MSG
    SJMP DISPLAY_ERROR_MSG
    
CHECK_MATH_ERROR:
    CJNE A, #MATH_ERROR_FLAG, CHECK_GENERAL_ERROR
    MOV DPTR, #MATH_MSG
    SJMP DISPLAY_ERROR_MSG
    
CHECK_GENERAL_ERROR:
    MOV DPTR, #GENERAL_MSG
    
DISPLAY_ERROR_MSG:
    LCALL LCD_DISPLAY_STRING
    LCALL DELAY_1S
    LCALL CLEAR_ALL
    RET

; 延时程序
DELAY_15MS:
    MOV R6, #30
DELAY_15MS_1:
    MOV R7, #250
    DJNZ R7, $
    DJNZ R6, DELAY_15MS_1
    RET

DELAY_10MS:
    MOV R6, #20
DELAY_10MS_1:
    MOV R7, #250
    DJNZ R7, $
    DJNZ R6, DELAY_10MS_1
    RET

DELAY_5MS:
    MOV R6, #10
DELAY_5MS_1:
    MOV R7, #250
    DJNZ R7, $
    DJNZ R6, DELAY_5MS_1
    RET
 
DELAY_1S:
    MOV R5, #100
DELAY_1S_1:
    LCALL DELAY_10MS
    DJNZ R5, DELAY_1S_1
    RET

; 错误信息字符串
OVERFLOW_MSG:
    DB "OVERFLOW ERROR", 0
    
SYNTAX_MSG:
    DB "SYNTAX ERROR", 0
    
MATH_MSG:
    DB "MATH ERROR", 0
    
GENERAL_MSG:
    DB "GENERAL ERROR", 0

END
