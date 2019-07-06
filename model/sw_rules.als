open actions as a

/* construction of sw */
//-----------
/**instr-sw**/
//-----------
//defined per instruction in action file

fact{all a:Sx |
	a.sw = a.instr_sw
}
//check{all disj a1,a2:Sx | not instr_sw[a1]=instr_sw[a2] }
//forces check{all disj i1,i2:Instruction | #(actions[i1]&actions[i2])=0}
// i.e, holds for disj na1,na2 because actions[instr[na1]] has to hold sx and 
// instr will be different for different sx

fact{all a:nA |
	a.sw = a.nic_ord_sw+a.poll_cq_sw+a.instr_sw
}


fact{all put:Put | // sx->nrp->nwpq
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nwpq=actions[put] & nWpq{
          instr_sw[sx] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}

fact{all get:Get | // sx->nrpq->nwp
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nwp=actions[get] & nWp{
          instr_sw[sx] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
      }
}

fact{all rga:Rga | // sx->nrwpq->nwp
  let sx=actions[rga] & Sx_rga, 
      nrwpq=actions[rga] & nRWpq,
      nwp=actions[rga] & nWp{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

fact{all cas:Cas | // sx->nrwpq->nwp
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nwp=actions[cas] & nWp{
          instr_sw[sx] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}
fact{all put:PutF |// sx->nf->nrp->nwpq
  let sx=actions[put] & Sx_put, 
      nrp=actions[put] & nRp,
      nf=actions[put] & nF,
      nwpq=actions[put] & nWpq{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrp and
          instr_sw[nrp] = nwpq and
		   #(instr_sw[nwpq])=0
     }
}

fact{all get:GetF | // sx->nf->nrpq->nwp
  let sx=actions[get] & Sx_get, 
      nrpq=actions[get] & nRpq,
      nf=actions[get] & nF,
      nwp=actions[get] & nWp{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrpq and
          instr_sw[nrpq] = nwp and
		   #(instr_sw[nwp])=0
      }
}

fact{all rga:RgaF | // sx->nf->nrwpq->nwp
  let sx=actions[rga] & Sx_rga, 
      nrwpq=actions[rga] & nRWpq,
      nf=actions[rga] & nF,
      nwp=actions[rga] & nWp{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

fact{all cas:CasF | // sx->nf->nrwpq->nwp
  let sx=actions[cas] & Sx_cas, 
      nrwpq=actions[cas] & nRWpq,
      nf=actions[cas] & nF,
      nwp=actions[cas] & nWp{
          instr_sw[sx] = nf and
          instr_sw[nf] = nrwpq and
          instr_sw[nrwpq] = nwp and
		   #(instr_sw[nwp])=0
     }
}

//-------------
/**nic-ord-sw**/
//-----------
fact{not cyclic[nic_ord_sw]}

// (na1,na2) in nic_ord_sw definition (3 cases)
fact{all disj na1,na2:nA |
        let sx1=actions[instr[na1]]&Sx,
             sx2=actions[instr[na2]]&Sx {
  (na2 in nic_ord_sw[na1]) 
      iff
  (
    (sameOandD[na1,na2]) and//forcing same queuepair and starting thread
    (sx2 in sx1.^po)  and 
	(//3 cases
	  (//Case1: put or RDMA atomic (with successor, on remote machine) 
	    (remoteMachine[na1]) and   // sx1----->nWpq
	    (remoteMachine[na2]) and   // ↓po         ↓nic_ord_sw
	    (not na1 in nRpq+nF)          // sx2----->na2 
	  )//end Case1
	  or (//Case2:  put (local read part)
	    some  nwpq1,nwpq2:nWpq {              // sx1----->nRp
	      (na2 in nRp) and (na1 in nRp) and   // ↓po         ↓nic_ord_sw
	      (instr[sx1]=instr[nwpq1])and            // sx2----->nRp 
	      (instr[sx2]=instr[nwpq2])
	    }
	  )//end Case2
	  or (//Case3: nF
	    some nrpq:nRpq {
	       (na2 in nF) and (na1 in nWp) and  // sx1-->nRpq-->nWp
	       (instr[sx1]=instr[nrpq])                   // ↓po                  ↓nic_ord_sw
	    }                                                       // sx2-------------->nF
	  )//end case3
	)//end  breaking into cases
 )//end iff
}//end let sx1,sx2
}

//------------
/****/
//------------
fact{all pcq:poll_cq | pcq=poll_cq_sw[co_poll_cq_sw[pcq]]}
fact{all pcq:poll_cq, na:nA | pcq in poll_cq_sw[na] iff na in co_poll_cq_sw[pcq]}
/*//first version --- recursive
fact{all disj na2:nA, pcq:poll_cq | 
(pcq in poll_cq_sw[na2])
iff 
  (some na1:nA,sx:Sx {
      (na2 in instr_sw[na1] ) and
      (na1 in instr_sw[sx] ) and
      (pcq in sx.^po) and
          (all sx2:Sx,na3,na4:nA {
             ( (na4 in instr_sw[na3] ) and
                (na3 in instr_sw[sx2] ) and
                (sx in sx2.^po)
              )
              =>
             (  some pcq2:poll_cq {
                    pcq2 in poll_cq_sw[na4] and
                    pcq in pcq2.^po and
                    pcq2 in sx2.^po
                 }          
             )
            }            
          )
  }//end of some na1,sx
  )
}
*/

fact{all disj na2:nA, pcq:poll_cq | 
(pcq in poll_cq_sw[na2])
iff 
  (some na1:nA,sx:Sx {
      (na2 in instr_sw[na1] ) and
      (na1 in instr_sw[sx] ) and
      (pcq in sx.^po) and
          (
           #(sx.^copo & Sx) = #(pcq.^copo & poll_cq)
           )
  }//end of some na1,sx
  )
}


/*pred p1 { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
           #PutF = 1 and
            #Sx_cas = 1 and
            #Thr = 2}

run p1 for 8
*/

pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            #Put = 1 and
            #PutF = 1 and
            #poll_cq = 2  and
			 #(Sx & Sx_put.po) > 0 and
			 #(poll_cq & Sx_put.po) > 0 and
            #Thr = 2}

run p for 10

