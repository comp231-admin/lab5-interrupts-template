.global key_isr
.global hpstimer_isr
.include "address_map_arm.s"

/* key_isr - keypress interrupt service routine */
key_isr:
            // TODO implement key interrupt service routine

            bx lr

/* timer_isr - timer interrupt service routine */
hpstimer_isr:
            // TODO implement timer interrupt service routine

            bx lr
