from .request cimport *

cdef extern from "<autogentoo/hacksaw/tools/log.h>":
	void linfo(char*);
	void lerror(char*);
	void lwarn(char*)

cdef extern from "<autogentoo/api/ssl_stream.h>":
	ctypedef struct SMWConnection:
		SMWServer* parent;
		
		void* write_side; # /* autogentoo.org side */
		int write_side_sock;
		
		SSocket* read_side; # /* AutoGentoo side */
		
		SMWPool* thread;
	
	ctypedef struct SMWPool:
		SMWPool* next;
		SMWPool* prev;
		SMWConnection* child;
		unsigned long pid;
	
	ctypedef struct SMWServer:
		int socket;
		char* port;
		unsigned long pid;
		
		char* (*django_callback)(char* server_id);
		
		# /* Open pools as needed */
		SMWPool* pool_head;
		unsigned long pool_mutex;
		
		char* cert_file;
		char* rsa_file;
		
		void* certificate;
		void* context;
		void* key_pair;
		
		int keep_alive;
	
	cdef:
		SMWServer* smw_server_new (char* port, char* cert_file, char* rsa_file);
		unsigned long smw_server_start(SMWServer* server);
		void smw_server_free(SMWServer* server);
		SMWConnection* smw_server_connect(SMWServer* server, int fd);
		SMWPool* smw_fork(SMWServer* server, int accepted_sock);
		void smw_server_loop(SMWServer* server);
		void smw_stream(SMWConnection* conn);

cdef char* django_handle_c(char* server_id)

cdef class MiddlewareServer:
	cdef SMWServer* parent;
	cdef django_handler
	
	cpdef start(self)
	cpdef loop(self)
