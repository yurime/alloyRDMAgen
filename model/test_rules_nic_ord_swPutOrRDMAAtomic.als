open base_sw_rules as bsr
open execution as e
//-------------
/**nic-ord-sw**/
//-----------


/* Pivots for rule putOrRDMAatomic */
one sig nA1Pivot in nWpq{} 
one sig nA2Pivot in nWpq{}

/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {putOrRDMAatomic[nA1Pivot,nA2Pivot]}

sig nA_prime in nA {
	nic_ord_sw_prime: set nA
}
fact{nA in nA_prime}

fact{nic_ord_sw_prime={nic_ord_sw - (nA1Pivot->nA2Pivot)}}

sig RDMAaction_prime in RDMAaction {
	sw_prime: set Action
}
fact{RDMAaction in RDMAaction_prime}
fact{all a:Sx| 
  a.sw_prime=a.instr_sw
}
fact{all a:nA| 
   a.sw_prime=a.nic_ord_sw_prime+a.poll_cq_sw+a.instr_sw
}

/* Execution_prime.hbs is acyclic */


/* Execution.hbs is cyclic, and the reader pivot is involved in the cycle */
//fact {RDMAExecution.Robust=False 
//         and {let e=RDMAExecution | nA1Pivot+Witness in nA2Pivot.(e.hbs + e.mo)}
//}

/* Witness */
one sig Witness in Reader {}
/* Witness2 */
one sig Witness2 in Reader {}
------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
one sig RDMAExecution_prime extends Execution{ }{
  hb = ^(po_tc+rf+sw_prime)

//mo basic definition

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


//hbs definition 
  hbs=^(hbqp+mos)
}// end of sig RDMAexecution

fact {RDMAExecution_prime.mo =RDMAExecution.mo}
//mo_s definition
fact  {RDMAExecution_prime.mos=RDMAExecution.mos}

