function showDialog(n) {
  n ? $("#dialog").css("visibility", "visible") : $("#dialog").css("visibility", "hidden")
}

function showSpinner(n) {
  n ? $("#waiting").css("visibility", "visible") : $("#waiting").css("visibility", "hidden")
}

function setStorage(n, e) {
  "" != e && jStorage.set(n, e)
}

function getStorage(n) {
  var e;
  return "" != jStorage.get(n) && (e = jStorage.get(n)), e
}

function deleteStorage(n) {
  jStorage.deleteKey(n)
}

function toggle_comments(n) {
  n ? ($("#show_all_cmnts_div").show(), $("#show_only_cmnts_div").hide()) : ($("#show_all_cmnts_div").hide(), $("#show_only_cmnts_div").show())
}

function arrange_comments(n, e) {
  1 == e ? ($(n).each(function(n, e) {
    view_all_comment(e)
  }), toggle_comments(!1)) : ($(n).each(function(n, e) {
    hide_all_comment(e)
  }), toggle_comments(!0))
}

function update_show_comments(n, e) {
  var i = $("#hdn_profile_id").val();
  showSpinner(!0), $.ajax({
    type: "POST",
    url: "/profile/show_comments",
    data: {
      id: i,
      show: e
    },
    dataType: "json",
    success: function(e) {
      1 == e.message ? arrange_comments(n, !0) : arrange_comments(n, !1), showSpinner(!1)
    },
    error: function() {
      alert("An Error has occured"), showSpinner(!1)
    }
  })
}
window.OnCampus || (OnCampus = {}), OnCampus.Validation = {
  validateEmail: function(n) {
    return !!n.toLowerCase().match(/^[_a-z0-9-]+([_a-z0-9.!#$%&*+/=?'{}|~\(\),:;<>\[\]-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,6})$/)
  }
};
