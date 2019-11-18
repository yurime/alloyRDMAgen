open driver as d
//-------------
/**happens before (strong) consistency rules breaking**/
//-----------
/*
pred missPrevWrite8[e:Execution, a1,a2:Writer,a3:Reader] {
    a3 in a1.rf and // consistency 8
    a3 in a2.nic_ord_sw and
	a2 in nWpq and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}

/* Pivots for rule putOrRDMAatomic defined in  base_sw_rules */
//fact{nA1Pivot in Writer} 
//fact{nA2Pivot in Writer} 
//fact{Witness in Reader}

/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | missPrevWrite8[e_t,nA1Pivot, nA2Pivot, Witness]}
/* rule from driver*/
//fact{RDMAExecution_prime.Consistent=True}

fact{RDMAaction in RDMAaction_prime}
fact{all a:Sx| 
  a.sw_prime=a.instr_sw
}
fact{all a:nA| 
   a.sw_prime=a.nic_ord_sw_prime+a.poll_cq_sw+a.instr_sw
}


// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules

------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e_f=RDMAExecution_prime, e_t=RDMAExecution |
  (e_f.hb) = (^(po_tc+rf +sw_prime+e_f.mos))
and (e_f.mo_next=e_t.mo_next -(nA1Pivot->nA2Pivot))
and (e_f.mo=^(e_f.mo_next))
}


fact{nic_ord_sw_prime={nic_ord_sw - (nA2Pivot->Witness)}}


// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }

//order-sw prevents it

run show for 12 //works for 12  not for 11 (77217ms)
//run consist_lw_nwpq for 12
/*
run consist_lw_lw for 12 
run consist_lw_nwp for 10 
run consist_nwp_lw for 12 
/*-------------------------------------------------------------------------------
run consist_nwpq_nwp for 14 
run consist_nwpq_lw for 14
run consist_nwpq_nwpq for 4 expect 0
run consist_nwp_nwp for 4 expect 0
*/
