// Loader für alle 118 Elementgeschichten. Die bisher fachlich freigegebenen Texte bleiben unverändert.
(function(){
  "use strict";
  var v="20260916-2";
  var files=[
    "elementgeschichten_freigegeben.js",
    "elementgeschichten_1_30_missing.js",
    "elementgeschichten_31_52.js",
    "elementgeschichten_53_74.js",
    "elementgeschichten_75_96.js",
    "elementgeschichten_97_118.js"
  ];
  for(var i=0;i<files.length;i++){
    document.write('<script src="'+files[i]+'?v='+v+'"><\\/script>');
  }
})();
