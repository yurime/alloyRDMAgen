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

fact {all a: ExternWrite |
				a in Writer 
				and not (a in Reader)
}

sig Reader in Action {
    rl: one MemoryLocation,
    rV: one (Int + Top)
}
sig RemoteRead extends RemoteAction {
	coget: one ExternWrite
}
fact {all a: RemoteRead |
				a in Reader and 
				not (a in Writer)}

/* =============== */
/* Remote Get statement */
/* =============== */

sig Rg extends Statement {}
fact { all r: Rg | #r.actions = 2 and #(r.actions & RemoteRead) = 1 and #(r.actions & ExternWrite) = 1}

fact {all disj r: RemoteRead, w: ExternWrite | 
		(~actions[r] = ~actions[w]  and ~actions[w] in Rg) iff 
			w in coget[r]
}

fact {all disj r: RemoteRead, w: ExternWrite | 
		(~actions[r] = ~actions[w]  and ~actions[w] in Rg) iff 
			(rV[r] = wV[w] and w in po[r] and 
			w = eactions[r])
}

fact { all r : Rg | (r.actions & RemoteRead).d = (r.actions & ExternWrite).d }
fact { all rr : RemoteRead | #(po[rr]) = 1 }

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

fact { #MemoryLocation = 2 and #Thr = 2 and #InitialValue = 2 and #AWrite = 3 and #Rg = 1}

pred show {}

run show for 5
