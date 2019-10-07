spec: spec.txt

%.xml: %.md
	kramdown-rfc2629 $< >$@

%.txt: %.xml
	xml2rfc $< -o $@ --text
