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
//mo_next: Writer->lone Writer,
 mos: Writer->set Writer,
 hb: Action-> set Action,
 hbqp: Action->set Action,
 hbs: Action->set Action,
 Consistent: Boolean
}{
//mo basic definition
  {all disj w1,w2:Writer | 
                 (host[wl[w1]]=host[wl[w2]]) 
                 <=> 
                ((w1 in w2.mo) or (w2 in w1.mo))
   }
   {mo=^mo}
   {not cyclic[mo]}

//mo_s definition
   mos in mo
  {all w1,w2:Writer| w2 in w1.mos iff w1 in nRWpq+U+nWp}

  {
   (cyclic_MoThenHbs or readAndMissPrevWriteInHbs
   or tsoBufferCoherence1of3
   or tsoBufferCoherence3of3)
   implies Consistent=False else Consistent=True
  }
//{all w1,w2:Writer | w1 in w2.mo_next <=> (w1 in w2.mo and #(w2.mo-w1.mo)=1)}
{all i:Init, a:Writer-Init| not i in mo[a]}
}



pred hb_cyclic[e:Execution] {
      cyclic[e.hb]
}

pred cyclic_MoThenHbs[e:Execution] {
      cyclic[(e.mo).(e.hbs)]//consistentcy 1
}

pred readAndMissPrevWriteInHbs [e:Execution] {
    some a,b,c:Action | c in a.rf and c in b.(e.hbs) and wl[a]=wl[b] and b in a.(e.mo)
}//consistency 2

pred tsoBufferCoherence1of3 [e:Execution]{some a,b,c:Action | 
    c in a.rf and // consistency 3
    c in b.((e.mo) & (Action->(Action-nWpq))).sw.(e.hbs) and 
    wl[a]=wl[b] 
    and b in a.(e.mo)
}


pred tsoBufferCoherence3of3 [e:Execution]{some a,b,c:Action | 
    c in a.rf and  // consistency 4
    c in b.(e.mo).(rf-po_tc).(e.hbs) and 
    wl[a]=wl[b] 
    and b in a.(e.mo)
}

pred tsoFenceViolation [e:Execution]{some a,b,c:Action | 
    c in a.rf and 
    c in b.(e.mos).(e.hbs) and 
    wl[a]=wl[b] 
    and b in a.(e.mo)
}

/*using sw_rules.als predicates: getThenPutF, putAfterPut, putAndCas */
run {Execution.Consistent=True and getThenPutF} for 12
run {Execution.Consistent=True and putAfterPut} for 10
run {Execution.Consistent=True and putAndCas} for 8
