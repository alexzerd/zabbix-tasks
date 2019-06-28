import os, requests, json, sys, socket
import netifaces
from requests.auth import HTTPBasicAuth

zabbix_server = "192.168.55.56"
zabbix_api_admin_name = os.environ['Z_NAME']
zabbix_api_admin_password = os.environ['Z_PASS']
ip4_list = [netifaces.ifaddresses(iface)[netifaces.AF_INET][0]['addr'] for iface in netifaces.interfaces() if netifaces.AF_INET in netifaces.ifaddresses(iface)]


def post(request):

    headers = {'content-type': 'application/json'}
    return requests.post(
        "http://" + zabbix_server + "/zabbix/api_jsonrpc.php",
        data = json.dumps(request),
        verify=True,
        headers = headers,
        auth = HTTPBasicAuth(zabbix_api_admin_name, zabbix_api_admin_password)
    )

payload = {"jsonrpc": "2.0", "method": "user.login", "params": {"user": zabbix_api_admin_name, "password" : zabbix_api_admin_password}, "auth": None, "id": "0"}
auth_token = post(payload).json()["result"]

def register_host(hostname, ip):
    post({
        "jsonrpc": "2.0",
        "method": "host.create",
        "params": {
            "host": 'zab_'+socket.gethostname()[8:12],
            "templates":[{
                "templateid": "10001"
            }],
            "interfaces": [{
                "type": 1,
                "main": 1,
                "useip": 1,
                "ip": [s for s in ip4_list if '55' in s][0],
                "dns": "",
                "port": "10050"
            }],
            "groups": [
                {"groupid": 15}
            ]
        },
        "auth": auth_token,
        "id": 1
    })

register_host('4194zab', '192.168.55.1')
