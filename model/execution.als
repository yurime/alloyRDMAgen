open actions as a
open sw_rules as swr

// definition of hb and hbs


one sig Execution {
// actions: set Actions,
// po: Action->Action,
// rf: Action->Action,
// sw: Action->Action,
 mo: Writer->Writer,
 mos: Writer->Writer,
 hb: Action-> set Action,
 hbs: Action->set Action,
 hbqp: Action->set Action
}{
  hb = ^(po+rf+sw)

//mo definition
  {all w1,w2:Writer | w1 in w2.^mo iff (d[w1]=d[w2])}

//hbqp definition
  {all disj a,b: Action| 
    (b in a.hbqp)
    iff(
    (b in a.hb) and
    (
      (not a in nWpq)
       or
      (a + b in nA and o[a]=o[b] and d[a]=d[b])
    )
   )//end iff
  }// end hbqp defintion

//mo_s definition
   mos in mo
  {all w1,w2:Writer | w1 in w2.^mos iff (w2 in nRWpq+U+nWp)}

//hbs definition 
  hbs=^(hbqp+mos)
}
pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            #Put = 2 and
            #poll_cq = 2  and
			 #(Sx & Sx.po) > 0 and
			 #(poll_cq & Sx_put.po) > 0 and
            #Thr = 2}

run p for 10
