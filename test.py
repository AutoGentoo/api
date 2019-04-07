from autogentoo_api.request import *
from autogentoo_api.d_malloc import DynamicBuffer

# k = d_malloc.DynamicBuffer(to_network=True)
# k.append("ssisa(is)", ["hello", "world", 2, "goodbye", [(2, "ds"), (3, "dd"), (1, "36")]])

client = Client(Address(ip="localhost", port="9491"))

# username = input("username: ")
# token = input("token: ")
username = "autogentoo.org"
token = "hP6Q5vNmyCvhBr48hqb9ZQKkhn9LaLF5"


print(client.request("REQ_SRV_REFRESH", [authorize(username, token)]))

#print(client.request("REQ_HOST_NEW", [
#	authorize("kronos", ""),
#	host_new("amd64", "profile", "test host")
#]))

print(client.request("REQ_SRV_INFO", []))

worker_request = DynamicBuffer(to_network=True)
worker_request.append("ssia(s)", ["script_name", "/home/atuser/test", 1, ["arg1", "arg2"]])

sock = Socket(Address(ip="/home/atuser/git/AutoGentoo/cmake-build-debug/worker.tcp", unix=True), ssl=False)
sock.request(worker_request)
#worker_request.print_raw()
print(sock.recv(raw=True))

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
