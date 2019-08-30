#ifndef RDMA_COMMON_H
#define RDMA_COMMON_H

#include <stdbool.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <rdma/rdma_cma.h>

#define NUM_ITERATIONS 1000

#define TEST_NZ(x) do { if ( (x)) die("error: " #x " failed (returned non-zero)." ); } while (0)
#define TEST_Z(x)  do { if (!(x)) die("error: " #x " failed (returned zero/null)."); } while (0)

enum app_type {
  CLIENT,
  SERVER
};

enum mode {
  ONE_PROC,
  TWO_PROCS
};

extern enum mode procs;

struct context {
  struct ibv_context *ctx;
  struct ibv_cq *cq;
  struct ibv_comp_channel *comp_channel;

  pthread_t cq_poller_thread;
};

struct message {
  enum { 
    MSG_MR,
    MSG_DONE
  } type;

  union {
    struct ibv_mr mr;
  } data;
};

struct connection {
  struct rdma_cm_id *id;
  struct ibv_qp *qp, *self_qp;

  int connected;

  struct ibv_mr *recv_mr;
  struct ibv_mr *send_mr;
  struct ibv_mr *rdma_mr;
  struct ibv_mr *peer_mr;

  struct message *recv_msg;
  struct message *send_msg;

  long long *rdma_region;

  enum {
    SS_INIT,
    SS_MR_SENT,
    SS_RDMA_SENT
  } send_state;

  enum {
    RS_INIT,
    RS_MR_RECV
  } recv_state;

};

extern enum app_type app;
extern struct ibv_pd *pd;

void die(const char *reason);

void build_connection(enum app_type acting_as, struct rdma_cm_id *id);
void build_params(struct rdma_conn_param *params);
void destroy_connection(void *context);
void on_connect(void *context);
void *poll_cq(void *ctx);
void * poll_cross_cq(void *ctx);
void set_app(enum app_type a);

void rdma_operation(enum app_type dest, struct connection *conn, struct ibv_mr peer_mr, int peer_offset, long long *rdma_region, struct ibv_mr *rdma_mr, enum ibv_wr_opcode opcode, int flags);
void rdma_operation_cas(enum app_type dest, struct connection *conn, struct ibv_mr peer_mr, int peer_offset, long long *rdma_addr, struct ibv_mr *rdma_mr, long long compare, long long swap);
void rdma_operation_rga(enum app_type dest, struct connection *conn, struct ibv_mr peer_mr, int peer_offset, long long *rdma_addr, struct ibv_mr *rdma_mr, long long add);
void send_message(struct connection *conn);
void send_flush(enum app_type dest, struct ibv_cq *cq, struct connection *conn, bool signal);
void send_self_flush(struct connection * conn);
void consume_one_cqe(struct ibv_cq *cq);
void post_receives(enum app_type acting_as, struct connection *conn);

#endif
