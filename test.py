from autogentoo_api.request import *

# k = d_malloc.DynamicBuffer(to_network=True)
# k.append("ssisa(is)", ["hello", "world", 2, "goodbye", [(2, "ds"), (3, "dd"), (1, "36")]])

client = Client(Address(ip="localhost", port="9491"))

# username = input("username: ")
# token = input("token: ")
username = "autogentoo.org"
token = "SsNFX7wF9wnW9GOskKCcs2Cupgo9QZ1i"


print(client.request("REQ_SRV_REFRESH", [authorize(username, token)]))

#print(client.request("REQ_HOST_NEW", [
#	authorize("kronos", ""),
#	host_new("amd64", "profile", "test host")
#]))

print(client.request("REQ_SRV_INFO", []))

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
