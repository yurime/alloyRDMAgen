// VPI_verbs server code
#include "rdma-common.h"
#include "rdma-test.h"

const int TIMEOUT_IN_MS = 500; /* ms */
const enum mode proc = ONE_PROC;
struct connection self_conn;

static int on_connect_request(struct rdma_cm_id *id);
static int on_connection(enum app_type acting_as, struct rdma_cm_id *id);
static int on_disconnect(struct rdma_cm_id *id);
static int on_event(struct rdma_cm_event *event);
static void usage(const char *argv0);
static void * self_connect(void *port_str);
static int on_self_event(struct rdma_cm_event *event);

int main(int argc, char **argv) {
  struct sockaddr_in addr;
  struct rdma_cm_event *event = NULL;
  struct rdma_cm_id *listener = NULL;
  struct rdma_event_channel *ec = NULL;

  if (argc != 1)
    usage(argv[0]);

  set_app(SERVER);

  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;

  TEST_Z(ec = rdma_create_event_channel());
  TEST_NZ(rdma_create_id(ec, &listener, NULL, RDMA_PS_TCP));
  TEST_NZ(rdma_bind_addr(listener, (struct sockaddr *)&addr));
  TEST_NZ(rdma_listen(listener, 10)); /* backlog=10 is arbitrary */

  uint16_t port = ntohs(rdma_get_src_port(listener));
  char port_str[10];

  snprintf(port_str, sizeof(port_str), "%d", port);

  for (int i = 0; i < NUM_ITERATIONS; i++) {
    pthread_t tid;
    TEST_NZ(pthread_create(&tid, NULL, self_connect, port_str));
    while (rdma_get_cm_event(ec, &event) == 0) {
      struct rdma_cm_event event_copy;

      memcpy(&event_copy, event, sizeof(*event));
      rdma_ack_cm_event(event);

      if (on_event(&event_copy))
	break;
    }
    TEST_NZ(pthread_join(tid, NULL));
  }

  rdma_destroy_id(listener);
  rdma_destroy_event_channel(ec);
  print_results();

  return 0;
}

int on_connect_request(struct rdma_cm_id *id) {
  struct rdma_conn_param cm_params;

  build_connection(SERVER, id);
  build_params(&cm_params);
  TEST_NZ(rdma_accept(id, &cm_params));

  return 0;
}

int on_connection(enum app_type acting_as, struct rdma_cm_id *id) {
  on_connect(id->context);
  if (acting_as == SERVER) {
    send_mr(id->context);
    send_flush(acting_as, NULL, id->context, false);
  } else {
    send_self_flush(id->context);
  }
  return 0;
}

int on_disconnect(struct rdma_cm_id *id) {
  destroy_connection(id->context);
  return 1;
}

int on_event(struct rdma_cm_event *event) {
  int r = 0;

  if (event->event == RDMA_CM_EVENT_CONNECT_REQUEST)
    r = on_connect_request(event->id);
  else if (event->event == RDMA_CM_EVENT_ESTABLISHED)
    r = on_connection(SERVER, event->id);
  else if (event->event == RDMA_CM_EVENT_DISCONNECTED)
    r = on_disconnect(event->id);
  else
    die("on_event: unknown event.");

  return r;
}

// connect to self code

static void * self_connect(void *port_str) {
  struct rdma_cm_event *event = NULL;
  struct rdma_cm_id *conn= NULL;
  struct rdma_event_channel *ec = NULL;
  struct addrinfo hints;
  struct addrinfo *addr;

  // our server only listens on IPv4 so we better try to connect to it there
  memset(&hints, 0, sizeof(hints));
  hints.ai_family=AF_INET;

  TEST_NZ(getaddrinfo("localhost", port_str, &hints, &addr));

  TEST_Z(ec = rdma_create_event_channel());

  TEST_NZ(rdma_create_id(ec, &conn, NULL, RDMA_PS_TCP));
  TEST_NZ(rdma_resolve_addr(conn, NULL, addr->ai_addr, TIMEOUT_IN_MS));

  freeaddrinfo(addr);

  while (rdma_get_cm_event(ec, &event) == 0) {
    struct rdma_cm_event event_copy;

    memcpy(&event_copy, event, sizeof(*event));
    rdma_ack_cm_event(event);

    if (on_self_event(&event_copy))
      break;
  }
  rdma_destroy_event_channel(ec);

  return NULL;
}

int on_addr_resolved(struct rdma_cm_id *id) {
  build_connection(CLIENT, id);
  TEST_NZ(rdma_resolve_route(id, TIMEOUT_IN_MS));

  return 0;
}

int on_route_resolved(struct rdma_cm_id *id) {
  struct rdma_conn_param cm_params;

  build_params(&cm_params);
  TEST_NZ(rdma_connect(id, &cm_params));

  return 0;
}

