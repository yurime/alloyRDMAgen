open actions as a
open sw_rules as swr

// definition of hb and hbs

one sig Execution {
// actions: set Actions,
// po: Action->Action,
// rf: Action->Action,
// sw: Action->Action,
 mo: Writer->lone Writer,
 mos: Writer->lone Writer,
 hb: Action-> set Action,
 hbs: Action->set Action,
 hbqp: Action->set Action
}{
  hb = ^(po+rf+sw)

//mo basic definition
  {all disj w1,w2:Writer | (host[wl[w1]]=host[wl[w2]]) => ((w1 in w2.^mo) or (w2 in w1.^mo))}
  {all w2:Writer, w1:w2.mo |  (host[wl[w1]]=host[wl[w2]])}


{not cyclic[hb]} // but hb;mo is cyclic, it culd be nice to generate the trace
{not cyclic[mo]}

//hbqp definition
hbqp in hb

  {all a: Action, b:a.hbqp| 
      (not a in nWpq)
       or
      (a + b in nA and sameOandD[a,b])
  }// end hbqp defintion

//mo_s definition
   mos in mo
  {all w2:Writer, w1: w2.^mos| w2 in nRWpq+U+nWp}

//hbs definition 
  hbs=^(hbqp+mos)

/** MO Axioms **/
// mo;hb_s irreflexive 
{all a:Action | not a in a.^mo.hbs}

//On when a read can miss a previous write in hb_s
{all a,b,c:Action | c in a.rf and c in b.hbs and wl[a]=wl[b] => not b in a.^mo}

//On when a read can miss a previous write in hb_s
//(1/3)
{all a,b,c:Action | 
    c in a.rf and 
    c in b.(mo & (Action->(Action-nWpq))).sw.hbs and 
    wl[a]=wl[b] 
    => not b in a.^mo}

//On when a read can miss a previous write in hb_s
//(2/3) nW forced to memory due to following read or atomic
{all a,b,c:Action | 
    c in a.rf and 
    (some d1,e1:Action |
        d1 in b.mo and
        e1 in d1.(hbs & (nWpq->(nRpq+nRWpq))) and
        o[e1]=o[d1] and 
        d[e1]=d[d1] and
        c in e1.hbs
    ) and
    wl[a]=wl[b] 
    => not b in a.^mo}

//On when a read can miss a previous write in hb_s
//(3/3) external read
{all a,b,c:Action | 
    c in a.rf and 
    c in b.mo.(rf-po).hbs and 
    wl[a]=wl[b] 
    => not b in a.^mo}

//TSO fence
{all a,b,c:Action | 
    c in a.rf and 
    c in b.mos.hbs and 
    wl[a]=wl[b] 
    => not b in a.^mo}

}
pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            #Put = 2 and
            #poll_cq = 2  and
			 #(Sx & Sx.po) > 0 and
			 #(poll_cq & Sx_put.po) > 0 and
            #Thr = 2}

check{not cyclic[(Execution.hb).(Execution.mo)]} for 10
//run p for 10
