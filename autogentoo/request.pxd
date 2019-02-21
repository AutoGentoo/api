from .dynamic_binary cimport DynamicType
from .d_malloc cimport DynamicBuffer

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
		
		int ssocket_new(SSocket** sock, char* server_hostname, unsigned short port);
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

cdef class Request:
	cdef SSocket* socket
	cdef DynamicBuffer request
	
	cdef int code
	cdef str message
	cdef error
	
	cpdef size_t send(self)
	cpdef list recv(self)

cdef class Address:
	cdef char* ip
	cdef int port

cdef class Client:
	cdef Address adr
	
	cpdef request(self, str str_code, args)
	cdef verify_request(self, request_t code, args)

cpdef host_new(str arch, str profile, str hostname)
# request_type 1: make_conf 2: general
cpdef host_edit(int request_type, str make_conf_var, str make_conf_val)
cpdef host_select(str hostname)
cpdef authorize(str user_id, str token)
cpdef emerge(str emerge)
cpdef issue_token(str user_id, str target_host, token_access_t access_level)