open execution as e

one sig nA1Pivot in Writer{}
one sig nA2Pivot in Writer{}


sig nA_prime in nA {
	nic_ord_sw_prime: set nA
}
fact{nA in nA_prime}

sig RDMAaction_prime in RDMAaction {
	sw_prime: set Action
}

/* Witness */
one sig Witness in Reader {
}
/* Witness2 */
//one sig Witness2 in Reader {}

one sig RDMAExecution_prime extends Execution{}
