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
    corga1: lone RemoteReadWrite
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

/* ======================= */
/* Remote Get Accumulate statement */
/* ======================= */

sig Rga extends Statement {}

fact { all r: Rga | #r.actions = 3 and 
							#(r.actions & ExternWrite) = 1 and 
							#(r.actions & ExternRead) = 1 and 
							#(r.actions & RemoteReadWrite) = 1
}


fact {all disj r: ExternRead, rw: RemoteReadWrite |
		(~actions[r] = ~actions[rw] and 
		 ~actions[r] in Rga)
		 iff (rw in corga1[r])
}

fact {all disj w: ExternWrite, rw: RemoteReadWrite |
		(~actions[w] = ~actions[rw] and 
		 ~actions[w] in Rga)
		 iff (w in corga2[rw])
}

fact {all disj r: ExternRead, w: ExternWrite, rw: RemoteReadWrite |
		(~actions[r] = ~actions[w] and 
		 ~actions[w] = ~actions[rw] and 
		 ~actions[w] in Rga)
		 iff 
			(wV[rw] = wV[w] and 
			 wV[rw] = rV[r].plus[rV[rw]] and 

			 (rw in po[r]) and 
			 (w in po[rw]) and 

			 (r in eactions[rw]) and 
			 (w in eactions[rw]) and 
			 #eactions[rw] = 2)
}

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

fact { #MemoryLocation = 2 and #Thr = 2 and #InitialValue = 2 and #Rga = 1}

pred show {}

run show for 8
