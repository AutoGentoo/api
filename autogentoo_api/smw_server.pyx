from .smw_server cimport *

main_server = None

cdef char* django_handle_c(char* server_id):
	linfo(server_id)
	if main_server is None:
		return "localhost"
	return "localhost"

cdef class MiddlewareServer:
	def __init__(self):
		self.parent = smw_server_new(b"9489", NULL, NULL)
		self.parent[0].django_callback = django_handle_c
	
	cpdef start(self):
		return smw_server_start(self.parent)
	
	cpdef loop(self):
		smw_server_loop(self.parent)
	
	def __dealloc__(self):
		smw_server_free(self.parent)
