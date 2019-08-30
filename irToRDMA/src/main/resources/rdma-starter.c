#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/select.h>

struct arg_server {
  FILE * f;
  char * n;
};

void * echo (void * a) {
  struct arg_server *arg = (struct arg_server *)a;
  char in_string[1035];

  while (1) {
    if (fgets(in_string, sizeof(in_string)-1, arg->f) == NULL) {
      break;
    } else {
      printf("[%s] %s", arg->n, in_string);
    }
  }
  return NULL;
}

#define LOCALHOST "localhost"
#define THIS_HOST_IB "192.168.0.1"
#define REMOTE_HOST "galilei"

#define RDMA_SERVER "rdma-server"
#define RDMA_CLIENT "rdma-client"

int main(int argc, char *argv[]) {
  char path[1035], tmp[10];
  char cwd[1035];
  static struct arg_server s = { .n = "server" },
    c = { .n = "client" };

    if (argc != 1) {
      printf("usage: %s\n", argv[0]);
      exit(1);
    }

    /* Open the command for reading */
    snprintf(path, sizeof(path), "./%s", RDMA_SERVER);
    s.f = popen(path, "r");
    if (s.f == NULL) {
      printf("Failed to run %s\n", argv[1]);
      exit(1);
    }

    while (fgets(path, sizeof(path)-1, s.f) != NULL) {
      printf("[server] %s", path);
      break;
    }

    int j = 0;
    for(int i = 0; path[i]; i++) {
      if (path[i] >= '0' && path[i] <= '9') {
	tmp[j] = path[i];
	j++;
      }
    }
    tmp[j] = '\0';
    int port = atoi(tmp);
    fprintf(stdout, "[starter] number is %d\n", port);

    getcwd(cwd, sizeof(cwd));
#if USE_SSH_FOR_RDMA_STARTER
    snprintf(path, sizeof(path), "ssh %s %s/%s %s %d", REMOTE_HOST, cwd, RDMA_CLIENT, THIS_HOST_IB, port);
#else
    snprintf(path, sizeof(path), "%s/%s %s %d", cwd, RDMA_CLIENT, LOCALHOST, port);
#endif
    c.f = popen(path, "r");

    pthread_t server_poller, client_poller;
    pthread_create(&server_poller, NULL, echo, &s);
    pthread_create(&client_poller, NULL, echo, &c);

    pthread_join(client_poller, NULL);
    pthread_join(server_poller, NULL);

    return 0;
}
