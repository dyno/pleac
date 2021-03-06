 #******************************************************************************
 #
 # Copyright (c) 2001 Guillaume Cottenceau <gc@mandrakesoft.com>
 #
 # PLEAC - Programming Language Examples Alike Cookbook
 #
 # Please visit:
 #
 #    http://pleac.sf.net/
 #    http://sf.net/projects/pleac
 #
 #
 # The documentation provided by this project is free documentation and can be
 # redistributed under the terms of the GNU Free Documentation Licence.
 #
 # You should have received a copy of the GNU Free Documentation License.
 # If not, please find it here: http://www.gnu.org/copyleft/fdl.html
 #
 #*****************************************************************************

# IMPLS must be sorted by percentage of completion
IMPLS = perl groovy ocaml python ruby guile commonlisp rexx tcl pike php haskell merd picolisp ada haskell-on-steroids java clojure cposix pliant c++ factor smalltalk forth erlang R objective-c masd coffeescript bash nasm go


DATAFILES = $(wildcard pleac_*.data)
HTMLTARGETS = $(subst .data,,$(DATAFILES))
HTMLTARGETSDEP = $(addsuffix /index.html, $(HTMLTARGETS))

PSTARGETS = $(addsuffix .ps, $(addprefix pleac_, $(IMPLS)))


all: $(HTMLTARGETSDEP) web

clean:
	rm -rf index.html pleac_*.html skeleton tmp.data $(HTMLTARGETS)

skeleton/index.html: skeleton.sgml
	rm -rf $@
	db2html -d pleac.dsl $<

%.html: %.data
	ruby1.8 -pe 'sub(/((@@|\^\^)INCLUDE(@@|\^\^) (\S+))/) { "#{$$1}\n" + File.open($$4).read }' $< > tmp.data
	./code2html tmp.data
	ruby1.8 -pi -e 'sub(/(@@|\^\^)INCLUDE(@@|\^\^) (\S+)/) { "<font size=\"-1\"><a href=\"http://pleac.sourceforge.net/#{$$3}\">download the following standalone program</a></font>" }' tmp.data.html
	mv -f tmp.data.html $@

$(HTMLTARGETSDEP): %/index.html: %.html skeleton/index.html
	rm -rf $(@D)
	cp -a skeleton $(@D)
	for i in $(@D)/*.html; do ./substitute.rb $$i $(@D).html ; done
	./genpercentages.rb $(@D)/index.html $(@D).data skeleton.sgml

web: $(DATAFILES)
	total=`grep "PLEAC:[0-9].*:CAELP" skeleton.sgml | wc -l` ; \
	cp index-skeleton.html index.html ; \
	ruby1.8 -pi -e "sub(/@LASTUPDATE@/, '`date`')" index.html ; \
	echo "<ul> " > webcontents ; \
	for i in $(IMPLS); \
	do \
		echo "<li>" >> webcontents; \
		done=`grep "..PLEAC.._[0-9].*" pleac_$$i.data | wc -l`; \
		incomp=`grep "@@INCOMPLETE@@" pleac_$$i.data | wc -l`; \
		percent=`ruby1.8 -e "printf \"%.2f\n\", ($$done-0.5*$$incomp)*100/Float($$total)"`; \
		echo "" >> webcontents; \
		echo "<a href=\"pleac_$$i/index.html\">$$i</a>, $$percent% done " >> webcontents; \
		echo "(<a href=\"pleac_$$i.data\">raw source</a>, <a href=\"pleac_$$i.html\">colorized source</a>)" >> webcontents; \
		echo "</li>" >> webcontents; \
	done
	echo "</ul> " >> webcontents
	ruby1.8 -pi -e "sub(/@CURRENTVERSIONS@/, '`cat webcontents`')" index.html
	rm -f webcontents

cvs:
	cvs up

upload: cvs all web
	rm -rf ../t
	mkdir ../t
	cp -a * ../t
	cd ../t; rm -rf `find -type d -name CVS`; scp -r * ggc,pleac@web.sourceforge.net:/home/groups/p/pl/pleac/htdocs
	rm -rf ../t
