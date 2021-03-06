open util/integer

/* Machine with one or more Threads */
sig Node {}

/* Thread */
sig Thr {
	host: one Node // host node
}

sig MemoryLocation { host: one Node }

abstract sig Action {
    o, d: one Thr
}
abstract sig LocalCPUaction extends Action{
	/* program order */
    po: lone LocalCPUaction // for displaying po.	
}

sig MemoryAction in Action{
	loc: one MemoryLocation
}{
	loc.host=d.host
}

sig Reader in MemoryAction {
	rV: one Int,
	corf: one Writer
}


sig Writer in MemoryAction {
	wV: one Int,
	rf: set Reader
}

fact{~rf=corf}

sig Init extends W{}

/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}

// assign some initial value
fact { all w:W | w.wV = 4 }

// there is at least one write to each memory location
fact { all ml:MemoryLocation | some w:W | w.loc = ml }

// writer succeeds initial value
fact { all iv : Init | one aw:W | aw in po[iv] }

// initial value is indeed initial
fact { all iv : Init | no aw:W | iv in po[aw] }

// partial order doesn't have length-1 cycles
fact { no a : Action | a in po[a] }

// po doesn't cross threads
fact { all x,y : LocalCPUaction | x in po[y] => x.o = y.o }

// not all actions belong to same thread
fact { some x, y : Action | not (x.o = y.o) }

fact { #(MemoryLocation.host) = 2 and #Thr = 2 and #Init = 2}

pred show {}

run show for 4
