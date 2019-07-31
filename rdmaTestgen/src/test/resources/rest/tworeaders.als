open util/integer

sig Thr { }
sig MemoryLocation { host: one Thr }
sig Action {
    o, d: one Thr,
}
sig Reader extends Action {
    rl: one MemoryLocation,
    rV: one (Int + Top)
}
sig ARead extends Reader {}
sig InitialValue {}
one sig Top {}

fact { all r:Reader | r.rV = 4 }

fact { #MemoryLocation = 2 and #Thr = 2 and #ARead = 2 }

pred show {}

run show for 2
