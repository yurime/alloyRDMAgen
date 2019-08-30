// VPI_Verbs API
// inspired by https://thegeekinthecorner.wordpress.com/2010/09/28/rdma-read-and-write-with-ib-verbs/
#include "rdma-common.h"
#include "rdma-test.h"

static void build_context(struct ibv_context *verbs);
static void build_qp_attr(struct ibv_qp_init_attr *qp_attr);
static int on_completion(enum app_type acting_as, struct ibv_cq *cq, struct ibv_wc *);
void post_receives(enum app_type acting_as, struct connection *conn);
static void register_memory(enum app_type acting_as, struct connection *conn);

struct context *s_ctx = NULL;
struct ibv_pd * pd = NULL;
struct connection self_conn;

enum app_type app;

void set_app(enum app_type a) {
  app = a;
}

void die(const char *reason) {
  fprintf(stderr, "%s\n", reason);
  exit(EXIT_FAILURE);
}

void build_connection(enum app_type acting_as, struct rdma_cm_id *id) {
  struct connection *conn;
  struct ibv_qp_init_attr qp_attr;

  build_context(id->verbs);
  build_qp_attr(&qp_attr);

  TEST_NZ(rdma_create_qp(id, pd, &qp_attr));

  id->context = conn = (struct connection *)malloc(sizeof(struct connection));

  conn->id = id;
  conn->qp = id->qp;

  conn->send_state = SS_INIT;
  conn->recv_state = RS_INIT;
  conn->peer_mr = 0;

  conn->connected = 0;

  register_memory(acting_as, conn);
  post_receives(acting_as, conn);
}

void build_context(struct ibv_context *verbs) {
  if (s_ctx) {
    if (s_ctx->ctx != verbs)
      die("cannot handle events in more than one context.");

    TEST_NZ(pthread_create(&s_ctx->cq_poller_thread, NULL, poll_cq, NULL));
    return;
  }

  s_ctx = (struct context *)malloc(sizeof(struct context));

  s_ctx->ctx = verbs;

  TEST_Z(pd = ibv_alloc_pd(s_ctx->ctx));
  TEST_Z(s_ctx->comp_channel = ibv_create_comp_channel(s_ctx->ctx));
  TEST_Z(s_ctx->cq = ibv_create_cq(s_ctx->ctx, 10, NULL, s_ctx->comp_channel, 0)); /* cqe=10 is arbitrary */
  TEST_NZ(ibv_req_notify_cq(s_ctx->cq, 0));

  TEST_NZ(pthread_create(&s_ctx->cq_poller_thread, NULL, poll_cq, NULL));
}

void build_params(struct rdma_conn_param *params) {
  memset(params, 0, sizeof(*params));

  params->initiator_depth = params->responder_resources = 1;
  params->rnr_retry_count = 7; /* infinite retry */
}

void build_qp_attr(struct ibv_qp_init_attr *qp_attr) {
  memset(qp_attr, 0, sizeof(*qp_attr));

  qp_attr->send_cq = s_ctx->cq;
  qp_attr->recv_cq = s_ctx->cq;
  qp_attr->qp_type = IBV_QPT_RC; // might want less reliable QPTs for experiments

  qp_attr->cap.max_send_wr = 10;
  qp_attr->cap.max_recv_wr = 10;
  qp_attr->cap.max_send_sge = 1;
  qp_attr->cap.max_recv_sge = 1;
}

void destroy_connection(void *context) {
  struct connection *conn = (struct connection *)context;

  rdma_destroy_qp(conn->id);

  ibv_dereg_mr(conn->send_mr);
  ibv_dereg_mr(conn->recv_mr);
  ibv_dereg_mr(conn->rdma_mr);

  free(conn->send_msg);
  free(conn->recv_msg);
  if (conn->peer_mr)
    free(conn->peer_mr);

  rdma_destroy_id(conn->id);

  free(conn);
}