int on_self_event(struct rdma_cm_event *event) {
  int r = 0;

  if (event->event == RDMA_CM_EVENT_ADDR_RESOLVED)
    r = on_addr_resolved(event->id);
  else if (event->event == RDMA_CM_EVENT_ROUTE_RESOLVED)
    r = on_route_resolved(event->id);
  else if (event->event == RDMA_CM_EVENT_ESTABLISHED)
    r = on_connection(CLIENT, event->id);
  else if (event->event == RDMA_CM_EVENT_DISCONNECTED)
    r = on_disconnect(event->id);
  else if (event->event == RDMA_CM_EVENT_REJECTED)
    die("on_event: RDMA_CM_EVENT_REJECTED.");
  else
    die("on_event: unknown event.");

  return r;
}

void usage(const char *argv0) {
  fprintf(stderr, "usage: %s\n", argv0);
  exit(1);
}

static void build_context(struct ibv_context *verbs);
static void build_cross_context(struct ibv_context *verbs);
static void build_qp_attr(enum app_type acting_as, struct ibv_qp_init_attr *qp_attr);
static int on_completion(struct ibv_cq *cq, struct ibv_wc *);
static void register_memory(enum app_type acting_as, struct connection *conn);

struct context *s_ctx = NULL, *s_cross_ctx = NULL;
struct ibv_pd *pd = NULL;

enum app_type app, cross_app;

void set_app(enum app_type a) {
  app = a;
  if (app == CLIENT)
    cross_app = SERVER;
  else
    cross_app = CLIENT;
}

void die(const char *reason) {
  fprintf(stderr, "%s\n", reason);
  exit(EXIT_FAILURE);
}

void build_connection(enum app_type acting_as, struct rdma_cm_id *id) {
  struct connection *conn;
  struct ibv_qp_init_attr qp_attr;

  if (acting_as == app)
    build_context(id->verbs);
  else
    build_cross_context(id->verbs);
  build_qp_attr(acting_as, &qp_attr);

  TEST_NZ(rdma_create_qp(id, pd, &qp_attr));

  struct ibv_qp_attr attr;
  memset(&attr, 0, sizeof(struct ibv_qp_attr));
  attr.qp_access_flags = IBV_ACCESS_LOCAL_WRITE | IBV_ACCESS_REMOTE_WRITE | IBV_ACCESS_REMOTE_READ | IBV_ACCESS_REMOTE_ATOMIC;
  TEST_NZ(ibv_modify_qp(id->qp, &attr, IBV_QP_ACCESS_FLAGS));

  if (acting_as == app)
    conn = (struct connection *)malloc(sizeof(struct connection));
  else
    conn = &self_conn;

  id->context = conn;

  conn->id = id;
  if (acting_as == app)
    conn->qp = id->qp;
  else
    conn->self_qp = id->qp;

  conn->send_state = SS_INIT;
  conn->recv_state = RS_INIT;

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

  if (pd == NULL)
    TEST_Z(pd = ibv_alloc_pd(s_ctx->ctx));

  TEST_Z(s_ctx->comp_channel = ibv_create_comp_channel(s_ctx->ctx));
  TEST_Z(s_ctx->cq = ibv_create_cq(s_ctx->ctx, 10, NULL, s_ctx->comp_channel, 0)); /* cqe=10 is arbitrary */
  TEST_NZ(ibv_req_notify_cq(s_ctx->cq, 0));

  TEST_NZ(pthread_create(&s_ctx->cq_poller_thread, NULL, poll_cq, NULL));
}

void build_cross_context(struct ibv_context *verbs) {
  if (s_cross_ctx) {
    if (s_cross_ctx->ctx != verbs)
      die("cannot handle events in more than one context.");

    TEST_NZ(pthread_create(&s_cross_ctx->cq_poller_thread, NULL, poll_cross_cq, NULL));
    return;
  }

  s_cross_ctx = (struct context *)malloc(sizeof(struct context));

  s_cross_ctx->ctx = verbs;

  if (pd == NULL)
    TEST_Z(pd = ibv_alloc_pd(s_cross_ctx->ctx));
  TEST_Z(s_cross_ctx->comp_channel = ibv_create_comp_channel(s_cross_ctx->ctx));
  TEST_Z(s_cross_ctx->cq = ibv_create_cq(s_cross_ctx->ctx, 10, NULL, s_cross_ctx->comp_channel, 0)); /* cqe=10 is arbitrary */
  TEST_NZ(ibv_req_notify_cq(s_cross_ctx->cq, 0));

  TEST_NZ(pthread_create(&s_cross_ctx->cq_poller_thread, NULL, poll_cross_cq, NULL));
}

void build_params(struct rdma_conn_param *params) {
  memset(params, 0, sizeof(*params));

  params->initiator_depth = params->responder_resources = 1;
  params->rnr_retry_count = 7; /* infinite retry */
}

