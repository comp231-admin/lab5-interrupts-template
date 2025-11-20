.global key_isr
.include    "address_map_arm.s" 

/* key_isr - keypress interrupt service routine */
key_isr:
            ldr r0, =KEY_BASE           // base address of KEY parallel port
            //ldr r0, =0xff200050         // base address of KEY parallel port
            ldr r1, [r0, #0xc]          // read edge capture register
            mov r2, #0xf                
            str r2, [r0, #0xc]          // clear interrupt

            ldr r0, =LED_BASE           // base address of LED display

check_key0:
            mov r3, #0x1
            ands r3, r3, r1             // check for kEY0
            beq check_key1
            mov r2, #0b1        
            str r2, [r0]                // write 0x1 to LED
            b end_key_isr

check_key1:
            mov r3, #0x2
            ands r3, r3, r1             // check for kEY0
            beq check_key2
            mov r2, #0b10        
            str r2, [r0]                // write 0x2 to LED
            b end_key_isr

check_key2:
            mov r3, #0x4
            ands r3, r3, r1             // check for kEY0
            beq is_key3
            mov r2, #0b100        
            str r2, [r0]                // write 0x4 to LED
            b end_key_isr

is_key3:
            mov r2, #0b1000          
            str r2, [r0]                // write 0x8 to LED
            b end_key_isr

end_key_isr:
            bx lr
