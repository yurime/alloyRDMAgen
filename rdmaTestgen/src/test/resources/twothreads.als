sig Thr {}

sig Action { o, d: one Thr }

fact { #Thr = 2 and #(Action.o) = 2 and #(Action.d) = 2 }

pred show {}

run show for 2
