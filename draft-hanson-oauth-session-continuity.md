---
docname: draft-hanson-oauth-session-continuity-latest
category: std
ipr: trust200902
submissionType: IETF

title: OAuth 2.0 Session Continuity
author:
  -
    ins: J. Hanson
    name: Jared Hanson
    org: Okta
    email: jared.hanson@okta.com
  -
    ins: K. McGuinness
    name: Karl McGuinness
    org: Okta
    email: kmcguinness@okta.com

area: Security
workgroup: Web Authorization Protocol

--- abstract

This specification defines a mechanism by which an OAuth 2.0 authorization
server can maintain a logical authorization session in which protected resources
can be accessed over a period time.  This specification also extends existing
OAuth 2.0 endpoints so that dynamic context about the session, such as user
location or device health, can be communicated to the authorization server
throughout the lifetime of the session.  Combined, this functionality provides
a lightweight approach to continuous authorization.


--- middle

# Introduction

In OAuth 2.0 {{!RFC6749}}, an authorization server issues an access token and
refresh token to a client.  The client uses the access token to access protected
resources hosted by a resource server, and uses the refresh token to obtain
new access tokens from the authorization server.  While the authorization
server, client, and resource server are separate entities, the usage of the
access token and refresh token forms a logical authorization session shared
between each entity.

The access token and refresh token are issued by the authorization server after
authenticating the resource owner and obtaining authorization.  Authorization is
typically obtained by interacting with the resource owner via the authorization
endpoint.  Once authorization has been obtained, issuance of the tokens
initiates an ongoing session in which protected resources may be accessed over
a period of hours or even days.

During this time, the status of the resource owner and her device, such as role,
location, or security posture, may change.  Increasingly, access to protected
resources needs to be based on this dynamically changing context.  However,
typical OAuth deployments evaluate this context infrequently - often only at
session initiation.

This specification provides mechanisms by which an OAuth deployment can both
increase the frequency of access policy evaluation during a session, as well as
increase awareness of dynamically changing context about the session used to
inform policy decisions.  Combined, this functionality provides a lightweight
approach to continuous authorization.

## Client Profiles

This specification has been designed around the client profiles defined in
Section 2.1 of {{!RFC6749}}:

{: vspace="0"}
web application:
: A web application is a confidential client running on a web server.  Resource
owners access the client via an HTML user interface rendered in a user-agent on
the device used by the resource owner.  The client credentials as well as any
access token issued to the client are stored on the web server and are not
exposed to or accessible by the resource owner.

user-agent-based application:
: A user-agent-based application is a public client in which the client code is
downloaded from a web server and executes within a user-agent (e.g., web
browser) on the device used by the resource owner.  Protocol data and
credentials are easily accessible (and often visible) to the resource owner.
Since such applications reside within the user-agent, they can make seamless use
of the user-agent capabilities when requesting authorization.

native application:
: A native application is a public client installed and executed on the device
used by the resource owner.  Protocol data and credentials are accessible to the
resource owner.  It is assumed that any client authentication credentials
included in the application can be extracted.  On the other hand, dynamically
issued credentials such as access tokens or refresh tokens can receive an
acceptable level of protection.  At a minimum, these credentials are protected
from hostile servers with which the application may interact.  On some
platforms, these credentials might be protected from other applications residing
on the same device.

## Token Locality

After obtaining approval of the end-user via interaction within the end-user's
user-agent, OAuth issues delegation-specific access tokens and refresh tokens to
clients.  This specification defines two token localities, based on where tokens
reside relative to the user-agent in which the issuance was approved:

{: vspace="0"}
off device:
: A token is off device when it resides with an application that is not located
on the same device as the end-user's user-agent.  Tokens issued to a web
application are off device, as the application runs on a web server acceessed
remotely via the user-agent.

on device:
: A token is on device when it resides with an application that is located on
the same device as the end-user's user-agent.  Tokens issued to native
native applications and user-agent-based applications are on device, as the
application is executing either on the device or within the user-agent itself.

## Notational Conventions

{::boilerplate bcp14}

# JSON Web Token Claims

Access tokens and refresh tokens are opaque, and can have different formats,
structures, and methods of utilization based on resource server and
authorization server security requirements.  Although the mechanisms described
herein can be used with any type of token, this section defines claims to
express such semantics specifically for JSON Web Token (JWT) {{!RFC7519}}.
Similar definitions for other types of tokens are possible but beyond the scope
of this specification.

## Access Tokens

JSON Web Token Profile for OAuth 2.0 Access Tokens {{!RFC9068}} defines a
profile for issuing OAuth 2.0 access tokens in JSON Web Token (JWT) format.
OAuth 2.0 deployments implementing this specification MAY issue access tokens
in conformance that profile.  Deployments that do not issue access tokens in
conformance with that profile SHOULD include semantically equivalent claims in
a deployment-specific token format.

The following additional claims SHOULD be included to facilitate session
continuity.

