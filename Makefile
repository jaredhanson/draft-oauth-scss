spec:
	kramdown-rfc2629 spec.md >spec.xml
	xml2rfc spec.xml -o Draft-1.0.txt --text
