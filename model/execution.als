open sw_rules as sw

// definition of hb and hbs

abstract sig Boolean {} // Ask Andrei:  why not use pred?
one sig True, False extends Boolean {}


abstract sig Execution {
// actions: set Actions,
// po: Action->Action,
// rf: Action->Action,
// sw: Action->Action,
 mo: Writer->set Writer,
 mo_next: Writer->lone Writer,
 mos: Writer->set Writer,
 hb: Action-> set Action,
 //hbqp: Action->set Action,
 hbs: Action->set Action,
 Consistent: Boolean
}{
//mo_s definition
   mos= (nRWpq+U) <: mo

  {
   ( hb_cyclic or cyclic_MoThenHb 
      or {some a1,a2:Writer,a3:Reader | 
         missPrevWrite3[a1,a2,a3]  
         or missPrevWrite4[a1,a2,a3]
         or missPrevWrite5[a1,a2,a3] 
         or missPrevWrite6[a1,a2,a3]
         or missPrevWrite7[a1,a2,a3] 
         or missPrevWrite8[a1,a2,a3]
         or missPrevWrite9[a1,a2,a3]
    })
   implies Consistent=False else Consistent=True
  }
}



pred hb_cyclic[e:Execution] {
      cyclic[e.hb]
}

pred cyclic_MoThenHb[e:Execution] {
      cyclic[(W<:(e.hb)).(e.mo)]//consistentcy 2
}


pred missPrevWrite3[e:Execution,a1,a2:Writer,a3:Reader] {
    a3 in a1.rf and // consistency 3
    a3 in a2.(e.hb) and 
	a2 not in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}

pred missPrevWrite4[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer|
    a3 in a1.rf and // consistency 4
    a4 in a2.(e.mo) and
	a3 in a4.po.(^instr_sw).(e.hb) and 
	a4 in W and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite5[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer |
    a3 in a1.rf and // consistency 5
    a4 in a2.(e.mo) and
	a3 in a4.(rf-po_tc).(e.hb) and 
	a4 in W and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite6[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer|
    a3 in a1.rf and // consistency 6
    a4 in a2.(e.mos) and
	a3 in a4.(e.hb) and 
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite7[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer |
    a3 in a1.rf and // consistency 7
    a4 in a2.(rf-nic_ord_sw) and
	a3 in a4.(e.hb) and 
	a2 in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite8[e:Execution, a1,a2:Writer,a3:Reader] {
    a3 in a1.rf and // consistency 8
    a2 in a3.nic_ord_sw and
	a2 in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
pred missPrevWrite9[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer |
    a3 in a1.rf and // consistency 8
    a4 in a2.(e.mo) and
    a3 in a4.(rf-nic_ord_sw).(e.hb) and
	a4 in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
/*
pred cyclic_MoThenHbs[e:Execution] {
      cyclic[(e.mo)+(e.hbs)]//consistentcy 1
}

pred readAndMissPrevWriteInHbs [e:Execution] {
    some a,b,c:Action | c in a.rf and c in b.(e.hbs) and loc[a]=loc[b] and b in a.(e.mo)
}//consistency 2

pred tsoBufferCoherence1of3 [e:Execution]{some a,b,c:Action | 
    c in a.rf and // consistency 3
    c in b.(e.mo).sw_s.(e.hbs) and 
    loc[a]=loc[b] 
    and b in a.(e.mo)
}


pred tsoBufferCoherence3of3 [e:Execution]{some a,b,c:Action | 
    c in a.rf and  // consistency 4
    c in b.(e.mo).(rf-po_tc).(e.hbs) and 
     loc[a]=loc[b] 
    and b in a.(e.mo)
}

pred tsoFenceViolation [e:Execution]{some a,b,c:Action | 
    c in a.rf and 
    c in b.(e.mos).(e.hbs) and 
     loc[a]=loc[b] 
    and b in a.(e.mo)
}
*/
//one sig TestExecution extends Execution{}
pred p { 
           #Cas = 1 and
            #Thr = 2}
/*using sw_rules.als predicates: getThenPutF, putAfterPut, putAndCas */
run getThenPutF for 13
run putAfterPut for 12
run putAndCas for 11
run p for 11