sid - as defined in Section 3 of OpenID.FrontChannel.

## Refresh Tokens

Unlike access tokens, refresh tokens are intended only for use with
authorization servers.  Thus, their format is an internal implementation detail
of an authorization server and there is little need for a profile to establish
interoperability between implementations.

OAuth 2.0 deployments implementing this specification MAY issue refresh tokens
in JWT format.  Implementations that issue refresh tokens in JWT format SHOULD
include the following claims.

iss - as defined in Section 4.1.1 of {{!RFC7519}}.

exp - as defined in Section 4.1.4 of {{!RFC7519}}.

aud - as defined in Section 4.1.3 of {{!RFC7519}}.

sub - as defined in Section 4.1.2 of {{!RFC7519}}.

client_id - as defined in Section 4.3 of {{!RFC8693}}.

iat - as defined in Section 4.1.6 of {{!RFC7519}}.  This claim identifies the
time at which the JWT refresh token was issued.

jti - as defined in Section 4.1.7 of {{!RFC7519}}.

sid - as defined in Section 3 of OpenID.FrontChannel.

This specification registers the "application/rt+jwt" media type, which can be
used to indicate that the content is a JWT refresh token.  JWT refresh tokens
MUST include this media type in the "typ" header parameter to explicitly declare
that the JWT represents a refresh token.

Deployments that do not issue refresh tokens in JWT format SHOULD include
semantically equivalent claims in a deployment-specific token format.

# Session Continuity

An authorization server can issue an access token and, optionally, a refresh
token in response to any authorization grant defined by {{!RFC7519}} and subsequent
extensions.  To facilitate session continuity, an authorization server SHOULD
include the "sid" claim in the access token and refresh token, if any.

For example, the client makes the following HTTP request using TLS to the token
endpoint (with extra line breaks for display purposes only):

~~~
  POST /token HTTP/1.1
  Host: server.example.com
  Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW
  Content-Type: application/x-www-form-urlencoded

  grant_type=authorization_code&code=SplxlOBeZQQYbYS6WxSbIA
  &redirect_uri=https%3A%2F%2Fclient%2Eexample%2Ecom%2Fcb
~~~

A successful response results in an access token and refresh token.

For example, an access token in JWT format would be structured as follows:

~~~
  { "typ": "at+JWT", "alg": "RS256", "kid": "RjEwOwOA" }
  .
  {
    "iss": "https://server.example.com/",
    "aud": "https://rs.example.com/",
    "sub": "248289761001",
    "client_id": "s6BhdRkqt3",
    "scope": "read write dolphin",
    "sid": "08a5019c-17e1-4977-8f42-65a12843ea02",
    "jti": "dbe39bf3a3ba4238a513f51d6e1691c4",
    "exp": 1419357438,
    "iat": 1419350238,
  }
~~~

And, for example, a refresh token in JWT format would be structured as follows:

~~~
  { "typ": "rt+JWT", "alg": "HS256" }
  .
  {
    "iss": "https://server.example.com/",
    "aud": "https://server.example.com/token",
    "sub": "248289761001",
    "client_id": "s6BhdRkqt3",
    "sid": "08a5019c-17e1-4977-8f42-65a12843ea02",
    "jti": "ae7eacde7d3a495aad2dc1196a9b659f",
    "exp": 1421942238,
    "iat": 1419350238,
  }
~~~

The access token and refresh token belong to the same authorization session, as
indicated by the correlated "sid" claim values.

## Refreshing an Access Token

If the authorization server issued a refresh token to the client, the client
makes a refresh request to the token endpoint to obtain a new access token.  If
valid and authorized, the authorization server issues a new access token and MAY
issue a new refresh token.  The new access token and refresh token belong to the
same authorization session as the initial access token and refresh token
obtained in exchange for the original authorization grant.  To maintain session
continuity, an authorization server SHOULD include the "sid" claim in the new
access token and refresh token, if any.  The value of the "sid" claim MUST be
correlated to the initial access token and refresh token.

For example, a new access token in JWT format would be structured as follows:

~~~
  { "typ": "at+JWT", "alg": "RS256", "kid": "RjEwOwOA" }
  .
  {
    "iss": "https://server.example.com/",
    "aud": "https://rs.example.com/",
    "sub": "248289761001",
    "client_id": "s6BhdRkqt3",
    "scope": "read write dolphin",
    "sid": "08a5019c-17e1-4977-8f42-65a12843ea02",
    "jti": "5014d91e3ef149ea94e3865962abb883",
    "exp": 1421949318,
    "iat": 1421942118,
  }
~~~

And, for example, a new refresh token in JWT format would be structured as follows:

~~~
  { "typ": "rt+JWT", "alg": "HS256" }
  .
  {
    "iss": "https://server.example.com/",
    "aud": "https://server.example.com/token",
    "sub": "248289761001",
    "client_id": "s6BhdRkqt3",
    "sid": "08a5019c-17e1-4977-8f42-65a12843ea02",
    "jti": "0d629e3212834e838fb6-cbcdece7cf99",
    "exp": 1424534118,
    "iat": 1421942118,
  }
