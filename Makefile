spec:
	kramdown-rfc2629 spec.md >spec.xml
	xml2rfc spec.xml -o draft-hanson-oauth-scss.txt --text
