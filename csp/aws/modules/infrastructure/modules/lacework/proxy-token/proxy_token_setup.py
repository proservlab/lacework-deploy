import getopt
import json
import os
import requests
import sys

def print_help():
    print('''
Usage: cloudability_setup.py [options]

cloudability_setup -- Register new account with Cloudability

Options:
  -h, --help            Show this help message and exit
  -a <acct #>, --acctnum=<acct #>
                        Required argument: IaaS Account Number
  -t <type>, --type=<type>
                        Required argument: IaaS Account Type
''')

def register_acct(acctnum, type):

    url = 'https://api.cloudability.com/v3/vendors/aws/accounts'
    token = os.environ['CldAbltyAPIToken']
    headers = {'Content-Type': 'application/json'}
    data = '{"vendorAccountId": "' + acctnum + '", "type": "'+ type + '" }'

    response = requests.post(url, auth=(token,''), headers=headers, data=data)

    # If new account was registered successfully, update externalID:
    if response.status_code == requests.codes.created:
      update_acct(acctnum, type)

    # If account already exists, update externalID:
    elif str(response.status_code) == '409':
      update_acct(acctnum, type)

    else:
      print("Bad response from Lacework API while registering proxy token.")
      print(f"HTTP: {response.status_code}")
      sys.exit(3)


def update_acct(acctnum, type):

    url = 'https://api.cloudability.com/v3/vendors/aws/accounts/' + acctnum
    token = os.environ['CldAbltyAPIToken']
    headers = {'Content-Type': 'application/json'}
    data = '{"type": "' + type + '", "externalId": "XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXX" }'

    response = requests.put(url, auth=(token,''), headers=headers, data=data)

    if response.status_code == requests.codes.ok:
      sys.exit()

    else:
      print("Bad response from Lacework API while updating proxy token.")
      print(f"HTTP: {response.status_code}")
      sys.exit(3)


def main(argv=None):
    '''
    Main function: work with command line options and send an HTTPS request to the Cloudability API.
    '''

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'ha:t:',
                                   ['help', 'acctnum=', 'type='])
    except getopt.GetoptError, err:
        # Print help information and exit:
        print str(err)
        print_help()
        sys.exit(2)

    # Initialize parameters
    acctnum = None
    type = None

    # Parse command line options
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            print_help()
            sys.exit()
        elif opt in ('-a', '--acctnum'):
            acctnum = arg
        elif opt in ('-t', '--type'):
            type = arg

    # Enforce required arguments
    if not acctnum or not type:
      print_help()
      sys.exit(4)

    register_acct(acctnum, type)


if __name__ == '__main__':
    sys.exit(main())