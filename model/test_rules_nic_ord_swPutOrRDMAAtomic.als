open driver as d
//-------------
/**nic-ord-sw**/
//-----------

/* Constructs tests where the sw edge between two nWpq on the same queue pair is removed*/
/* Checks if RDMA actualy generates that edge*/ 
/* In this test the nA1Pivot --mo-->nA2Pivot si created in the other dirrection*/ 

/* Pivots for rule putOrRDMAatomic */
fact{nA1Pivot in nWpq} 
fact{nA2Pivot in nWpq}

/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {putOrRDMAatomic[nA1Pivot,nA2Pivot]}



fact{nic_ord_sw_prime={nic_ord_sw - (nA1Pivot->nA2Pivot)}}


fact{RDMAaction in RDMAaction_prime}
fact{all a:Sx| 
  a.sw_prime=a.instr_sw
}
fact{all a:nA| 
   a.sw_prime=a.nic_ord_sw_prime+a.poll_cq_sw+a.instr_sw
}

/* Execution_prime.hbs is acyclic */


/* Execution.hbs is cyclic, and the reader pivot is involved in the cycle */
//fact {RDMAExecution.Consistent=False 
//         and {let e=RDMAExecution | nA1Pivot+Witness in nA2Pivot.(e.hbs + e.mo)}
//}


------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e=RDMAExecution_prime |
  (e.hb) = ^(po_tc+rf+sw_prime)
}

fact{let e=RDMAExecution_prime |
//hbqp definition
  (e.hbqp) in (e.hb)
}
fact{let e=RDMAExecution_prime |
  {all a: Action, b:a.(e.hb)|  b in a.(e.hbqp)
   <=>(
      (not a in nWpq)
       or
      (a + b in nA and sameOandD[a,b])// on the same queue pair
      or
      (b in a.rf)
      )
  }// end hbqp defintion
}
fact{let e=RDMAExecution_prime |
//hbs definition 
  (e.hbs)=^((e.hbqp)+(e.mos))
}// end of sig RDMAexecution_prime rules

//The Witness definition
fact {Witness in nA1Pivot.rf and 
        Witness in nA2Pivot.(RDMAExecution_prime.hbs)
}

pred oneThread { #Thr = 1 }
pred twoThreads { #Thr = 2 }

// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules

/* Properties of the test */
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }


run {show} for 11
