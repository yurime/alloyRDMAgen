open util/integer

sig Thr { }
sig MemoryLocation { host: one Thr }
sig Action {
    o, d: one Thr,
    po: set Action
}
one sig Top {}

abstract sig Statement {
	actions: set ExternalAction
}

abstract sig LocalAction extends Action {
	poico: set Action
}

fact { all l: LocalAction| o[l] = d[l]}
abstract sig ExternalAction extends Action {}

abstract sig RemoteAction extends ExternalAction {
	eactions: set ExternalAction
}
abstract sig ExternAction extends ExternalAction {}

sig Writer in Action {
    wl: one MemoryLocation,
    wV: one (Int + Top)
}

sig ExternWrite extends ExternAction {
}

sig ExternRead extends ExternAction {
    cocas1: lone RemoteReadWrite
}

fact {all a: ExternWrite |
				a in Writer
				and not (a in Reader)
}

fact {all a: ExternRead |
				a in Reader
				and not (a in Writer)
}

sig Reader in Action {
    rl: one MemoryLocation,
    rV: one (Int + Top)
}
sig RemoteReadWrite extends RemoteAction {
	corga2: lone ExternWrite,
    cocas2: lone ExternWrite
}
fact {all a: RemoteReadWrite |
				a in Reader and
				a in Writer}

/* =============== */
/* Remote Cas statement */
/* =============== */

sig Rcas extends Statement {}
fact {all r: Rcas | #r.actions = 4 and
							#(r.actions & ExternRead) = 2 and
							#(r.actions & ExternWrite) = 1 and
							#(r.actions & RemoteReadWrite) = 1}

fact {all disj r: ExternRead, rw: RemoteReadWrite|

                (~actions[r] = ~actions[rw] and
                 ~actions[rw] in Rcas)
                iff
                rw in cocas1[r]
}

fact {all disj w: ExternWrite, rw: RemoteReadWrite|

                (~actions[rw] = ~actions[w] and
                 ~actions[rw] in Rcas)
                iff
                w in cocas2[rw]
}

fact {all disj rcomp, rnew: ExternRead, w: ExternWrite, rw: RemoteReadWrite|

                (~actions[rcomp] = ~actions[rnew] and
                 ~actions[rnew] = ~actions[rw] and
                 ~actions[rw] = ~actions[w] and
                 rnew in po[rcomp] and
                 ~actions[rw] in Rcas)
                iff
                        (rcomp in eactions[rw] and
                         rnew in eactions[rw] and
                         w in eactions[rw] and
                         #eactions[rw] = 3 and

                         rw in po[rnew] and
                         w in po[rw] and

                        ( (rV[rcomp] = rV[rw]) implies
                                (wV[rw] = rV[rnew]) else
                                (wV[rw] = rV[rw]) ) and

                        wV[w] = rV[rw]) }

abstract sig Write extends LocalAction {}
sig AWrite extends Write {}
sig InitialValue extends AWrite { }

fact { all iv : InitialValue | not (iv in Reader) }
fact { all w : AWrite | not (w in Reader) }

// assign some initial value
fact { all w:Writer | w.wV = 4 }

// there is at least one write to each memory location
fact { all ml:MemoryLocation | some w:Writer | w.wl = ml }
// ... and one initial value
fact { all ml:MemoryLocation | some iv:InitialValue | iv.wl = ml }

// a writer succeeds initial value
fact { all iv : InitialValue | one w:Writer | w in po[iv] }

// initial value is indeed initial
fact { all iv : InitialValue | no w:Writer | iv in po[w] }

// partial order doesn't have cycles
fact { no a: Action | a in a.^po }

// po doesn't cross threads
fact { all x,y : Action | x in po[y] => x.o = y.o }

// not all actions belong to same thread
fact { some x, y : Action | not (x.o = y.o) }

fact { #MemoryLocation = 2 and #Thr = 2 and #InitialValue = 2 and #Rcas = 1}

pred show {}

run show for 8
