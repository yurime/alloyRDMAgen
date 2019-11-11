open util/integer

sig Node { }
sig Thr { host: one Node }
sig MemoryLocation { host: one Node }
one sig Top {}

sig Action { o, d: one Thr }

sig MemoryAction in Action{
	loc: one MemoryLocation
}{
	loc.host=d.host
}

sig Writer in MemoryAction {
    wV: one Int
}

/*NIC action*/
abstract sig nA extends Action{
}

/*NIC Write*/
abstract sig nW extends nA{}
fact {all w:nW| w in Writer}

/*NIC remote write*/
sig nWpq extends nW{}
fact { all a: nWpq| not host[o[a]] = host[d[a]]}


fact { #(Action.o) = 2 and #(Action.d) = 2 }
fact { #MemoryLocation = 2 and #Thr = 2 and #nWpq = 1 and #(nWpq.loc) = 1 }

pred show {}

run show for 2
