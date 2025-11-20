.global config_gic, config_hps_timer, config_keys
.include "address_map_arm.s"

/* config_gic - setup interrupt handling for keys  */
config_gic:
              push {lr}

              /* configure interrupt handling for HPS Timer (id 199) */

              // TODO insert configuration code here

              /* configure interrupt handling for FPGA KEYs (id 73) */
              mov r0, #73          // interrupt id for FPGA KEYs
              mov r1, #0x1         // target CPU mask (CPU0)
              bl config_interrupt

              /* configure GIC CPU interface */
              ldr r0, =MPCORE_GIC_CPUIF // GIC CPU interface base address
              ldr r1, =0xffff           // want all priority levels of interrupts
              str r1, [r0, #ICCPMR]     // write to mask register (ICCPMR)

              /* enable GIC CPU interface to forward interrupts to CPU */
              mov r1, #1
              str r1, [r0]              // write enable=1 to ICCICR

              /* enable GIC distributor interface to forward interrupts 
                 to GIC CPU interface                                   */
              ldr r0, =MPCORE_GIC_DIST  // base address of distributor control register
              str r1, [r0]              // write enable=1 to ICDDCR

              pop {pc}              // return


/* config_interrupt - enable a single interrupt
    r0 - id of interrupt
    r1 - cpu mask for interrupt target
*/
config_interrupt:
              push {r4-r5, lr}

              /* two main tasks:
               * 1. set target to cpu0 in processor target reigsters (ICDIPTRn)
               * 2. enable interrupt in set/enable register (ICDISERn)          */

              /* configure set-enable registers (ICDISERn) 
               *   reg_offset = (id / 32) * 4
               *   value = 1 << (id % 32)                                       */
              
              /* compute reg_offset */
              ldr r2, =MPCORE_GIC_DIST  // base address of set-enable registers (ICDISER)
              add r2, r2, #ICDISER
              lsr r4, r0, #3            // divide by 8 (32/4 == 8) to get byte index
              bic r4, r4, #3            // find word address containing our interrupt
              add r4, r2, r4            // compute ICDISER address for our interrupt

              /* compute value */
              and r2, r0, #0x1f         // clear high bits, preserving low 5 bits  (i.e. mod 32)
              mov r5, #1                // enable value
              lsl r2, r5, r2            // shift enable bit into correct place

              /* update set/enable bit */
              ldr r3, [r4]              // load our set/enable word
              orr r3, r3, r2            // turn on the bit for our interrupt
              str r3, [r4]              // update ICDISER with enabled bit

              /* configure interrupt processor target register (ICDIPTRn)
               *   one byte for each interrupt (i.e. 4 interrupts/word 
               *   reg_offset = (id / 4) * 4  (i.e. math cancels, do nothing)
               *   value = id % 32                                       */

               ldr r2, =MPCORE_GIC_DIST   // base address of processor target registers 
               add r2, r2, #ICDIPTR
               bic r4, r0, #3             // find word address containing our interrupt
               add r4, r2, r4		          // word address of ICDIPTR
               and r2, r0, #0x3           // clear high bits, preserving low 2 bits (i.e. mod 4)
               add r4, r2, r4             // add byte offset in word to computed address of ICDIPTRn

               strb r1, [r4]              // write cpu mask (parameter) to ICDIPTR

               pop {r4-r5, pc}

config_hps_timer:

            // TODO Implement this function

            bx  lr

config_keys:
            /* setup KEY interrupt registration */
            ldr r0, =KEY_BASE       // KEY parallel port base address 
            mov r1, #0xf            // enable interrupts for KEY3..KEY0 on parallel port
            str r1, [r0, #0x8]      // write interrupt mask to parallel port

            bx  lr
