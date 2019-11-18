open actions as a

/* construction of sw */

fact{all a:Sx |
	a.sw = a.instr_sw
//and
	//a.sw_s = a.instr_sw
}

fact{all a:nA |
	a.sw = a.nic_ord_sw+a.poll_cq_sw+a.instr_sw
//and 	a.sw_s = a.nic_ord_sw_s+a.poll_cq_sw_s+a.instr_sw
}
/*
if nRp--isw-->nWpq--isw-->nEx--pf->poll then 
   remove pf and set nRp--pf-->poll  
*/
/*fact{all a:nA |
	#(nWpq & (a.((~instr_sw) :> nA)))>0 => a.poll_cq_sw_s=none
	else a in nRp => a.poll_cq_sw_s=a.(instr_sw).(instr_sw).(poll_cq_sw)
	else a.poll_cq_sw_s=a.poll_cq_sw 
}

fact{all a:nA |
	(a in nWp) => a.nic_ord_sw_s= a.~nic_ord_sw.instr_sw
    else a.nic_ord_sw_s= a.nic_ord_sw
}
*/
//-----------
/**instr-sw**/
//-----------
fact{all i:Instruction| instr_sw[i.ex]=none}

fact{all put:Put | // sx->nrp->nwpq
          instr_sw[put.sx] = put.nrp and
          instr_sw[put.nrp] = put.nwpq and
		  instr_sw[put.nwpq]=put.ex   and
          instr_sw[put.ex]=none  
}


fact{all get:Get | // sx->nrpq->nwp
     instr_sw[get.sx] = get.nrpq and
     instr_sw[get.nrpq] = get.nwp and
	 instr_sw[get.nwp]=get.ex  and
     instr_sw[get.ex]=none 
}

fact{all rga:Rga | // sx->nrwpq->nwp
          instr_sw[rga.sx] = rga.nrwpq and
          instr_sw[rga.nrwpq] = rga.nwp and
		  instr_sw[rga.nwp]=rga.ex    and
          instr_sw[rga.ex]=none  
}

fact{all cas:Cas | // sx->nrwpq->nwp
          instr_sw[cas.sx] = cas.nrwpq and
          instr_sw[cas.nrwpq] = cas.nwp and
		  instr_sw[cas.nwp]=cas.ex    and
          instr_sw[cas.ex]=none  
}
fact{all put:PutF |// sx->nf->nrp->nwpq
          instr_sw[put.sx] = put.nf and
          instr_sw[put.nf] = put.nrp and
          instr_sw[put.nrp] = put.nwpq and
		  instr_sw[put.nwpq]=put.ex    and
          instr_sw[put.ex]=none  
}

fact{all get:GetF | // sx->nf->nrpq->nwp
          instr_sw[get.sx] =get.nf and
          instr_sw[get.nf] = get.nrpq and
          instr_sw[get.nrpq] = get.nwp and
          instr_sw[get.nwp]=get.ex  and
         instr_sw[get.ex]=none 
}

fact{all rga:RgaF | // sx->nf->nrwpq->nwp
          instr_sw[rga.sx] =rga.nf and
          instr_sw[rga.nf] = rga.nrwpq and
          instr_sw[rga.nrwpq] = rga.nwp and
	      instr_sw[rga.nwp]=rga.ex    and
          instr_sw[rga.ex]=none  
}

fact{all cas:CasF | // sx->nf->nrwpq->nwp
          instr_sw[cas.sx] = cas.nf and
          instr_sw[cas.nf] = cas.nrwpq and
          instr_sw[cas.nrwpq] = cas.nwp and
	      instr_sw[cas.nwp]=cas.ex   and
          instr_sw[cas.ex]=none  
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
			(na1 in nEx) and
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

// pcq is after (in po) the sx of the polled instruction
// and it is on the same queue pair
fact{all disj na:nEx, pcq:poll_cq  | 
          (pcq=na.poll_cq_sw => 
                      (
                         (pcq in na.instr.sx.po_tc)
                          and (sameOandD[pcq,na.instr.sx])
                      )
         )
}


fact{all disj na1, na2:nEx, pcq2:poll_cq | 
(pcq2=na2.poll_cq_sw
  and (na2 in na1.ipo))
=> #(na1.poll_cq_sw)>0
}


// values flow in rdma instructions
fact {all disj nr:(nA&Reader),nw:(nA&Writer) | 
          nw in nr.instr_sw => wV[nw]=rV[nr]}

/*pred p1 { 
           #PutF = 1 and
            #Sx_cas = 1 and
            #Thr = 2}

run p1 for 8
*/

pred p2 { 
           #Cas = 1 and
            #Thr = 2}

//check{not cyclic[sw]} for 10 expect 0

run getThenPutF for 13
run putAfterPut for 12
run putAndCas for 10
run p2 for 8

