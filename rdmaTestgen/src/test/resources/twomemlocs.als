sig Node {}
sig Thr { host: one Node }
sig MemoryLocation { host: one Node }
sig Action { o, d: one Thr }

fact { #MemoryLocation = 2 and #Thr = 2 and #(Thr.host) = 2 and #(Action.o) = 2 and #(Action.d) = 2 }

pred show {}

run show for 2
