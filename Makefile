spec: spec.txt

%.xml: %.md
	kramdown-rfc $< >$@

%.txt: %.xml
	xml2rfc $< -o $@ --text

%.html: %.xml
	xml2rfc $< -o $@ --html
