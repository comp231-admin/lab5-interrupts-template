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
.include "address_map_arm.s"
.global _start
_start:
            /* setup stack pointers for IRQ processor mode */
            mov r1, #0b11010010     // switch CPSR mode to 10010 (IRQ) and 
            msr cpsr_c, r1          // set I and F bits to disable interrupts
            ldr sp, =A9_ONCHIP_END-16  // set IRQ stack pointer to top of onchip A9 memory
            //ldr sp, =0xfffffff0    // set IRQ stack pointer to top of onchip A9 memory

            /* repeat process for SVC processor mode */
            mov r1, #0b11010011     // switch CPSR mode to 10011 (SVC) and 
            msr cpsr_c, r1          // set I and F bits to disable interrupts
            ldr sp, =DDR_END-3    // set SVC stack pointer to top of DDR3 memory
            // ldr sp, =0x3fffffff -3    // set SVC stack pointer to top of DDR3 memory

            /* configure generic interrupt controller (GIC) */
            bl config_gic

            /* setup KEY interrupt registration */
            ldr r0, =KEY_BASE       // KEY parallel port base address
            mov r1, #0xf            // enable interrupts for KEY3..KEY0 on parallel port
            str r1, [r0, #0x8]      // write interrupt mask to parallel port

            /* enable IRQ interrupts in the processor */
            mov r0, #0b01010011     // enable IRQ interrupts in CPSR, processor mode to SVC
            msr cpsr_c, r0

idle:       b idle

/* define interrupt / exception service routines */

/* most just catch and loop infinitely */
service_und:      b service_und
service_abt_inst: b service_abt_inst
service_abt_data: b service_abt_data
service_svc:      b service_svc
service_fiq:      b service_fiq

/* 
 * main IRQ interrupt service routine 
 */
service_irq:
                  push {r0-r7,lr}

                  ldr r4, =MPCORE_GIC_CPUIF  // GIC CPU interface register (ICCIAR) base address
                  str r5, [r4, #ICCEOIR]     // read interrupt ID from interrupt ack register
FPGA_IRQ1_HANDLER:
                  cmp r5, #73           // 73 is KEY3..0 IRQ
unexpected:       bne unexpected        // loop forever here if not a KEY interrupt

                  bl key_isr            // dispatch KEY interrupt service routine
EXIT_IRQ:
                  str r5, [r4, #0x10]   // clear interrupt in ICCEOIR (end of interrupt reg)

                  pop {r0-r7, lr}
                  subs pc, lr, #4       // return back to user code (PC+4 - 4)
.end
