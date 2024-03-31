// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java:
// https://pvs-studio.com

#include <bits/pthreadtypes.h>
#include <thpool.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <unistd.h>

#define PORT 8888
#define BUFFER_SIZE 1024

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
    thpool_add_work(pool, handle_client, (void* )client_socket_ptr);
  }

  // Close the server socket
  close(server_socket);

  return 0;
}
