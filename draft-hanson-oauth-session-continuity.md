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

This specification defines a mechanism in which clients and resource servers can
share session signals with an authorization server.  These signals are
transported using existing OAuth 2.0 endpoints, providing a lightweight approach
to continuous authorization.


--- middle

# Introduction

In OAuth, an authorization server issues access tokens to clients, which are
used to access protected resources hosted by a resource server.  Prior to
issuing tokens, the authorization server authenticates the end-user and obtains
consent.  This interaction establishes a session in which the end-user accesses
both the authorization server and one or more applications.

These sessions can be long-lived, lasting for days or months.  During this time,
the status of the end-user and her device, such as location, network address, or
security posture, may change - requring a change in access privileges.
Unfortunately, typical OAuth deployments determine access only at the time of
authentication and lack awareness of dynamically changing information about
ongoing sessions.

This specification defines a mechanism in which clients and resource servers can
share session signals with an authorization server.  These signals are
transported using existing OAuth 2.0 endpoints.  Use of existing endpoints is
intended to provide a lightweight approach to continuous authorization, while
complimenting future protocols that provide real-time access evaluation using a
publish-subscribe approach.

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

# Signal Sharing

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
