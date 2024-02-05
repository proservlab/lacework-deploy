# cat list_pods_1.py
# #!/usr/bin/python3.7
# # Script name: list_pods_1.py
# import kubernetes.client
# from kubernetes import client, config

# config.load_kube_config("/root/config")   # I'm using file named "config" in the "/root" directory

# v1 = kubernetes.client.CoreV1Api()
# print("Listing pods with their IPs:")
# ret = v1.list_pod_for_all_namespaces(watch=False)
# for i in ret.items:
#     print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))


# cat list_pods_2.py
# #!/usr/bin/python3.7
# import kubernetes.client
# from kubernetes import client, config
# import requests
# from requests.packages.urllib3.exceptions import InsecureRequestWarning

# requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

#  # Define the barer token we are going to use to authenticate.
#     # See here to create the token:
#     # https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/
# aToken = "<MY_TOKEN>"

#     # Create a configuration object
# aConfiguration = client.Configuration()

#     # Specify the endpoint of your Kube cluster
# aConfiguration.host = "https://<ENDPOINT_OF_MY_K8S_CLUSTER>"

#     # Security part.
#     # In this simple example we are not going to verify the SSL certificate of
#     # the remote cluster (for simplicity reason)
# aConfiguration.verify_ssl = False
#     # Nevertheless if you want to do it you can with these 2 parameters
#     # configuration.verify_ssl=True
#     # ssl_ca_cert is the filepath to the file that contains the certificate.
#     # configuration.ssl_ca_cert="certificate"

# aConfiguration.api_key = {"authorization": "Bearer " + aToken}

#     # Create a ApiClient with our config
# aApiClient = client.ApiClient(aConfiguration)

#     # Do calls
# v1 = client.CoreV1Api(aApiClient)
# print("Listing pods with their IPs:")
# ret = v1.list_pod_for_all_namespaces(watch=False)
# for i in ret.items:
#     print("%s\t%s\t%s" %
#             (i.status.pod_ip, i.metadata.namespace, i.metadata.name))
