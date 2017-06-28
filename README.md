FLOW
IN: data/*.txt
1) http://lindat.mff.cuni.cz/services/morphodita/api/tokenize per file;
2) http://lindat.mff.cuni.cz/services/morphodita/api/tag -> morp_temp;
  http://lindat.mff.cuni.cz/services/udpipe/api/process -> udpipe_temp;
3) find whole sentences with problematic tokens inside of udpipe_temp (contains tokens with id with format \d-\d),
  and extract -> edited/ (before)
4) edit sentences and generates new d tree  http://lindat.mff.cuni.cz/services/parsito/api/parse -> edited/#_parsito_ (after)
5) substitution of origin sentences for edited sentences in udpipe_temp -> udpipe_temp2 
6) check and merge morp_temp with udpipe_temp2 -> t1  

