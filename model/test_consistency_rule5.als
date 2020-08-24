open driver as d
//-------------
/**happens before (strong) consistency rules breaking**/
//-----------

/* Pivots for rule putOrRDMAatomic defined in  base_sw_rules */
//fact{nA1Pivot in Writer} 
//fact{nA2Pivot in }
/*
pred missPrevWrite5[e:Execution, a1,a2:Writer,a3:Reader] {some a4:Writer |
    a3 in a1.rf and // consistency 5
    a4 in a2.(e.mo) and
	a3 in a4.(rf-po_tc).(e.hb) and 
	a4 in W and
    loc[a1]=loc[a2] 
    and a2 in a1.(e.mo)
}
/* Hypothesis of the nic-ord-sw put or RDMAatomic rule on the pivots */
fact {let e_t=RDMAExecution | missPrevWrite5[e_t,nA1Pivot, nA2Pivot, Witness]}
/* rule from driver*/
//fact{RDMAExecution_prime.Consistent=True}

------------------------------------------------------------------------
/** Definition of Execution_prime hb and hbs**/
------------------------------------------------------------------------
fact{let e_f=RDMAExecution_prime, e_t=RDMAExecution |
       (e_f.hb = e_t.hb)
//and (e_f.hbqp = e_t.hbqp)
and (e_f.mo_next=e_t.mo_next -(nA1Pivot->nA2Pivot))
and (e_f.mo=^(e_f.mo_next))
//and (e_f.hbs=^(po_tc+rf +sw_s+e_f.mos))
}

// sanity
//check {RDMAExecution.Consistent=False} expect 0
//Note that {RDMAExecution_prime.Consistent=true} comes from base_sw_rules
pred show { 
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2
        }

/*
run consist_lw_lw for 6 //works for 6 not for 5 (299ms.)

-------------------------------------------------------------------------------
run consist_nwp_nwpq for 8 //not for 10 (49522ms)
run consist_nwpq_lw for 12 //not for 10 (39601ms.)
run consist_nwp_lw for 10 // not for 10 (25052ms)
run consist_nwpq_nwp for 12  // not for 12 (251302ms)
run consist_lw_nwpq for 12 //not for 10 (79434ms) too long for 12
run consist_lw_nwp for 12 //  not for 10(89744ms) too long for 12
run consist_nwpq_nwpq for 10  //  not for 10  (46701ms.)
run consist_nwp_nwp for 10  //  not for 10  (46686ms.)
*/
