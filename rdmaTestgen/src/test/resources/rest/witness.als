open util/integer

sig Thr { }
sig MemoryLocation { host: one Thr }
abstract sig Action {
    o, d: one Thr,
    po: set Action
}
one sig Top {}

/* Locals */
sig Register {
	host: one Thr
}

fact { all r: Register| host[r] = o[~reg[r]] }

abstract sig Statement {
	actions: set ExternalAction
}

abstract sig LocalAction extends Action {
	poico: set Action
}

fact { all l: LocalAction| o[l] = d[l]}
abstract sig ExternalAction extends Action {
}

abstract sig RemoteAction extends ExternalAction {
	eactions: set ExternalAction
}
abstract sig ExternAction extends ExternalAction {}

sig Writer in Action {
    wl: one MemoryLocation,
    wV: one (Int)
}

abstract sig RemoteWrite extends RemoteAction {}

fact {all a: RemoteWrite |
				a in Writer and
				not (a in Reader)}

sig ExternWrite extends ExternAction {
}
fact {all a: ExternWrite |
				a in Writer
				and not (a in Reader)
}

sig RemoteReadWrite extends RemoteAction{
	corga2: one ExternWrite
}

sig Reader in Action {
    rl: one MemoryLocation,
    rV: one Int
}

sig ExternRead extends ExternAction {

	coput: lone RemoteWrite,
	corga1: lone RemoteReadWrite
}

fact {all a: ExternRead |
				a in Reader and
				not (a in Writer)}

/* =============== */
/* Remote Put statement */
/* =============== */

sig Rp extends Statement {}

fact { all r: Rp | #r.actions = 2 and #(r.actions & ExternRead) = 1 and #(r.actions & RemoteWrite) = 1}

fact {all disj r: ExternRead, w: RemoteWrite |
		(~actions[r] = ~actions[w]  and ~actions[w] in Rp) iff
			w in coput[r]
}

fact {all disj r: ExternRead, w: RemoteWrite |
		(~actions[r] = ~actions[w]  and ~actions[w] in Rp) iff
			(rV[r] = wV[w] and w in po[r] and
			 r = eactions[w])
}

fact {all disj e1, e2: ExternalAction, a: Action |
		~actions[e1] = ~actions[e2] implies not (e1 in po[a] and a in po[e2])
}

fact { all r : Rp | (r.actions & ExternRead).d = (r.actions & RemoteWrite).d }
fact { all er : ExternRead | #(po[er]) = 1 }

abstract sig Write extends LocalAction {}
fact {all a: Write |
				a in Writer and
				not (a in Reader)}
sig AWrite extends Write {}
sig InitialValue extends AWrite { }

sig Atomic in Action { }

/* ====== */
/* local read */
/* ====== */
abstract sig Read extends LocalAction {
	reg: one Register
}

fact {all a: Read |
				a in Reader and
				not (a in Writer)}

sig ARead extends Read {}
fact {all a: ARead | a in Atomic}

/* Witness */

sig Witness in Read {}

fact {#Witness = 1}

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

fact { #MemoryLocation = 2 and #Thr = 2 and #InitialValue >= 2 and #Rp = 1}

pred show {}

run show for 6
