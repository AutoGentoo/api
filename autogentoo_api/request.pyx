from .request cimport *
from posix.unistd cimport close
from libc.stdio cimport printf
from libc.stdlib cimport free
from libc.string cimport strdup, memset
from .d_malloc cimport Binary
from collections import namedtuple

req_bindings = {
	"REQ_HOST_NEW": <int>REQ_HOST_NEW,
	"REQ_HOST_EDIT": <int>REQ_HOST_EDIT,
 	"REQ_HOST_DEL": <int>REQ_HOST_DEL,
	"REQ_HOST_EMERGE": <int>REQ_HOST_EMERGE,
	"REQ_HOST_MNTCHROOT": <int>REQ_HOST_MNTCHROOT,
	"REQ_SRV_INFO": <int>REQ_SRV_INFO,
	"REQ_SRV_REFRESH": <int>REQ_SRV_REFRESH,
	"REQ_AUTH_ISSUE_TOK": <int>REQ_AUTH_ISSUE_TOK,
	"REQ_AUTH_REFRESH_TOK": <int>REQ_AUTH_REFRESH_TOK,
	"REQ_AUTH_REGISTER": <int>REQ_AUTH_REGISTER,
}

request_args = {
	REQ_HOST_NEW: [STRCT_AUTHORIZE, STRCT_HOST_NEW],
	REQ_HOST_EDIT: [STRCT_AUTHORIZE, STRCT_HOST_SELECT, STRCT_HOST_EDIT],
	REQ_HOST_DEL: [STRCT_AUTHORIZE, STRCT_HOST_SELECT],
	REQ_HOST_EMERGE: [STRCT_AUTHORIZE, STRCT_HOST_SELECT, STRCT_EMERGE],
	REQ_HOST_MNTCHROOT: [STRCT_AUTHORIZE, STRCT_HOST_SELECT],
	REQ_SRV_INFO: [],
	REQ_SRV_REFRESH: [STRCT_AUTHORIZE],
	REQ_AUTH_ISSUE_TOK: [STRCT_AUTHORIZE, STRCT_HOST_SELECT, STRCT_ISSUE_TOK],
	REQ_AUTH_REFRESH_TOK: [STRCT_AUTHORIZE],
	REQ_AUTH_REGISTER: [STRCT_AUTHORIZE, STRCT_ISSUE_TOK]
}

request_structure_linkage = [
	"sss",# /* Host new */
	"s", # /* Host select */
	"iss", # /* Host edit */
	"ss", # /* Host authorize */
	"s", # /* Emerge arguments */
	"ssi", # /* Issue Token */
]

cpdef RequestStruct = namedtuple('RequestStruct', 'struct_type args')
cpdef Response = namedtuple('Response', 'code message content')

cdef class Request:
	def __init__(self, Address adr, request_t req_code, list args, ssl=True):
		self.request = DynamicBuffer(to_network=True) # To big endian
		self.request.parent.used_size += 1
		self.ssl = ssl
		memset(self.request.parent.ptr, 0, 1)
		self.request.append_int(<int>req_code)
		for strct in args:
			self.request.append_int(strct.struct_type)
			self.request.append(str(request_structure_linkage[strct.struct_type - 1]), strct.args)
		self.request.append_int(STRCT_END)

		self.error = False
		
		cdef int con;
		if self.ssl:
			con = ssocket_new (&self.secure_socket, adr.ip, adr.port);
		else:
			self.raw_socket = prv_ssocket_connect(adr.ip, adr.port)
			if self.raw_socket == -1:
				con = 1
		
		if con != 0:
			self.error = True
		self.code = -1
		self.message = None

	cpdef size_t send(self):
		cdef ClientRequest request;
		request.ptr = self.request.parent.ptr
		request.size = self.request.get_size()
		cdef int out_size;
		printf("before send\n")
		if self.ssl:
			ssocket_request(self.secure_socket, &request)
		else:
			socket_request(self.raw_socket, &request)
		printf("after send\n")

	cpdef list recv(self):
		cdef void* response_ptr
		cdef int response_size
		
		if self.ssl:
			response_size = <size_t>ssocket_read(self.secure_socket, &response_ptr)
		else:
			response_size = <size_t>socket_read(self.raw_socket, &response_ptr)
		if response_size <= 0:
			raise ConnectionError("Failed to read response from server")

		cdef Binary res_bin = Binary(None)
		res_bin.set_ptr(response_ptr, response_size)

		self.code = res_bin.read_int()
		self.message = res_bin.read_string()
		cdef str template = res_bin.read_string()

		if template is None:
			return []

		return res_bin.read_template(template.encode('utf-8'))

	def __dealloc__(self):
		if not self.error:
			if self.ssl:
				ssocket_free(self.secure_socket)
			else:
				close (self.raw_socket)

cpdef host_new(str arch, str profile, str hostname):
	return RequestStruct(struct_type=STRCT_HOST_NEW, args=(arch, profile, hostname))
# request_type 1: make_conf 2: general
cpdef host_edit(int request_type, str make_conf_var, str make_conf_val):
	return RequestStruct(struct_type=STRCT_HOST_EDIT, args=(request_type, make_conf_var))
cpdef host_select(str hostname):
	return RequestStruct(struct_type=STRCT_HOST_SELECT, args=[hostname])
cpdef authorize(str user_id, str token):
	return RequestStruct(struct_type=STRCT_AUTHORIZE, args=(user_id, token))
cpdef emerge(str emerge):
	return RequestStruct(struct_type=STRCT_EMERGE, args=[emerge])
cpdef issue_token(str user_id, str target_host, token_access_t access_level):
	return RequestStruct(struct_type=STRCT_ISSUE_TOK, args=(user_id, target_host, access_level))

cdef class Client:
	def __init__(self, Address adr):
		autogentoo_client_ssl_init()
		self.adr = adr

	cpdef request(self, str str_code, args):
		cdef request_t code = <request_t>req_bindings[str_code]

		self.verify_request(code, args)
		cdef Request req = Request(self.adr, code, args)
		if req.error:
			return None

		req.send()
		content = req.recv()
		res = Response(code=req.code, message=req.message, content=content)

		return res

	cdef verify_request(self, request_t code, args):
		for strct in args:
			if type(strct) != RequestStruct:
				raise TypeError("args must be RequestStruct")
		required_args = request_args[code]
		if [i.struct_type for i in args] != request_args[code]:
			raise TypeError("Incorrect struct list, expected: %s" % request_args[code])

cdef class Address:
	def __init__(self, ip, port):
		self.ip = strdup(ip.encode("utf-8"))
		self.port = int(port)

	def __dealloc__(self):
		free(self.ip)
