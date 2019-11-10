open actions as a

/* construction of sw */

fact{all a:Sx |
	a.sw = a.instr_sw
and
	a.sw_s = a.instr_sw
}

fact{all a:nA |
	a.sw = a.nic_ord_sw+a.poll_cq_sw+a.instr_sw
and 	a.sw_s = a.nic_ord_sw_s+a.poll_cq_sw_s+a.instr_sw
}

fact{all a:nA |
	(a in nWp) => a.poll_cq_sw_s= a.(~poll_cq_sw).instr_sw
	else a.poll_cq_sw_s=a.poll_cq_sw 
}

fact{all a:nA |
	(a in nWp) => a.nic_ord_sw_s= a.~nic_ord_sw_s.instr_sw
    else a.nic_ord_sw_s= a.nic_ord_sw
}

//-----------
/**instr-sw**/
//-----------
fact{all put:Put | // sx->nrp->nwpq
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nwpq=actions[put] & nWpq,
      nex=actions[put] & nEx{
          instr_sw[sx] = nrp and
          instr_sw[nrp] = nwpq and
		  instr_sw[nwpq]=nex and 
          #(instr_sw[nex])=0     
      }
}


fact{all get:Get | // sx->nrpq->nwp
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nwp=actions[get] & nWp,
      nex=actions[get] & nEx{
          instr_sw[sx] = nrpq and
          instr_sw[nrpq] = nwp and
		      instr_sw[nwp]=nex and 
          #(instr_sw[nex])=0
      }
}

fact{all rga:Rga | // sx->nrwpq->nwp
  let sx=actions[rga] & Sx_rga, 
      nrwpq=actions[rga] & nRWpq,
      nwp=actions[rga] & nWp,
      nex=actions[rga] & nEx{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		  instr_sw[nwp]=nex and 
          #(instr_sw[nex])=0
     }
}

fact{all cas:Cas | // sx->nrwpq->nwp
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nwp=actions[cas] & nWp,
      nex=actions[cas] & nEx{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		  instr_sw[nwp]=nex and 
          #(instr_sw[nex])=0
     }
}
fact{all put:PutF |// sx->nf->nrp->nwpq
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nf=actions[put] & nF,
      nwpq=actions[put] & nWpq,
      nex=actions[put] & nEx{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrp and
          instr_sw[nrp] = nwpq and
		  instr_sw[nwpq]=nex and 
          #(instr_sw[nex])=0
     }
}

fact{all get:GetF | // sx->nf->nrpq->nwp
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nf=actions[get] & nF,
      nwp=actions[get] & nWp,
      nex=actions[get] & nEx{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrpq and
          instr_sw[nrpq] = nwp and
		      instr_sw[nwp]=nex and 
          #(instr_sw[nex])=0
      }
}

fact{all rga:RgaF | // sx->nf->nrwpq->nwp
  let sx=actions[rga] & Sx_rga, 
      nrwpq=actions[rga] & nRWpq,
      nf=actions[rga] & nF,
      nwp=actions[rga] & nWp,
      nex=actions[rga] & nEx{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrwpq and
          instr_sw[nrwpq] = nwp and
		      instr_sw[nwp]=nex and 
          #(instr_sw[nex])=0
     }
}

fact{all cas:CasF | // sx->nf->nrwpq->nwp
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nf=actions[cas] & nF,
      nwp=actions[cas] & nWp,
      nex=actions[cas] & nEx{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrwpq and
          instr_sw[nrwpq] = nwp and
		      instr_sw[nwp]=nex and 
          #(instr_sw[nex])=0
     }
}

//-------------
/**nic-ord-sw**/
//-----------

fact{all a:nA | not a in nic_ord_sw[a]}

// predicates to define when nic_ord_sw is legal
pred putOrRDMAatomic [na1:nA,na2:nA] {
           (na2 in na1.ipo) and//forcing same queuepair and starting thread
  	       (remoteMachineAction[na1]) and   // sx1----->nWpq
	       (remoteMachineAction[na2]) and   // ↓po         ↓nic_ord_sw
	       (not na1 in nRpq)                         // sx2----->na2 
}

pred putLocalPart [na1:nA,na2:nA]{
           (na2 in na1.ipo) and//forcing same queuepair and starting thread
	      (na2+na1 in nRp)		// sx1----->nRp
											// ↓po         ↓nic_ord_sw
									        // sx2----->nRp 
}


pred nicFence [na1:nA,na2:nA] {
			(na2 in na1.ipo) and//forcing same queuepair and starting thread
            (na2 in nF)  // sx1-->nRpq-->nWp
	        				  // ↓po                  ↓nic_ord_sw
	       	                  // sx2-------------->nF                                                    
}

// (na1,na2) in nic_ord_sw definition (3 cases)
fact{all disj na1,na2:nA |
  (na2 in nic_ord_sw[na1]) 
  iff
  (  putOrRDMAatomic[na1,na2] 
	  or 
      putLocalPart[na1,na2]
	  or 
	  nicFence[na1,na2]
  )//end iff
}

//------------
/** poll_cq_sw **/
//------------

fact{poll_cq_sw=~co_poll_cq_sw}


fact{all disj na:nA, pcq:poll_cq  | 
          pcq=na.poll_cq_sw => pcq in (na.instr.actions & Sx).po_tc
}


fact{all disj na1, na2:nEx, pcq2:poll_cq | 
(pcq2=na2.poll_cq_sw
  and (na2 in na1.ipo))
=> (some pcq1:poll_cq| 
        (pcq2 in pcq1.po_tc)
        and pcq1=na1.poll_cq_sw
      )
}


fact {all nr:(nA&Reader),nw:(nA&Writer) | nw in nr.instr_sw => wV[nw]=rV[nr]}

/*pred p1 { 
           #PutF = 1 and
            #Sx_cas = 1 and
            #Thr = 2}

run p1 for 8
*/

pred p2 { 
           #Cas = 1 and
            #Thr = 2}

check{not cyclic[sw]} for 10 expect 0

run getThenPutF for 13
run putAfterPut for 12
run putAndCas for 10
run p2 for 8

