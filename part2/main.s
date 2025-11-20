/* use ax directive modifiers to make allocatable and executable. */
.section .vectors, "ax"
            b _start            // reset vector
            b service_und       // undefined instruction vector
            b service_svc       // software interrupt vector (syscalls)
            b service_abt_inst  // aborted instruction (prefetch) vector
            b service_abt_data  // aborted data access vector
            .word 0             // unused
            b service_irq       // IRQ interrupt vector
            b service_fiq       // fast IRQ interrupt vector

.text
.global _start
.include "address_map_arm.s"
_start:
            /* setup stack pointers for IRQ processor mode */
            mov r1, #0b11010010     // switch CPSR mode to 10010 (IRQ) and 
            msr cpsr_c, r1          // set I and F bits to disable interrupts
            ldr sp, =0xfffffff0    // set IRQ stack pointer to top of onchip A9 memory

            /* repeat process for SVC processor mode */
            mov r1, #0b11010011     // switch CPSR mode to 10011 (SVC) and 
            msr cpsr_c, r1          // set I and F bits to disable interrupts
            ldr sp, =0x3fffffff -3    // set SVC stack pointer to top of DDR3 memory

            /* configure generic interrupt controller (GIC) */
            bl config_gic

            bl config_hps_timer     // configure HPS timer 0
            bl config_keys          // configure pushbutton KEYS port

            /* enable IRQ interrupts in the processor */
            mov r0, #0b01010011     // enable IRQ interrupts in CPSR, processor mode to SVC
            msr cpsr_c, r0

            ldr r5, =LEDR_BASE      // base address of LEDs
loop:
            ldr r3, COUNT           // global count variable
            str r3, [r5]            // write global count to LEDs
            b loop

/* define interrupt / exception service routines */

/* most just catch and loop infinitely */
service_und:      b service_und
service_abt_inst: b service_abt_inst
service_abt_data: b service_abt_data
service_svc:      b service_svc
service_fiq:      b service_fiq

/* main IRQ interrupt service routine */
service_irq:
                  push {r0-r7,lr}

                  ldr r4, =MPCORE_GIC_CPUIF   // GIC CPU interface register (ICCIAR) base address
                  ldr r5, [r4, #0x0c]         // read interrupt ID from interrupt ack register
FPGA_IRQ1_HANDLER:
                  cmp r5, #73                 // 73 is KEY3..0 IRQ
                  bne check_hps_timer

                  bl key_isr                  // dispatch KEY interrupt service routine
                  b EXIT_IRQ

check_hps_timer:
                  // TODO implement this code block 


unexpected:       bne unexpected              // loop forever here if not a KEY interrupt

EXIT_IRQ:
                  str r5, [r4, #0x10]         // clear interrupt in ICCEOIR (end of interrupt reg)

                  pop {r0-r7, lr}
                  subs pc, lr, #4             // return back to user code (PC+4 - 4)

/* global variables */

.global COUNT
.global RUN

COUNT:
.word 0
RUN:
.word 0x1
.end
