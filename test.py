from autogentoo_api.request import *
from autogentoo_api.d_malloc import DynamicBuffer

# k = d_malloc.DynamicBuffer(to_network=True)
# k.append("ssisa(is)", ["hello", "world", 2, "goodbye", [(2, "ds"), (3, "dd"), (1, "36")]])

#client = Client(Address(ip="localhost", port="9491"))

# username = input("username: ")
# token = input("token: ")
username = "autogentoo.org"
token = "hP6Q5vNmyCvhBr48hqb9ZQKkhn9LaLF5"


#print(client.request("REQ_SRV_REFRESH", [authorize(username, token)]))

#print(client.request("REQ_HOST_NEW", [
#	authorize("kronos", ""),
#	host_new("amd64", "profile", "test host")
#]))

#print(client.request("REQ_SRV_INFO", []))

sock = Socket(Address(ip="/tmp/autogentoo_worker.sock", unix=True), ssl=False)

worker_request_1 = DynamicBuffer(to_network=True)
worker_request_1.append("issia(s)", [0, "script_name", "/home/atuser/test", 1, ["arg1", "arg2"]])

sock.request(worker_request_1)
print(sock.recv(raw=True))

worker_request_2 = DynamicBuffer(to_network=True)
worker_request_2.append("issia(s)", [1, "script_name", "/home/atuser/test", 1, ["arg1", "arg2"]])

sock = Socket(Address(ip="/tmp/autogentoo_worker.sock", unix=True), ssl=False)
sock.request(worker_request_2)
res_bin = sock.recv()

res_bin.print_raw()
template = res_bin.read_string()

print(res_bin.read_template(template.encode('utf-8')))
