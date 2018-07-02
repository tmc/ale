"""
This Python script creates a TCP server that does nothing but send its input
back to the client that connects to it. Only one argument must be given, a port
to bind to.
"""
import socket
import sys


def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(('127.0.0.1', int(sys.argv[1])))
    sock.listen(0)

    while True:
        connection = sock.accept()[0]

        while True:
            connection.send(connection.recv(1024))

    connection.close()


if __name__ == "__main__":
    main()
