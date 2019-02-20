from cython_dynamic_binary cimport DynamicType
from d_malloc cimport DynamicBuffer
from collections import namedtuple

cdef extern from "<autogentoo/request_structure.h>":
	ctypedef enum request_structure_t:
		STRCT_END,
		STRCT_HOST_NEW = 1,
		STRCT_HOST_SELECT,
		STRCT_HOST_EDIT,
		STRCT_AUTHORIZE,
		STRCT_EMERGE,
		STRCT_ISSUE_TOK,
		
		STRCT_MAX

cdef extern from "<autogentoo/request.h>":
	cdef:
		ctypedef enum request_t:
			REQ_GET,
			REQ_HEAD,
			REQ_POST,
			REQ_START,
			
			REQ_HOST_NEW,
			REQ_HOST_EDIT,
			REQ_HOST_DEL,
			REQ_HOST_EMERGE,
			
			REQ_HOST_MNTCHROOT,
			REQ_SRV_INFO,
			REQ_AUTH_ISSUE_TOK,
			REQ_AUTH_REFRESH_TOK,
			
			REQ_MAX

cdef extern from "<autogentoo/api/request_generate.h>":
	ctypedef struct ClientRequest:
		# We dont use these
		request_t request_type;
		void* arguments;
		
		# /* Just set the dynamic binary ptr */
		size_t size;
		void* ptr;
	
	cdef:
		ClientRequest* client_request_init(request_t _type);
		int client_request_add_structure(ClientRequest* req, request_structure_t struct_type, DynamicType* content);
		int client_request_generate(ClientRequest* req);
		void client_request_free(ClientRequest* req);

cdef extern from "<autogentoo/api/ssl_wrap.h>":
	cdef:
		ctypedef struct SSocket:
			void* ssl;
			void* cert;
			void* cert_name;
			void* context;
			
			char* hostname;
			unsigned short port;
			int socket;
		
		SSocket* ssocket_new(char* server_hostname, unsigned short port);
		void ssocket_free(SSocket* ptr);
		void autogentoo_client_ssl_init();
		void ssocket_request(SSocket* ptr, ClientRequest* request);
		ssize_t ssocket_read_response(SSocket* sock, void** dest);
		ssize_t ssocket_read(SSocket* ptr, void* dest, size_t n);

cdef extern from "<autogentoo/user.h>":
	ctypedef enum token_access_t:
		TOKEN_NONE,
		TOKEN_SERVER_READ = 1 << 0,
		TOKEN_SERVER_WRITE = TOKEN_SERVER_READ | 1 << 1, # //!< Create hosts
		TOKEN_SERVER_AUTOGENTOO_ORG = 1 << 2, # //!< Register users from server (no read/write)
		TOKEN_HOST_READ = 1 << 3,
		TOKEN_HOST_EMERGE = TOKEN_HOST_READ | 1 << 4, # //!< Can't change host settings
		TOKEN_HOST_WRITE = TOKEN_HOST_EMERGE | 1 << 5, # //!< Write to make.conf
		TOKEN_HOST_MOD = TOKEN_HOST_WRITE | 1 << 6, # //!< Can delete host
		TOKEN_SERVER_SUPER = 0xFF, # //!< All permissions

cdef char** request_structure_linkage = [
	"sss",# /* Host new */
	"s", # /* Host select */
	"iss", # /* Host edit */
	"ss", # /* Host authorize */
	"s", # /* Emerge arguments */
	"ssi", # /* Issue Token */
]

cdef class Request:
	cdef SSocket* socket
	cdef DynamicBuffer request
	
	cdef int code
	cdef char* message
	
	cpdef size_t send(self)
	cpdef list recv(self)

cdef class Address:
	cdef char* ip
	cdef int port

RequestStruct = namedtuple('RequestStruct', 'struct_type args')
Response = namedtuple('Response', 'code message content')

request_args = {
	REQ_HOST_NEW: [STRCT_AUTHORIZE, STRCT_HOST_NEW],
	REQ_HOST_EDIT: [STRCT_AUTHORIZE, STRCT_HOST_SELECT, STRCT_HOST_EDIT],
	REQ_HOST_DEL: [STRCT_AUTHORIZE, STRCT_HOST_SELECT],
	REQ_HOST_EMERGE: [STRCT_AUTHORIZE, STRCT_HOST_SELECT, STRCT_EMERGE],
	REQ_HOST_MNTCHROOT: [STRCT_AUTHORIZE, STRCT_HOST_SELECT],
	REQ_SRV_INFO: [],
	REQ_AUTH_ISSUE_TOK: [STRCT_AUTHORIZE, STRCT_HOST_SELECT, STRCT_ISSUE_TOK],
	REQ_AUTH_REFRESH_TOK: [STRCT_AUTHORIZE]
}

# Generates requests and parses responses
cdef class RequestStructs:
	@staticmethod
	cdef host_new(char* arch, char* profile, char* hostname)
	# request_type 1: make_conf 2: general
	@staticmethod
	cdef host_edit(int request_type, char* make_conf_var, char* make_conf_val)
	@staticmethod
	cdef host_select(char* hostname)
	@staticmethod
	cdef authorize(char* user_id, char* token)
	@staticmethod
	cdef emerge(char* emerge)
	@staticmethod
	cdef issue_token(char* user_id, char* target_host, token_access_t access_level)

cdef class Client:
	cdef Address adr
	
	cpdef request(self, request_t code, args)
	cdef verify_request(self, request_t code, args)