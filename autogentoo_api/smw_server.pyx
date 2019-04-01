from .smw_server cimport *

main_server = None

cdef char* django_handle_c(char* server_id):
	linfo(server_id)
	if main_server is None:
		return "localhost"
	return "localhost"

cdef class MiddlewareServer:
	def __init__(self, cert_file=None, rsa_file=None):
		self.parent = smw_server_new("9489", <char*>cert_file, <char*>rsa_file)
		self.parent[0].django_callback = django_handle_c
	
	cpdef start(self):
		return smw_server_start(self.parent)
	
	def __dealloc__(self):
		smw_server_free(self.parent)
