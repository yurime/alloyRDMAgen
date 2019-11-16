open util/integer
sig Node {}

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
/*CPU write*/
sig W extends LocalCPUaction{}
fact {all w:W| w in Writer and not(w in Reader)}


sig Init extends W { }

// assign some initial value
fact { all w:Writer | w.wV = 4 }

// there is at least one write to each memory location
fact { all ml:MemoryLocation | some w:Writer | w.loc = ml }
// ... and one initial value
fact { all ml:MemoryLocation | some iv:Init | iv.loc = ml }

// w succeeds initial value
fact { all iv : Init | one w:Writer | w in po[iv] }

// initial value is indeed initial
fact { all iv : Init | no w:Writer | iv in po[w] }

// partial order doesn't have cycles
fact { no a: Action | a in a.^po }

// po doesn't cross threads
fact { all x,y : Action | x in po[y] => x.o = y.o }

// not all actions belong to same thread
fact { some x, y : Action | not (x.o = y.o) }

fact { #Thr = 2 and  #MemoryLocation = 2 and #Init = 2 and #(W-Init) = 3}

pred show {}

run show for 5
