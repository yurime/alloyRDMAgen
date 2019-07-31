open util/integer

sig Thr { }
sig MemoryLocation { host: one Thr }
sig Action {
    o, d: one Thr,
    po: set Action
}
sig Writer extends Action {
    wl: one MemoryLocation,
    wV: one (Int + Top)
}
sig AWrite extends Writer {
}

one sig Top {}

sig InitialValue extends Writer { }

// assign some initial value
fact { all w:Writer | w.wV = 4 }

// there is at least one write to each memory location
fact { all ml:MemoryLocation | some w:Writer | w.wl = ml }
// ... and one initial value
fact { all ml:MemoryLocation | some iv:InitialValue | iv.wl = ml }

// awriter succeeds initial value
fact { all iv : InitialValue | one aw:Writer | aw in po[iv] }

// initial value is indeed initial
fact { all iv : InitialValue | no aw:Writer | iv in po[aw] }

// partial order doesn't have cycles
fact { no a: Action | a in a.^po }

// po doesn't cross threads
fact { all x,y : Action | x in po[y] => x.o = y.o }

// not all actions belong to same thread
fact { some x, y : Action | not (x.o = y.o) }

fact { #MemoryLocation = 2 and #Thr = 2 and #InitialValue = 2 and #AWrite = 3 }

pred show {}

run show for 5
