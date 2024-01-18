#!/usr/bin/env python3

import argparse
from google.cloud import secretmanager
from google.auth import compute_engine
from google.oauth2 import service_account
from google.auth import transport
from google.auth import default
from google.auth.compute_engine import _metadata

credentials, project_id = default()
auth_req = transport.requests.Request()
credentials.refresh(auth_req)

# Create a Secret Manager client
client = secretmanager.SecretManagerServiceClient(credentials=credentials)


def access_secret_version(secret_id):
    # Build the resource name of the secret version.
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    # Access the secret version.
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode('UTF-8')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='reverse shell listener')
    parser.add_argument('--output', dest='output',
                        default='cloudsql-combined-ca-bundle.pem', help='path to output db cert')

    args = parser.parse_args()
    # Retrieve your database connection details from Secret Manager
    DB_CERT = access_secret_version('db_cert')

    SSL_CA = args.output
    with open(SSL_CA, 'w') as f:
        f.write(DB_CERT)
