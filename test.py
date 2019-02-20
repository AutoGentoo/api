import d_malloc
import traceback
import sys

from request import *

#k = d_malloc.DynamicBuffer(to_network=True)
#k.append("ssisa(is)", ["hello", "world", 2, "goodbye", [(2, "ds"), (3, "dd"), (1, "36")]])

client = Client(Address(ip="localhost", port="9491"))
client.request(REQ_HOST_NEW, [
	RequestStructs.authorize("kronos", "adakjaskdkkda"),
	RequestStructs.host_new("amd64", "profile", "test host")
])

"""
while True:
	try:
		print(eval(input("> ")))
	except KeyboardInterrupt:
		print("")
	except EOFError:
		print("^D")
		break
	except (NameError, SyntaxError, RuntimeError):
		traceback.print_exc(file=sys.stdout)
"""