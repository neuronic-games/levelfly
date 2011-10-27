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