void build_qp_attr(enum app_type acting_as, struct ibv_qp_init_attr *qp_attr) {
  memset(qp_attr, 0, sizeof(*qp_attr));

  if (app == acting_as) {
    qp_attr->send_cq = s_ctx->cq;
    qp_attr->recv_cq = s_ctx->cq;
  } else {
    qp_attr->send_cq = s_cross_ctx->cq;
    qp_attr->recv_cq = s_cross_ctx->cq;
  }
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

  rdma_destroy_id(conn->id);

  if (conn != &self_conn)
    free(conn);
}

int on_completion(struct ibv_cq *cq, struct ibv_wc *wc) {
  struct connection *conn = (struct connection *)(uintptr_t)wc->wr_id;
  if (wc->status != IBV_WC_SUCCESS) {
    printf("on_completion: [app %d] status is %s (%d), not IBV_WC_SUCCESS.\n", app, ibv_wc_status_str(wc->status), wc->status);
    return 0;
  }
  if (app == SERVER) {
    test(cq, &self_conn);
    test_result(cq, &self_conn);
    collate_results(cq, conn);

    rdma_disconnect(conn->id);
    conn->connected = 0;
    return 1;
  } else {
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
      if (on_completion(cq, &wc)) {
	return NULL;
      }
  }

  return NULL;
}

void * poll_cross_cq(void *ctx) {
  struct ibv_cq *cq;
  struct ibv_wc wc;

  while (1) {
    TEST_NZ(ibv_get_cq_event(s_cross_ctx->comp_channel, &cq, (void**)&ctx));
    ibv_ack_cq_events(cq, 1);
    TEST_NZ(ibv_req_notify_cq(cq, 0));

    while (ibv_poll_cq(cq, 1, &wc))
      if (on_completion(cq, &wc)) {
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
  wr.send_flags = 0;

  sge.addr = (uintptr_t)conn->send_msg;
  sge.length = sizeof(struct message);
  sge.lkey = conn->send_mr->lkey;

  while (!conn->connected);

  TEST_NZ(ibv_post_send(conn->qp, &wr, &bad_wr));
}

void send_flush(enum app_type dest, struct ibv_cq *cq, struct connection *conn, bool signal) {
  struct ibv_send_wr wr, *bad_wr = NULL;

  memset(&wr, 0, sizeof(wr));

  wr.wr_id = (uintptr_t)conn;
  wr.opcode = IBV_WR_RDMA_WRITE;
  wr.sg_list = NULL;
  wr.num_sge = 0;
  wr.send_flags = IBV_SEND_FENCE;
  if (signal)
    wr.send_flags |= IBV_SEND_SIGNALED;

  while (!conn->connected);

  if (app == dest)
    TEST_NZ(ibv_post_send(conn->qp, &wr, &bad_wr));
  else
    TEST_NZ(ibv_post_send(conn->self_qp, &wr, &bad_wr));

  if (signal)
    consume_one_cqe(cq);
}

void send_self_flush(struct connection *conn) {
  struct ibv_send_wr wr, *bad_wr = NULL;

  memset(&wr, 0, sizeof(wr));

  wr.wr_id = (uintptr_t)conn;
  wr.opcode = IBV_WR_RDMA_WRITE;
  wr.sg_list = NULL;
  wr.num_sge = 0;
  wr.send_flags = IBV_SEND_FENCE;

  while (!self_conn.connected);

  TEST_NZ(ibv_post_send(self_conn.self_qp, &wr, &bad_wr));
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
    printf("consume_one_cqe: status is %s (%d), not IBV_WC_SUCCESS.\n", ibv_wc_status_str(wc.status), wc.status);
    return;
  }
}

void post_receives(enum app_type dest, struct connection *conn) {
  struct ibv_recv_wr wr, *bad_wr = NULL;
  struct ibv_sge sge;

  wr.wr_id = (uintptr_t)conn;
  wr.next = NULL;
  wr.sg_list = &sge;
  wr.num_sge = 1;

  sge.addr = (uintptr_t)conn->recv_msg;
  sge.length = sizeof(struct message);
  sge.lkey = conn->recv_mr->lkey;

  if (dest != app)
    TEST_NZ(ibv_post_recv(conn->self_qp, &wr, &bad_wr));
  else
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

  if (dest == app)
    TEST_NZ(ibv_post_send(self_conn.self_qp, &wr, &bad_wr));
  else
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

  if (dest == app)
    TEST_NZ(ibv_post_send(self_conn.self_qp, &wr, &bad_wr));
  else
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

  if (dest == app)
    TEST_NZ(ibv_post_send(self_conn.self_qp, &wr, &bad_wr));
  else
    TEST_NZ(ibv_post_send(conn->qp, &wr, &bad_wr));
}

// CAS: http://permalink.gmane.org/gmane.linux.drivers.openib/61028
