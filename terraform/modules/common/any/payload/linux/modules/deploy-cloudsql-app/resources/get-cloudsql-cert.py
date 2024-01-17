#!/usr/bin/env python3

from google.cloud import secretmanager
from google.auth import compute_engine
from google.oauth2 import service_account


# Use the IAM service account for authentication
credentials = compute_engine.Credentials()

# Create a Secret Manager client
client = secretmanager.SecretManagerServiceClient(credentials=credentials)


def access_secret_version(secret_id):
    # Build the resource name of the secret version.
    name = f"projects/my-project/secrets/{secret_id}/versions/latest"
    # Access the secret version.
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode('UTF-8')


if __name__ == "__main__":
    # Retrieve your database connection details from Secret Manager
    DB_CERT = access_secret_version('db_cert')

    SSL_CA = 'cloudsql-combined-ca-bundle.pem'
    with open(SSL_CA, 'w') as f:
        f.write(DB_CERT)
