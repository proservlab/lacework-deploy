#!/bin/env python3

from laceworksdk import LaceworkClient
import logging
import argparse
import json

parser = argparse.ArgumentParser()
parser.add_argument("-s", "--suppressions", help="output all legacy supressions",
                    action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("-e", "--exceptions", help="output new lpp exceptions",
                    action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("-p", "--policies", help="output new lpp policies",
                    action=argparse.BooleanOptionalAction, default=False)
parser.add_argument("--name", help="filter by policy name",
                    default=None)
parser.add_argument("--profile", help="lacework profile",
                    default=None)
args = parser.parse_args()
if not args.exceptions and not args.suppressions and not args.policies:
    print("Missing required --exceptions or --suppressions")
    parser.print_help()
    exit()

lw = LaceworkClient(profile=args.profile)

if args.policies:
    # new lpp policies
    data = lw.policies.get(policy_id=args.name)
    formatted_json = json.dumps(data['data'], sort_keys=True, indent=4)
    print(formatted_json)
elif args.exceptions:
    # new lpp policy exceptions
    if args.name:
        policy_id = args.name
        data = lw.policy_exceptions.get(policy_id=policy_id)
        formatted_json = json.dumps(data, sort_keys=True, indent=4)
        print(formatted_json)
    else:
        policies = lw.policies.get(policy_id=args.name)
        for p in policies['data']:
            print(p['policyId'])
            data = lw.policy_exceptions.get(policy_id=p['policyId'])
            formatted_json = json.dumps(data, sort_keys=True, indent=4)
            print(formatted_json)
    
elif args.suppressions:
    # legacy suppressions
    data = lw.suppressions.get(type="aws",recommendation_id=args.name)
    if args.name is not None:
        result = data['data']
    else:
        result = data['data'][0]['recommendationExceptions']

    formatted_json = json.dumps(result, sort_keys=True, indent=4)
    print(formatted_json)
