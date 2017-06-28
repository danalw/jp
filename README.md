FLOW
IN: data/*.txt
1) tokenize http://lindat.mff.cuni.cz/services/morphodita/api/tokenize
2) http://lindat.mff.cuni.cz/services/morphodita/api/tag -> morp_temp
  http://lindat.mff.cuni.cz/services/udpipe/api/process -> udpipe_temp
3) udpipe_temp find, extract whole sentences with problematic tokens inside(\d-\d), merge -> edited/ (before)
4) edited sentences to http://lindat.mff.cuni.cz/services/parsito/api/parse -> edited/#_parsito_ (after)
5) substitution of origin sentences for edited sentences -> udpipe_temp2
6) check and merge morp_temp with udpipe_temp2 -> t1  

