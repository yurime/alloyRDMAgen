open execution as e

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
