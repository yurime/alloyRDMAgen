open util/integer

sig Thr { }
sig MemoryLocation { host: one Thr }
sig Action {
    o, d: one Thr
}
sig Writer extends Action {
    wl: one MemoryLocation,
    wV: one (Int + Top)
}
one sig Top {}

sig InitialValue extends Writer { }

fact { all w:Writer | w.wV = 4 }
fact { all ml:MemoryLocation | one w:Writer | w.wl = ml }

fact { #MemoryLocation = 2 and #Thr = 2 and #InitialValue = 2 }

pred show {}

run show for 2
