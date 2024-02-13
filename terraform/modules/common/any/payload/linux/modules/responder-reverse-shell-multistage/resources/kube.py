#!/usr/bin/env python3

import kubernetes.client
from kubernetes import client, config
from kubernetes.client.rest import ApiException
import yaml

# Load configuration from '/root/config'
config.load_kube_config("/root/config")

v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()


def attempt_operation(operation, *args, **kwargs):
    try:
        operation(*args, **kwargs)
        print(f"Operation {operation.__name__} successful.")
    except ApiException as e:
        print(f"Operation {operation.__name__} failed: {e}")


def list_and_get_operations(api, namespace, resource_type, resource_name=None):
    list_func = getattr(api, f"list_namespaced_{resource_type}")
    get_func = getattr(api, f"read_namespaced_{resource_type}", None)

    print(f"Listing {resource_type}:")
    attempt_operation(list_func, namespace)

    if resource_name and get_func:
        print(f"Getting {resource_type}: {resource_name}")
        attempt_operation(get_func, resource_name, namespace)


def create_and_update_operations(api, namespace, resource_type, resource_name, resource_body, update_body):
    create_func = getattr(api, f"create_namespaced_{resource_type}", None)
    update_func = getattr(api, f"patch_namespaced_{resource_type}", None)

    if create_func:
        print(f"Creating {resource_type}: {resource_name}")
        attempt_operation(create_func, namespace, resource_body)

    if update_func and resource_name:
        print(f"Updating {resource_type}: {resource_name}")
        attempt_operation(update_func, resource_name, namespace, update_body)


# Example usage for Pods
list_and_get_operations(v1, 'default', 'pod', 'example-pod')

# Example usage for Deployments
deployment_body = yaml.safe_load('''apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deployment
spec:
  selector:
    matchLabels:
      app: example
  replicas: 1
  template:
    metadata:
      labels:
        app: example
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80''')

update_deployment_body = {'spec': {'replicas': 2}}

list_and_get_operations(apps_v1, 'default', 'deployment', 'example-deployment')
create_and_update_operations(apps_v1, 'default', 'deployment',
                             'example-deployment', deployment_body, update_deployment_body)

# Extend similar blocks for Services, ConfigMaps, etc., adjusting the body and update payloads as needed.

# NOTE: Ensure you replace 'example-pod', 'example-deployment', etc., with actual resource names relevant to your environment.
# The resource bodies (e.g., deployment_body) should be crafted according to your testing scenario.

# Load configuration from '/root/config'
config.load_kube_config("/root/config")

v1 = client.CoreV1Api()


def list_pods():
    print("Listing pods with their IPs:")
    ret = v1.list_pod_for_all_namespaces(watch=False)
    for i in ret.items:
        print(f"{i.status.pod_ip}\t{i.metadata.namespace}\t{i.metadata.name}")


def get_pod_details(namespace, pod_name):
    print(f"Getting details for pod: {pod_name} in namespace: {namespace}")
    try:
        ret = v1.read_namespaced_pod(name=pod_name, namespace=namespace)
        print(
            f"Pod Name: {ret.metadata.name}, Namespace: {ret.metadata.namespace}")
    except ApiException as e:
        print(f"An error occurred: {e}")


def list_secrets(namespace='default'):
    print("Listing secrets:")
    try:
        ret = v1.list_namespaced_secret(namespace)
        for i in ret.items:
            print(f"{i.metadata.name}")
    except ApiException as e:
        print(f"An error occurred: {e}")


def get_secret(namespace, secret_name):
    print(
        f"Getting details for secret: {secret_name} in namespace: {namespace}")
    try:
        ret = v1.read_namespaced_secret(name=secret_name, namespace=namespace)
        print(
            f"Secret Name: {ret.metadata.name}, Namespace: {ret.metadata.namespace}")
    except ApiException as e:
        print(f"An error occurred: {e}")


def update_secret(namespace, secret_name, new_data):
    print(f"Updating secret: {secret_name} in namespace: {namespace}")
    try:
        # Get the current secret
        secret = v1.read_namespaced_secret(
            name=secret_name, namespace=namespace)
        # Update the data
        secret.data = new_data
        # Submit the update
        v1.replace_namespaced_secret(
            name=secret_name, namespace=namespace, body=secret)
        print(f"Secret {secret_name} updated.")
    except ApiException as e:
        print(f"An error occurred: {e}")


# Example usage
list_pods()
# Replace 'example-pod' with a real pod name
get_pod_details('default', 'example-pod')
list_secrets('default')
# Replace 'example-secret' with a real secret name
get_secret('default', 'example-secret')
# Replace 'example-secret' and dict with actual values
update_secret('default', 'example-secret', {'key': 'new_value'})
