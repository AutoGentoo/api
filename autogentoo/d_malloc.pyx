from libc.stdio cimport printf, fflush, stdout
from libc.string cimport strlen, strdup, memcpy
from libc.stdlib cimport free
from .d_malloc cimport DynamicBuffer
from .dynamic_binary cimport *
from .vector cimport CVector

cdef extern from "<autogentoo/endian_convert.h>":
	int ntohl (int)
	int htonl (int)

cdef class DynamicBuffer:
	def __cinit__(self):
		self.parent = dynamic_binary_new(<dynamic_binary_endian_t>0)
	
	def __init__ (self, char* start=<char*>NULL, to_network=False, is_network=False):
		cdef int temp = 0;
		temp |= DB_ENDIAN_TARGET_NETWORK if to_network else 0
		temp |= DB_ENDIAN_INPUT_NETWORK if is_network else 0
		self.parent.endian = <dynamic_binary_endian_t>temp
		if start and start is not None:
			self.append_string(start)
	
	cdef void append_string (self, char* ptr):
		self.append_item("i", ptr)
	
	cdef void append_int (self, int k):
		self.append_item ("i", &k)
	
	cdef void append_item (self, str _type, void* data):
		dynamic_binary_add(self.parent, _type.encode("utf-8")[0], data)
	
	cpdef append(self, py_template, array):
		if len(array) == 0:
			return
		py_pass_template = ""
		
		cdef CVector to_convert = CVector(sizeof(DynamicType))
		cdef CVector to_free = CVector(sizeof(char*))
		
		# parent template_start row_index array col_index
		current_array = None
		
		i = 0
		parent_array_index = 0
		cdef DynamicType temp_dyn;
		while i < len(py_template):
			item = None
			if current_array is None:
				item = array[parent_array_index]
				parent_array_index += 1
			else:
				try:
					item = current_array[3][current_array[2]][current_array[4]]
				except IndexError:
					if len(current_array[3][current_array[2]]) != current_array[4]:
						raise IndexError("Incorrect array size")
					else:
						item = None
				else:
					current_array[4] += 1
			if py_template[i] == 'i':
				temp_dyn.integer = <int>item
				to_convert.add(&temp_dyn)
				py_pass_template += 'i'
			elif py_template[i] == 's':
				temp_str = strdup((<str>item).encode("utf-8"))
				to_free.add(&temp_str)
				temp_dyn.string = temp_str
				to_convert.add(&temp_dyn)
				py_pass_template += 's'
			elif py_template[i] == 'v':
				temp_dyn.binary.data = (<DynamicBuffer>item).get_ptr()
				temp_dyn.binary.n = (<DynamicBuffer>item).get_size()
				to_convert.add(&temp_dyn)
				py_pass_template += 'v'
			elif py_template[i] == 'a':
				i += 1
				parent = current_array
				py_pass_template += 'a'
				
				# parent, template_ptr, array_index array
				current_array = [parent, i, 0, item, 0]
			elif py_template[i] == ')':
				if current_array is None:
					raise RuntimeError("Too many parenthesis closes")
				if current_array[2] + 1 >= len(current_array[3]):
					# End array
					current_array = current_array[0]
					py_pass_template += 'e'
				else:
					i = current_array[1] # Reset the template position
					current_array[2] += 1
					current_array[4] = 0
					py_pass_template += 'n'
			i += 1
		
		temp = py_pass_template.encode("utf-8")
		cdef char* template = temp
		dynamic_binary_add_quick(self.parent, template, <DynamicType*>to_convert.parent.ptr)
		for i in range(len(to_free)):
			free(to_free.get(i)[0])
	
	cdef void append_bin (self, void* ptr, size_t size):
		dynamic_binary_add_binary(self.parent, size, ptr)
	
	cdef void* get_ptr (self):
		return self.parent.ptr
	
	cpdef size_t get_size(self):
		return self.parent.used_size
	
	def __len__(self):
		return self.get_size()
	
	def __dealloc__ (self):
		if self.parent:
			free(dynamic_binary_free(self.parent))
	
	cpdef void print_raw (self, align=25):
		cdef int last_i = 1
		print(self.get_size())
		for i in range (self.parent.used_size):
			printf ("%02x ", (<char*>self.parent.ptr)[i] & 0xff)
			if last_i % 25 == 0 and align:
				printf ("\n")
			last_i += 1
		fflush (stdout)
		printf("\n")

cdef class Binary:
	def __init__ (self, DynamicBuffer buffer, is_network=True):
		self.buffer = buffer # Keep the memory intact
		if buffer is not None:
			self.ptr = buffer.get_ptr()
			self.size = buffer.get_size()
		
		self.pos = 0
		self.sentinels = []
		self.is_network_endian = is_network
	
	cdef void set_ptr(self, void* ptr, size_t size):
		self.ptr = ptr
		self.size = size
	
	cdef str read_string (self):
		if not self.inside():
			return None
		cdef char* out = <char*>(<void*>self.ptr + self.pos)
		self.pos += strlen (out) + 1
		return out.decode("utf-8")
	
	cdef int read_int (self):
		if not self.inside(sizeof (int)):
			return 0
		
		cdef int out
		memcpy (&out, self.ptr + self.pos, sizeof (int))
		self.pos += sizeof (int)
		if not self.is_network_endian:
			return out
		return ntohl(out)
	
	cdef str get_array_template(self, template_start):
		end = 0
		level = 1
		for i in range(len(template_start)):
			if template_start[i] == ')':
				level -= 1
			if level == 0:
				end = i
				break
		return template_start[:end]
	
	cdef skip_until (self, to_find):
		if sizeof(to_find) == 1:
			to_find = [htonl (to_find)]
		else:
			to_find = [htonl(x) for x in to_find]
		
		cdef int eof_be = htonl (AUTOGENTOO_FILE_END)
		cdef int c
		
		while c not in to_find and c != eof_be and self.pos < self.size:
			memcpy (&c, self.ptr + self.pos, sizeof (int))
			self.pos += 1
		self.pos -= 1
		
		return self.pos + 1 < self.size
	
	cpdef add_sentinel (self, int sentinel):
		self.sentinels.append (sentinel)
	
	cdef inside_size (self, size_t size=0):
		return self.pos < (self.size + size)
	
	cdef check_sentinels (self):
		if len(self.sentinels) == 0:
			return False
		
		if not self.inside_size(sizeof (int)):
			return True
		
		cdef int out
		memcpy (&out, self.ptr + self.pos, sizeof (int))
		
		for sentinel in self.sentinels:
			if out == sentinel:
				return True
		return False
	
	cdef inside (self, size_t next_size=0):
		return not self.check_sentinels() and self.inside_size(next_size)
	
	cpdef read_template (self, char* template):
		out = []
		
		i = 0
		while i < strlen(template):
			if template[i] == b'i':
				out.append (self.read_int())
			elif template[i] == b's':
				out.append (self.read_string())
			elif template[i] == b'a':
				i += 1 # skip over the open paren
				array_len = self.read_int()
				array_template = strdup(self.get_array_template(str(template)[i+3:]).encode('utf-8'))
				for j in range (array_len):
					out.append(self.read_template(array_template))
				i += array_len
				free(array_template)
			i += 1
		return out
	
	cpdef void print_raw (self, align=25):
		cdef int last_i = 1
		for i in range (self.size):
			printf ("%02x ", (<char*>self.ptr)[i] & 0xff)
			if last_i % 25 == 0 and align:
				printf ("\n")
			last_i += 1
		fflush (stdout)
		printf("\n")
	
	def __dealloc__(self):
		if self.buffer is None:
			free(self.ptr)