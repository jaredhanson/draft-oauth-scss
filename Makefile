spec: draft-hanson-oauth-session-continuity.xml draft-hanson-oauth-session-continuity.txt

%.xml: %.md
	kramdown-rfc $< >$@

%.txt: %.xml
	xml2rfc $< -o $@ --text

%.html: %.xml
	xml2rfc $< -o $@ --html
