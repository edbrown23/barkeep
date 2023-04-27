// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

Rails.start()
ActiveStorage.start()

import '../../javascript/controllers'

import jquery from "jquery"
global.$ = global.jQuery = jquery;
window.$ = window.jQuery = jquery;

import '../js/bootstrap_js_files.js'
import * as bootstrap from 'bootstrap'
window.bootstrap = require("bootstrap");

import '../js/select2_files.js'

// My shared js library functions
import * as lib from '../js/lib/shared.js'
window.lib = lib