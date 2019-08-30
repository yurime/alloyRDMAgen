// VPI_verbs test code
// inspired by https://thegeekinthecorner.wordpress.com/2010/09/28/rdma-read-and-write-with-ib-verbs/
#include "rdma-test.h"

extern enum mode proc;
extern struct connection self_conn;
// shared var decls
$3

// local decls
$5

void register_shared_vars(enum app_type acting_as, struct connection * conn) {
  // should be no race because the client should complete sending a request
  //   ... strictly before the server responds to it.
  if (proc == ONE_PROC && acting_as == SERVER) {
    conn->rdma_region = self_conn.rdma_region;
  } else {
    posix_memalign((void**)&(conn->rdma_region), 64, sizeof(long long)*{2});
    memset(conn->rdma_region, 0, sizeof(long long)*{2});
    self_conn.rdma_region = conn->rdma_region;
  }

  vars = conn->rdma_region;
  // initialize vars
  $4

  test_init(conn);

  TEST_Z(conn->rdma_mr = ibv_reg_mr(pd,
				    conn->rdma_region,
				    sizeof(long long) * {2},
				    IBV_ACCESS_LOCAL_WRITE | IBV_ACCESS_REMOTE_WRITE | IBV_ACCESS_REMOTE_READ | IBV_ACCESS_REMOTE_ATOMIC));
  if (acting_as == CLIENT) {
    self_conn.peer_mr = conn->rdma_mr;
  }
}

/* ****************************** START OF TESTS SECTION ****************************** */

/*
$11
*/

void test_init(struct connection *conn) {
  $12
}

void test(struct ibv_cq *cq, struct connection *conn) {
  enum app_type peer;
  if (app == CLIENT) peer = SERVER; else peer = CLIENT;

  // pre-test barrier
  if (proc == TWO_PROCS) {
    if (app == CLIENT) {
      *client_state = 1;
      rdma_operation(peer, conn, *conn->peer_mr, client_state - vars, client_state, conn->rdma_mr, IBV_WR_RDMA_WRITE, IBV_SEND_SIGNALED);
      consume_one_cqe(cq);
      while (*server_state < 1) /* busy-wait */;
    } else {
      *server_state = 1;
      rdma_operation(peer, conn, *conn->peer_mr, server_state - vars, server_state, conn->rdma_mr, IBV_WR_RDMA_WRITE, IBV_SEND_SIGNALED);
      consume_one_cqe(cq);
      while (*client_state < 1) /* busy-wait */;
    }
  }
  // test code
  $13
  // ---
  // post-test barrier
  if (proc == TWO_PROCS) {
    if (app == CLIENT) {
      *client_state = 2;
      rdma_operation(peer, conn, *conn->peer_mr, client_state - vars, client_state, conn->rdma_mr, IBV_WR_RDMA_WRITE, IBV_SEND_SIGNALED);
      consume_one_cqe(cq);
      while (*server_state < 2) /* busy-wait */;
    } else {
      *server_state = 2;
      rdma_operation(peer, conn, *conn->peer_mr, server_state - vars, server_state, conn->rdma_mr, IBV_WR_RDMA_WRITE, IBV_SEND_SIGNALED);
      consume_one_cqe(cq);
      while (*client_state < 2) /* busy-wait */;
    }
  }
}

void test_result(struct ibv_cq *cq, struct connection *conn) {
  enum app_type peer;
  if (app == CLIENT) peer = SERVER; else peer = CLIENT;

  $14
  if (proc == TWO_PROCS) {
    if (app == CLIENT) {
      *client_state = 3;
      rdma_operation(peer, conn, *conn->peer_mr, client_state - vars, client_state, conn->rdma_mr, IBV_WR_RDMA_WRITE, IBV_SEND_SIGNALED);
      consume_one_cqe(cq);
      while (*server_state < 3) /* busy-wait */;
    } else {
      *server_state = 3;
      rdma_operation(peer, conn, *conn->peer_mr, server_state - vars, server_state, conn->rdma_mr, IBV_WR_RDMA_WRITE, IBV_SEND_SIGNALED);
      consume_one_cqe(cq);
      while (*client_state < 3) /* busy-wait */;
    }
  }
}

void collate_results(struct ibv_cq *cq, struct connection *conn) {
  enum app_type peer;
  if (app == CLIENT) peer = SERVER; else peer = CLIENT;

  $15

  // synch before disconnecting
  if (proc == TWO_PROCS) {
    if (app == CLIENT) {
      *client_state = 4;
      rdma_operation(peer, conn, *conn->peer_mr, client_state - vars, client_state, conn->rdma_mr, IBV_WR_RDMA_WRITE, IBV_SEND_SIGNALED);
      consume_one_cqe(cq);
      while (*server_state < 4) /* busy-wait */;
    } else {
      *server_state = 4;
      rdma_operation(peer, conn, *conn->peer_mr, server_state - vars, server_state, conn->rdma_mr, IBV_WR_RDMA_WRITE, IBV_SEND_SIGNALED);
      consume_one_cqe(cq);
      while (*client_state < 4) /* busy-wait */;
    }
  }
}

void print_results() {
  $16
}

/* ****************************** END OF TESTS SECTION ****************************** */
