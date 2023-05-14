import requests
from bs4 import BeautifulSoup
import re

def getNonce(response):
    soup = BeautifulSoup(response.content, 'html.parser')
    script_text = soup.find('script', string=re.compile('csrfNonce')).string
    return re.search(r'\'csrfNonce\':\s*"(.*?)",', script_text).group(1)

def getSession(session):
    return session.cookies.get_dict()['session']

def pageRequest(method,url,json=None,data=None,files=None):
    return method(url, 
        json=json,
        data=data,
        files=files
    )

def apiRequest(method, url, nonce, session_cookie, json=None, data=None, files=None):
    headers = {
        'CSRF-Token': nonce,
        'User-Agent': "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
        'Cookie': f"session={session_cookie}"
    }
    if json is not None:
        headers['Content-Type'] = "application/json"
    return method(
        url=url, 
        headers=headers,
        json=json,
        data=data,
        files=files
    )


## PAGE ##

# start a session to maintain cookies
session = requests.Session()

# fetch the setup page
response = pageRequest(
    method=session.get,
    url = 'http://localhost:8000/setup')
nonce = getNonce(response=response)
session_cookie = getSession(session=session)

# post setup information
response = pageRequest(
    method=session.post,
    url = 'http://localhost:8000/setup',
    data={
        'ctf_name': 'My CTF',
        'ctf_description': '',
        'user_mode': 'teams',
        'name': 'admin',
        'email': 'admin@example.com',
        'password': 'mysecurepassword',
        'ctf_logo': ('', ''),
        'ctf_banner': ('', ''),
        'ctf_small_icon': ('', ''),
        'ctf_theme': 'core',
        'theme_color': '',
        'start': '',
        'end': '',
        '_submit': 'Finish',
        'nonce': nonce
    }
)
nonce = getNonce(response=response)
session_cookie = getSession(session=session)

# fetch the login page
response = pageRequest(
    method=session.get,
    url = 'http://localhost:8000/login')
nonce = getNonce(response=response)
session_cookie = getSession(session=session)

# post login
response = pageRequest(
    method=session.post,
    url = 'http://localhost:8000/login',
    data = {
        'name': 'admin',
        'password': 'mysecurepassword',
        '_submit': 'Finish',
        'nonce': nonce
    }
)
nonce = getNonce(response=response)
session_cookie = getSession(session=session)

## API ##

# api call - no nonce/session changes
response = apiRequest(
    method=requests.post,
    url='http://127.0.0.1:8000/api/v1/tokens', 
    nonce=nonce,
    session_cookie=session_cookie,
    json={}
)
api_token = response.json()['data']['value']
print("API Token:", api_token)

# get current user
response = apiRequest(
    method=requests.get,
    url='http://127.0.0.1:8000/api/v1/users/me',
    nonce=nonce,
    session_cookie=session_cookie,
    json=None
)
print(response.json())

# create a new team
for i in range(5):
    response = apiRequest(
        method=requests.post,
        url='http://127.0.0.1:8000/api/v1/teams',
        nonce=nonce,
        session_cookie=session_cookie,
        json={
            'name': f'team{i}',
            'email': f'team{i}@example.com', 
            'password': f'team{i}', 
            'hidden': False, 
            'banned': False, 
            'fields': []
        }
    )
    print(response.json())

# create a new user
for i in range(5):
    response = apiRequest(
        method=requests.post,
        url='http://127.0.0.1:8000/api/v1/users',
        nonce=nonce,
        session_cookie=session_cookie,
        json={
            'banned': False,
            'email' : f"user{i}@bar.com",
            'fields': [],
            'hidden': False,
            'name': f"user{i}",
            'password': f"user{i}",
            'type': "user",
            'verified': True
        }
    )
    print(response.json())

# add a user to team
for i in range(5):
    response = apiRequest(
        method=requests.post,
        url=f'http://127.0.0.1:8000/api/v1/teams/{i+1}/members',
        nonce=nonce,
        session_cookie=session_cookie,
        # admin user is user_id 1 to users are i + 2
        json={
            'user_id': i+2
        }
    )
    print(response.json())


# create a new challenge
for i in range(5):
    response = apiRequest(
        method=requests.post,
        url='http://127.0.0.1:8000/api/v1/challenges',
        nonce=nonce,
        session_cookie=session_cookie,
        json={
            'name': f'challenge{i}',
            'category': 'category',
            'state': 'visible',
            'value': 10,
            'type': 'standard',
            'description': f'sample *challenge{i}*'
        }
    )
    print(response.json())

# add a flag to a challenge
for i in range(5):
    response = apiRequest(
        method=requests.post,
        url='http://127.0.0.1:8000/api/v1/flags',
        nonce=nonce,
        session_cookie=session_cookie,
        json={
            'challenge': i+1,
            'content': f'flag{i}',
            'type': 'static',
            'data': ""
        }
    )
    print(response.json())

# add requirement
# for i in range(5):
#     response = apiRequest(
#         method=requests.patch,
#         url=f'http://localhost:8000/api/v1/challenges/{i}/requirements',
#         nonce=nonce,
#         session_cookie=session_cookie,
#         json={
#             'requirements': {
#                 'prerequisites': range(1,i-1,1), 
#                 'anonymize': True
#             }
#         }
#     )
#     print(response.json())

# add recommended next
for i in range(5-1):
    response = apiRequest(
        method=requests.patch,
        url=f'http://localhost:8000/api/v1/challenges/{i}',
        nonce=nonce,
        session_cookie=session_cookie,
        json={
            'next_id': i+1
        }
    )
    print(response.json())

# add hints next
for i in range(5):
    response = apiRequest(
        method=requests.post,
        url=f'http://localhost:8000/api/v1/hints',
        nonce=nonce,
        session_cookie=session_cookie,
        json={
            "challenge_id": i+1,
            "content": f"hint{i}",
            "cost": "10",
            "requirements": {
                "prerequisites": []
            }
        }
    )
    print(response.json())


# add a file to a challenge
with open('ctfd.svg', 'rb') as file:
    response = apiRequest(
        method=requests.post,
        url='http://127.0.0.1:8000/api/v1/files',
        files={
            'file': file
        },
        nonce=nonce,
        session_cookie=session_cookie,
        data={
            'challenge': 1,
            'type': 'challenge',
            'nonce': nonce
        }
    )
    print(response.json()) 
