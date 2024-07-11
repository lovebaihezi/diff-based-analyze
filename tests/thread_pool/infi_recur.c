// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java:
// https://pvs-studio.com

#include <arpa/inet.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#include "thpool.h"
#include "types.h"

#define PORT 8888
#define BUFFER_SIZE 1024

PointToAnother p1, p2;

Data d1, d2;

size_t write_to(PointToAnother *input, char *output) {
  pid_t *pid = (pid_t *)output;
  *pid = input->data->pid;
  memcpy(output + sizeof(pid_t), input->data->slice, input->data->slice_len);
  return sizeof(pid_t) + input->data->slice_len;
}

char *parse(PointToAnother *input, size_t *output_len) {
  if (input->data == NULL || input->data->slice_len == 0 ||
      input->data->slice == NULL) {
    return NULL;
  }
  char *buf = (char *)malloc(sizeof(pid_t) + input->data->slice_len + 1);
  if (buf == NULL) {
    return NULL;
  }
  size_t wrote = write_to(input, buf);
  for (size_t i = 0; i < input->len; i += 1) {
    size_t other_output_len = 0;
    char *parsed_others = parse(input->others + i, &other_output_len);
    if (parsed_others != NULL) {
      wrote += other_output_len;
      char *new_buf = malloc(wrote + other_output_len + 1);
      memcpy(new_buf, buf, wrote);
      memcpy(new_buf + wrote, parsed_others, other_output_len);
      free(parsed_others);
      free(buf);
      buf = new_buf;
    }
  }
  *output_len = wrote;
  return NULL;
}

void handle_client(void *arg) {
  int client_socket = *(int *)arg;
  char buffer[BUFFER_SIZE];
  int read_size;

  // Read data from the client
  while ((read_size = recv(client_socket, buffer, BUFFER_SIZE, 0)) > 0) {
    // Process the received data
    // ...

    // Send a response back to the client
    send(client_socket, buffer, read_size, 0);
  }

  // Close the client socket
  close(client_socket);
  free(arg);
}

int main(void) {

  int server_socket, client_socket;
  struct sockaddr_in server_addr, client_addr;
  socklen_t addr_size;

  d1.slice_len = sizeof("data 1");
  d1.slice = "data 1";
  d1.pid = getpid();
  d2.slice_len = sizeof("data 2");
  d2.slice = "data 2";
  d2.pid = 1; // means the pid of the init process

  p1.others = &p2;
  p1.len = 1;
  p2.others = &p1;
  p2.len = 1;

  threadpool pool = thpool_init(31);

  // Create the server socket
  server_socket = socket(AF_INET, SOCK_STREAM, 0);
  if (server_socket < 0) {
    perror("socket");
    exit(1);
  }

  // Configure the server address
  server_addr.sin_family = AF_INET;
  server_addr.sin_port = htons(PORT);
  server_addr.sin_addr.s_addr = INADDR_ANY;

  // Bind the socket to the specified IP and port
  if (bind(server_socket, (struct sockaddr *)&server_addr,
           sizeof(server_addr)) < 0) {
    perror("bind");
    exit(1);
  }

  // Start listening for incoming connections
  if (listen(server_socket, 5) < 0) {
    perror("listen");
    exit(1);
  }

  printf("Server is running on port %d\n", PORT);

  // Accept and handle client connections
  while (1) {
    addr_size = sizeof(client_addr);
    client_socket =
        accept(server_socket, (struct sockaddr *)&client_addr, &addr_size);
    if (client_socket < 0) {
      perror("accept");
      exit(1);
    }

    printf("New client connected\n");

    // Create a new thread to handle the client connection
    int *client_socket_ptr = malloc(sizeof(int));
    *client_socket_ptr = client_socket;
    thpool_add_work(pool, handle_client, (void *)client_socket_ptr);
  }

  thpool_wait(pool);
  // Close the server socket
  close(server_socket);

  return 0;
}
