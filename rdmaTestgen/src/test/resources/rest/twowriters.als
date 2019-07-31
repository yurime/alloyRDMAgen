open util/integer

sig Thr { }
sig MemoryLocation { host: one Thr }
sig Writer {
    wl: one MemoryLocation,
    wV: one (Int + Top)
}
sig InitialValue {}
one sig Top {}

fact { all w:Writer | w.wV = 4 }

fact { #MemoryLocation = 2 and #Thr = 2 and #Writer = 2 }

pred show {}

run show for 2
