// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

if (!window.OnCampus) OnCampus = {};

  OnCampus.Validation = {
    validateEmail: function(string) {
      return !!string.toLowerCase().match(/^[_a-z0-9-]+([_a-z0-9.!#$%&*+/=?'{}|~\(\),:;<>\[\]-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,6})$/)
    }
  }