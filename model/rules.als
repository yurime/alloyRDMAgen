open actions as a

fact {all disj r: Reader, w: Writer| (w = corf[r]) iff (r in rf[w]) }

//fact {all disj pq: poll_cq, na: nA| (na = cosw[pq]) iff (pq in sw[na]) }

pred p { 
            //#(Action.o) > 1 and
            //#Rcas = 0 and
            //#Rga = 0 and
            //#Action = 7 and
            #Thr = 2}

run p for 10