~~~

# Session Authorization

An authorization session is initiated with the issuance of an initial access
token and refresh token.  These tokens represent specific scopes and durations
of access based on the context available to the authorization server at the time
of making an authorization decision and take into account authorization server
policy.

The particular moments in which the authorization server is able to make
authorization decisions are typically limited to those in which the authorization
server is interacting with the resource owner via the authorization endpoint,
and how frequently that interaction occurs.  For usability reasons, there is
a desire to minimize user interaction with the authorization server.  As a
consequence, authorization sessions are often long-lived.  This results in a
situation in which access decisions that need to account for dynamically
changing context, such as location, are operating based on out-of-date
information.

Within an authorization session, an authorization server can utilize the token
endpoint







During this time, the status of the resource owner and her device, such as role,
location, or security posture, may change.  Increasingly, access to protected
resources needs to be based on this dynamically changing context.  However,
typical OAuth deployments evaluate this context infrequently - often only at
session initiation.




Once an authorization session has been initiated, and tokens have been issued,
the client can access protected resources hosted by

## Authorization Endpoint

## Token Endpoint

## Introspection Endpoint


## Refreshing an Access Token






### From On Device

A native application possessing a refresh token that is on device shares signals
by making a refresh request that includes device posture, as defined in section
6 of {{!I-D.wdenniss-oauth-device-posture}}.

For example, the client makes the following HTTP request using transport-layer
security (with extra line breaks for display purposes only):

~~~~~~~~~~
  POST /token HTTP/1.1
  Host: server.example.com
  Content-Type: application/x-www-form-urlencoded

  grant_type=refresh_token&refresh_token=tGzv3JOkF0XG5Qx2TlKWIA
  client_id=s6BhdRkqt3&device_posture=%7B%22screen_lock%22%3Atrue%2C
  %22device_os%22%3A%22iOS%22%2C%22device_os_version%22%3A%2211.1%22
  %7D
~~~~~~~~~~

### From Off Device

A web application posessing a refresh token that is off device shares signals by
making a refresh request that includes user-agent posture, as defined by User
Agent Posture Signals.

For example, the client makes the following HTTP request using transport-layer
security (with extra line breaks for display purposes only):

~~~~~~~~~~
  POST /token HTTP/1.1
  Host: server.example.com
  Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW
  Content-Type: application/x-www-form-urlencoded

  grant_type=refresh_token&refresh_token=tGzv3JOkF0XG5Qx2TlKWIA
  client_id=s6BhdRkqt3&user_agent_posture=%7B%22user_agent%22%3A%22Mozilla%2F5.0
  %20%28Macintosh%3B%20Intel%20Mac%20OS%20X%2010_14_5%29%20AppleWebKit%2F537.36
  %20%28KHTML%2C%20like%20Gecko%29%20Chrome%2F75.0.3770.142%20Safari%2F537.36%22
  %2C%22ip_address%22%3A%2293.184.216.34%22%7D
~~~~~~~~~~

The client MUST only include user-agent posture in online access scenarios.
Refresh tokens used in offline scenarios, when the end-user is not present, are
decoupled from the session and lack end-user user agent context.

## Token Introspection

### Introspection Request

A resource server querying for to determine the state of an access token shares
signals by making an by making an introspection request to the introspection
endpoint, as defined in Section 2.1 of {{!RFC7662}}.

In addition to the parameters defined by Section 2.1 of {{!RFC7662}}, the
following parameters are also defined:
   
user_agent_posture
: OPTIONAL. URL-encoded JSON dictionary, containing user-agent posture signals,
as defined by User Agent Posture Signals.

For example, the client makes the following HTTP request using transport-layer
security (with extra line breaks for display purposes only):

~~~~~~~~~~
  POST /introspect HTTP/1.1
  Host: server.example.com
  Accept: application/json
  Content-Type: application/x-www-form-urlencoded
  Authorization: Basic czZCaGRSa3F0MzpnWDFmQmF0M2JW

  token=mF_9.B5f-4.1JqM&token_type_hint=access_token
  &user_agent_posture=%7B%22user_agent%22%3A%22Mozilla%2F5.0
  %20%28Macintosh%3B%20Intel%20Mac%20OS%20X%2010_14_5%29%20AppleWebKit%2F537.36
  %20%28KHTML%2C%20like%20Gecko%29%20Chrome%2F75.0.3770.142%20Safari%2F537.36%22
  %2C%22ip_address%22%3A%2293.184.216.34%22%7D
~~~~~~~~~~

Note that the locality of an access token is always off device when presented to
a resource server.

# Session Authorization






# Comparison to CAEP

Use of existing endpoints is
intended to provide a lightweight approach to continuous authorization, while
complimenting future protocols that provide real-time access evaluation using a
publish-subscribe approach.