int on_completion(enum app_type acting_as, struct ibv_cq *cq, struct ibv_wc *wc) {
  struct connection *conn = (struct connection *)(uintptr_t)wc->wr_id;
  if (wc->status != IBV_WC_SUCCESS) {
    printf("on_completion: status is %s, not IBV_WC_SUCCESS.\n", ibv_wc_status_str(wc->status));
    return 0;
  }

  if (wc->opcode & IBV_WC_RECV) {
    conn->recv_state++;
		
    if (conn->recv_msg->type == MSG_MR) {
      conn->peer_mr = malloc(sizeof(struct ibv_mr));
      memcpy(conn->peer_mr, &conn->recv_msg->data.mr, sizeof(struct ibv_mr));
      post_receives(acting_as, conn);
      if (conn->send_state == SS_INIT) {
	send_mr(conn);
      }
    }
  } else {
    conn->send_state++;
  }

  if (conn->send_state == SS_MR_SENT && conn->recv_state == RS_MR_RECV) {
    test(cq, conn);
    test_result(cq, conn);
    collate_results(cq, conn);

    rdma_disconnect(conn->id);
    conn->connected = 0;
    return 1;
  }
  return 0;
}

void on_connect(void *context) {
  ((struct connection *)context)->connected = 1;
}

void * poll_cq(void *ctx) {
  struct ibv_cq *cq;
  struct ibv_wc wc;

  while (1) {
    TEST_NZ(ibv_get_cq_event(s_ctx->comp_channel, &cq, (void**)&ctx));
    ibv_ack_cq_events(cq, 1);
    TEST_NZ(ibv_req_notify_cq(cq, 0));

    while (ibv_poll_cq(cq, 1, &wc))
      if (on_completion(SERVER, cq, &wc)) {
	return NULL;
      }
  }

  return NULL;
}

void register_memory(enum app_type acting_as, struct connection *conn) {
  conn->send_msg = malloc(sizeof(struct message));
  conn->recv_msg = malloc(sizeof(struct message));

  register_shared_vars(acting_as, conn);

  TEST_Z(conn->send_mr = ibv_reg_mr(pd,
				    conn->send_msg, 
				    sizeof(struct message), 
				    IBV_ACCESS_LOCAL_WRITE | IBV_ACCESS_REMOTE_WRITE | IBV_ACCESS_REMOTE_READ));

  TEST_Z(conn->recv_mr = ibv_reg_mr(pd,
				    conn->recv_msg, 
				    sizeof(struct message), 
				    IBV_ACCESS_LOCAL_WRITE | IBV_ACCESS_REMOTE_WRITE | IBV_ACCESS_REMOTE_READ));
}

void send_mr(void * context) {
  struct connection *conn = (struct connection *) context;

  conn->send_msg->type = MSG_MR;
  memcpy(&conn->send_msg->data.mr, conn->rdma_mr, sizeof(struct ibv_mr));

  send_message(conn);
}

void send_message(struct connection *conn) {
  struct ibv_send_wr wr, *bad_wr = NULL;
  struct ibv_sge sge;

  memset(&wr, 0, sizeof(wr));

  wr.wr_id = (uintptr_t)conn;
  wr.opcode = IBV_WR_SEND;
  wr.sg_list = &sge;
  wr.num_sge = 1;
  wr.send_flags = IBV_SEND_SIGNALED;

  sge.addr = (uintptr_t)conn->send_msg;
  sge.length = sizeof(struct message);
  sge.lkey = conn->send_mr->lkey;

  while (!conn->connected);

  TEST_NZ(ibv_post_send(conn->qp, &wr, &bad_wr));
}

void send_flush(enum app_type acting_as, struct ibv_cq *cq, struct connection *conn, bool signal) {
  struct ibv_send_wr wr, *bad_wr = NULL;

  memset(&wr, 0, sizeof(wr));

  wr.wr_id = (uintptr_t)conn;
  wr.opcode = IBV_WR_RDMA_WRITE;
  wr.sg_list = NULL;
  wr.num_sge = 0;
  wr.send_flags = IBV_SEND_FENCE | IBV_SEND_SIGNALED;

  while (!conn->connected);

  TEST_NZ(ibv_post_send(conn->qp, &wr, &bad_wr));
  consume_one_cqe(cq);
}

