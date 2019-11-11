open util/integer


sig Node { }
sig Thr { host: one Node }
sig MemoryLocation { host: one Node }

sig Action { o, d: one Thr }

sig MemoryAction extends Action{
	loc: one MemoryLocation
}{
	loc.host=d.host
}

sig Writer extends MemoryAction {
    wV: one Int
}

sig Init extends Writer { }

fact { all w:Writer | w.wV = 4 }
fact { all ml:MemoryLocation | one w:Writer | w.loc = ml }

fact { #MemoryLocation = 2 and #Thr = 2 and #Init = 2 }

pred show {}

run show for 2
