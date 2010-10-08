" oauth
" Last Change: 2010-09-10
" Maintainer:   Yasuhiro Matsumoto <mattn.jp@gmail.com>
" License:      This file is placed in the public domain.
" Reference:
"   http://tools.ietf.org/rfc/rfc5849.txt

let s:save_cpo = &cpo
set cpo&vim

function! oauth#requestToken(url, consumer_key, consumer_secret, params)
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_version"] = "1.0"
  for key in keys(a:params)
    let query[key] = a:params[key]
  endfor
  let query_string = "POST&"
  let query_string .= http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= http#encodeURI(http#encodeURI(query))
  let hmacsha1 = hmac#sha1(http#encodeURI(a:consumer_secret) . "&", query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let res = http#post(a:url, query, {})
  let request_token = http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token='")[0], '^[^=]*=', '', ''))
  let request_token_secret = http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token_secret='")[0], '^[^=]*=', '', ''))
  return [request_token, request_token_secret]
endfunction

function! oauth#accessToken(url, consumer_key, consumer_secret, request_token, request_token_secret, params)
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:request_token
  let query["oauth_token_secret"] = a:request_token_secret
  let query["oauth_version"] = "1.0"
  for key in keys(a:params)
    let query[key] = a:params[key]
  endfor
  let query_string = "POST&"
  let query_string .= http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= http#encodeURI(http#encodeURI(query))
  let hmacsha1 = hmac#sha1(http#encodeURI(a:consumer_secret) . "&" . http#encodeURI(a:request_token_secret), query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let res = http#post(a:url, query, {})
  let request_token = http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token='")[0], '^[^=]*=', '', ''))
  let request_token_secret = http#decodeURI(substitute(filter(split(res.content, "&"), "v:val =~ '^oauth_token_secret='")[0], '^[^=]*=', '', ''))
  return [request_token, request_token_secret]
endfunction

function! oauth#get(url, consumer_key, consumer_secret, access_token, access_token_secret, params, getdata, headdata)
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "GET"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:access_token
  let query["oauth_version"] = "1.0"
  for key in keys(a:params)
    let query[key] = a:params[key]
  endfor
  let query_string = query["oauth_request_method"] . "&"
  let query_string .= http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= http#encodeURI(http#encodeURI(query))
  let hmacsha1 = hmac#sha1(http#encodeURI(a:consumer_secret) . "&" . http#encodeURI(a:access_token_secret), query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let auth = 'OAuth '
  for key in sort(keys(query))
    let auth .= key . '="' . http#encodeURI(query[key]) . '", '
  endfor
  let auth = auth[:-3]
  let headdata = a:headdata
  if empty(headdata)
    let headdata = {}
  endif
  let headdata["Authorization"] = auth
  let res = http#get(a:url, a:getdata, headdata)
  return res
endfunction

function! oauth#post(url, consumer_key, consumer_secret, access_token, access_token_secret, params, postdata, headdata)
  let query = {}
  let time_stamp = localtime()
  let nonce = time_stamp . " " . time_stamp
  let nonce = sha1#sha1(nonce)[0:28]
  let query["oauth_consumer_key"] = a:consumer_key
  let query["oauth_nonce"] = nonce
  let query["oauth_request_method"] = "POST"
  let query["oauth_signature_method"] = "HMAC-SHA1"
  let query["oauth_timestamp"] = time_stamp
  let query["oauth_token"] = a:access_token
  let query["oauth_version"] = "1.0"
  if type(a:params) == 4
    for key in keys(a:params)
      let query[key] = a:params[key]
    endfor
  endif
  let query_string = query["oauth_request_method"] . "&"
  let query_string .= http#encodeURI(a:url)
  let query_string .= "&"
  let query_string .= http#encodeURI(http#encodeURI(query))
  let hmacsha1 = hmac#sha1(http#encodeURI(a:consumer_secret) . "&" . http#encodeURI(a:access_token_secret), query_string)
  let query["oauth_signature"] = base64#b64encodebin(hmacsha1)
  let auth = 'OAuth realm="https://www.google.com/accounts/AuthSubRequest", '
  for key in sort(keys(query))
    let auth .= http#escape(key) . '="' . http#escape(query[key]) . '",'
  endfor
  let auth = auth[:-2]
  let headdata = a:headdata
  if empty(headdata)
    let headdata = {}
  endif
  let headdata["Authorization"] = auth
  let res = http#post(a:url, a:postdata, headdata)
  return res
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
