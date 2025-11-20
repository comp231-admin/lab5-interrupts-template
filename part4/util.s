.global seg7_code, divide

bit_codes:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

seg7_code:  ldr     r1, =bit_codes  
            ldrb    r0, [r1, r0]    
            bx      lr              

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0
 */
divide:   mov     r2, #0          
cont:     cmp     r0, r1         
          blt     div_end         
          sub     r0, r0, r1         
          add     r2, r2, #1          
          b       cont            
div_end:  mov     r1, r2          // return quotient in r1 (remainder in r0)
          bx      lr   
