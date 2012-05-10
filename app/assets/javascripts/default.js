function showDialog(visible) {
  if (visible) {
    $("#dialog").css("visibility", "visible");
  } else {
    $("#dialog").css("visibility", "hidden");
  }
}

function showSpinner(visible) {
  if (visible) {
    $("#waiting").css("visibility", "visible");
  } else {
    $("#waiting").css("visibility", "hidden");
  }
}

//Set temp storage
function setStorage(key,value){
  //alert(key +"==="+ value);//debug
  if(value!=""){
    jStorage.set(key, value);
  }
}
//Get temp storage
function getStorage(key) {
  var val
  if(jStorage.get(key)!=""){
    val = jStorage.get(key);
  }
  return val;
}
//Delete temp storage key
function deleteStorage(key) {
  jStorage.deleteKey(key);
}
