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
   (cyclic_MoThenHbs or readAndMissPrevWriteInHbs
   or tsoBufferCoherence1of3
   or tsoBufferCoherence3of3)
   implies Consistent=False else Consistent=True
  }
}



pred hb_cyclic[e:Execution] {
      cyclic[e.hb]
}

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
//one sig TestExecution extends Execution{}
pred p { 
           #Cas = 1 and
            #Thr = 2}
/*using sw_rules.als predicates: getThenPutF, putAfterPut, putAndCas */
run getThenPutF for 13
run putAfterPut for 12
run putAndCas for 11
run p for 11
