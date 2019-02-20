from request cimport *
from libc.stdlib cimport free
from libc.string cimport strdup
from d_malloc cimport Binary

cdef class Request:
	def __init__(self, Address adr, request_t req_code, list args):
		self.request = DynamicBuffer(to_network=True) # To big endian
		self.request.append_int(<int>req_code)
		for strct in args:
			self.request.append(str(request_structure_linkage[strct.struct_type - (REQ_START + 1)]), strct.args)
		
		self.socket = ssocket_new (adr.ip, adr.port)
		if self.socket == NULL:
			raise ConnectionError("Failed to create connect to %s:%s" % (adr.ip, adr.port))
		
		self.code = -1
		self.message = NULL
	
	cpdef size_t send(self):
		cdef ClientRequest request;
		request.ptr = self.request.get_ptr()
		request.size = self.request.get_size()
		ssocket_request(self.socket, &request)
	
	cpdef list recv(self):
		cdef void* response_ptr
		cdef size_t response_size
		
		response_size = <size_t>ssocket_read_response(self.socket, &response_ptr)
		if response_size <= 0:
			raise ConnectionError("Failed to read response from server")
		
		cdef Binary res_bin = Binary(None)
		res_bin.set_ptr(response_ptr, response_size)
		
		self.code = res_bin.read_int()
		self.message = res_bin.read_string()
		
		cdef char* template = res_bin.read_string()
		return res_bin.read_template(template)
	
	def __dealloc__(self):
		if self.message:
			free(self.message)
		ssocket_free(self.socket)

cdef class RequestStructs:
	@staticmethod
	cdef host_new(char* arch, char* profile, char* hostname):
		return RequestStruct(struct_type=STRCT_HOST_NEW, args=list(locals().values()))
	# request_type 1: make_conf 2: general
	@staticmethod
	cdef host_edit(int request_type, char* make_conf_var, char* make_conf_val):
		return RequestStruct(struct_type=STRCT_HOST_EDIT, args=list(locals().values()))
	@staticmethod
	cdef host_select(char* hostname):
		return RequestStruct(struct_type=STRCT_HOST_SELECT, args=list(locals().values()))
	@staticmethod
	cdef authorize(char* user_id, char* token):
		return RequestStruct(struct_type=STRCT_AUTHORIZE, args=list(locals().values()))
	@staticmethod
	cdef emerge(char* emerge):
		return RequestStruct(struct_type=STRCT_EMERGE, args=list(locals().values()))
	@staticmethod
	cdef issue_token(char* user_id, char* target_host, token_access_t access_level):
		return RequestStruct(struct_type=STRCT_ISSUE_TOK, args=list(locals().values()))

cdef class Client:
	def __init__(self, Address adr):
		self.adr = adr
	
	cpdef request(self, request_t code, args):
		self.verify_request(code, args)
		cdef Request req = Request(self.adr, code, args)
		req.send()
		content = req.recv()
		res = Response(code=req.code, message=req.message, content=content)
		
		return res
	
	cdef verify_request(self, request_t code, args):
		for strct in args:
			if type(strct) != RequestStruct:
				raise TypeError("args must be RequestStruct")
		required_args = request_args[code]
		for i, in range(len(required_args)):
			if args[i].struct_type != request_args[i]:
				raise TypeError("Expect struct type: %d, got %d" % (request_args[i], args[i].struct_type))

cdef class Address:
	def __init__(self, ip, port):
		self.ip = strdup(ip.encode("utf-8"))
		self.port = int(port)
	
	def __dealloc__(self):
		free(self.ip)