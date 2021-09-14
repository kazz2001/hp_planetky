<!--
function FunSelectItem(FromWnd)
{
var nIndex, sHtmlName;
nIndex = FromWnd.selectedIndex;
sHtmlName = FromWnd.options[nIndex].value;
location.href = sHtmlName;
}
function fc(w){
        if(w == "")return;
        document.menu0.url.selectedIndex = 0;
        location.href=w;
}
function MM_jumpMenu(targ,selObj,restore){ //v3.0
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
}
//-->
