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
 hbqp: Action->set Action,
 hbs: Action->set Action,
 Robust: Boolean
}{
  {
   (hb_cyclic  or cyclic_MoThenHbs or readAndMissPrevWriteInHbs
   or tsoBufferCoherence1of3 or tsoBufferCoherence2of3  
   or tsoBufferCoherence3of3  or tsoFenceViolation)
   implies Robust=False else Robust=True
  }
{all w1,w2:Writer | w1 in w2.mo_next <=> (w1 in w2.mo and #(w2.mo-w1.mo)=1)}
}



pred hb_cyclic[e:Execution] {
      cyclic[e.hb]
}

pred cyclic_MoThenHbs[e:Execution] {
      cyclic[(e.mo).(e.hbs)]
}

pred readAndMissPrevWriteInHbs [e:Execution] {
    some a,b,c:Action | c in a.rf and c in b.(e.hbs) and wl[a]=wl[b] and b in a.(e.mo)
}

pred tsoBufferCoherence1of3 [e:Execution]{some a,b,c:Action | 
    c in a.rf and 
    c in b.((e.mo) & (Action->(Action-nWpq))).sw.(e.hbs) and 
    wl[a]=wl[b] 
    and b in a.(e.mo)
}

pred tsoBufferCoherence2of3[e:Execution] {some a,b,c:Action | 
    c in a.rf and 
    (some d1,e1:Action |
        d1 in b.(e.mo) and
        e1 in d1.((e.hbs) & (nWpq->(nRpq+nRWpq))) and
        sameOandD[e1,d1] and
        c in e1.(e.hbs)
    ) and
    wl[a]=wl[b] 
    and b in a.(e.mo)
}

pred tsoBufferCoherence3of3 [e:Execution]{some a,b,c:Action | 
    c in a.rf and 
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


one sig RDMAExecution extends Execution{

}{
  hb = ^(po_tc+rf+sw)

//mo basic definition
  {all disj w1,w2:Writer | 
                 (host[wl[w1]]=host[wl[w2]]) 
                 <=> 
                ((w1 in w2.mo) or (w2 in w1.mo))
   }
   {mo=^mo}
   {not cyclic[mo]}

//hbqp definition
  hbqp in hb
  {all a: Action, b:a.hb|  b in a.hbqp
   <=>(
      (not a in nWpq)
       or
      (a + b in nA and sameOandD[a,b])// on the same queue pair
      or
      (b in a.rf)
      )
  }// end hbqp defintion

//mo_s definition
   mos in mo
  {all w1,w2:Writer| w2 in w1.mos iff w1 in nRWpq+U+nWp}

//hbs definition 
  hbs=^(hbqp+mos)

}// end of sig execution

pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            
            RDMAExecution.Robust=True and
            putAfterPut}

//check{RDMAExecution.Robust => not cyclic[(Execution.hb).^(Execution.mo)]} for 10 expect 1 //should fail so expect 1
run p for 10
