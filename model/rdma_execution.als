open execution as e
open sw_rules as sw

one sig RDMAExecution extends Execution{

}{
//mo basic definition
   {mo=^mo}
   {not cyclic[mo]}
    {mo_next=mo-mo.mo}

  {all disj w1,w2:Writer | 
                 (host[loc[w1]]=host[loc[w2]]) 
                 <=> 
                ((w1 in w2.mo) or (w2 in w1.mo))
   }
//{all w1,w2:Writer | w1 in w2.mo_next <=> (w1 in w2.mo and #(w2.mo-w1.mo)=1)}
{all i:Init, a:Writer-Init| not i in mo[a]}

  hb = ^(po_tc+rf+sw+mos)
/*
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
*/
//hbs definition 
  hbs=^(po_tc+rf +sw+mos)

}// end of sig execution

pred p { 
            //#(Action.o) > 1 and
            #Cas= 1}

pred getThenPutF_rdma{RDMAExecution.Consistent=True and getThenPutF}
pred putAfterPut_rdma{RDMAExecution.Consistent=True and putAfterPut}
pred putAndCas_rdma{RDMAExecution.Consistent=True and putAndCas}


//check{RDMAExecution.Robust => not cyclic[(Execution.hb).^(Execution.mo)]} for 10 expect 1 //should fail so expect 1
run getThenPutF_rdma for 13
run putAfterPut_rdma for 13
run putAndCas_rdma for 12
run getThenPutF for 13
run putAfterPut for 12
run putAndCas for 10
run p for 11