void consume_one_cqe(struct ibv_cq *cq) {
  int handled = 0;
  struct ibv_wc wc;

  do {
    handled += ibv_poll_cq(cq, 1, &wc);
    if (handled < 0) {
      die("poll_cq failed");
    }
  } while (handled < 1);
  if (wc.status != IBV_WC_SUCCESS) {
    printf("consume_one_cqe: status is %s, not IBV_WC_SUCCESS.\n", ibv_wc_status_str(wc.status));
    return;
  }
}

void post_receives(enum app_type acting_as, struct connection *conn) {
  struct ibv_recv_wr wr, *bad_wr = NULL;
  struct ibv_sge sge;

  wr.wr_id = (uintptr_t)conn;
  wr.next = NULL;
  wr.sg_list = &sge;
  wr.num_sge = 1;

  sge.addr = (uintptr_t)conn->recv_msg;
  sge.length = sizeof(struct message);
  sge.lkey = conn->recv_mr->lkey;

  TEST_NZ(ibv_post_recv(conn->qp, &wr, &bad_wr));
}

void rdma_operation(enum app_type dest, struct connection *conn, struct ibv_mr peer_mr, int peer_offset, long long *rdma_addr, struct ibv_mr *rdma_mr, enum ibv_wr_opcode opcode, int flags) {
  struct ibv_send_wr wr, *bad_wr = NULL;
  struct ibv_sge sge;
	
  memset(&wr, 0, sizeof(wr));
	
  wr.wr_id = (uintptr_t)conn;
  wr.opcode = opcode;
  wr.sg_list = &sge;
  wr.num_sge = 1;
  wr.send_flags = flags;
  wr.wr.rdma.remote_addr = (uintptr_t)((long long *)peer_mr.addr + peer_offset);
  wr.wr.rdma.rkey = peer_mr.rkey;

  sge.addr = (uintptr_t)rdma_addr;
  sge.length = sizeof(long long);
  sge.lkey = rdma_mr->lkey;
	
  TEST_NZ(ibv_post_send(conn->qp, &wr, &bad_wr));
}

void rdma_operation_cas(enum app_type dest, struct connection *conn, struct ibv_mr peer_mr, int peer_offset, long long *rdma_addr, struct ibv_mr *rdma_mr, long long compare, long long swap) {
  struct ibv_send_wr wr, *bad_wr = NULL;
  struct ibv_sge sge;

  memset(&wr, 0, sizeof(wr));

  wr.wr_id = (uintptr_t)conn;
  wr.opcode = IBV_WR_ATOMIC_CMP_AND_SWP;
  wr.sg_list = &sge;
  wr.num_sge = 1;
  wr.send_flags = 0;
  wr.wr.atomic.remote_addr = (uintptr_t)((long long *)peer_mr.addr + peer_offset);
  wr.wr.atomic.compare_add = compare;
  wr.wr.atomic.swap = swap;
  wr.wr.atomic.rkey = peer_mr.rkey;

  sge.addr = (uintptr_t)rdma_addr;
  sge.length = sizeof(long long);
  sge.lkey = rdma_mr->lkey;

  TEST_NZ(ibv_post_send(conn->qp, &wr, &bad_wr));
}

void rdma_operation_rga(enum app_type dest, struct connection *conn, struct ibv_mr peer_mr, int peer_offset, long long *rdma_addr, struct ibv_mr *rdma_mr, long long add) {
  struct ibv_send_wr wr, *bad_wr = NULL;
  struct ibv_sge sge;

  memset(&wr, 0, sizeof(wr));

  wr.wr_id = (uintptr_t)conn;
  wr.opcode = IBV_WR_ATOMIC_FETCH_AND_ADD;
  wr.sg_list = &sge;
  wr.num_sge = 1;
  wr.send_flags = 0;
  wr.wr.atomic.remote_addr = (uintptr_t)((long long *)peer_mr.addr + peer_offset);
  wr.wr.atomic.compare_add = add;
  wr.wr.atomic.rkey = peer_mr.rkey;

  sge.addr = (uintptr_t)rdma_addr;
  sge.length = sizeof(long long);
  sge.lkey = rdma_mr->lkey;

  TEST_NZ(ibv_post_send(conn->qp, &wr, &bad_wr));
}

// CAS: http://permalink.gmane.org/gmane.linux.drivers.openib/61028
