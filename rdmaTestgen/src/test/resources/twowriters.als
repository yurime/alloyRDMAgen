open util/integer

sig Node { }
sig Thr { host: one Node }
sig MemoryLocation { host: one Node }

sig Action { o, d: one Thr }
sig Writer extends Action {
    wl: one MemoryLocation,
    wV: one Int
}
sig InitialValue {}

fact { all w:Writer | w.wV = 4 }

fact { #MemoryLocation = 2 and #(MemoryLocation.host) = 2 and #Writer = 2 }

pred show {}

run show for 2
