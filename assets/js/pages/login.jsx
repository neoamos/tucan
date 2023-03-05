import React, { useState, useEffect } from "react";
import axios from 'axios';

import { setTimeline, setFeed } from '../state/postSlice'


import { MainHeader } from "../layout";
import { useTitle } from "../components/ui_elements"
import { getEventHash } from 'nostr-tools'
import { useNavigate } from "react-router-dom";

import { setUser } from '../state/userSlice'
import { useDispatch } from 'react-redux'
import { sign, validSeckey } from "../nostr";
import { nip19 } from "nostr-tools";

const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
axios.defaults.headers.post["X-CSRF-Token"] = token
export default function Login(){
  useTitle("Login", [])

  const dispatch = useDispatch()
  const navigate = useNavigate()

  const [seckey, setSeckey] = useState("")

  useEffect(() => {
    let interval = setTimeout(() => {
      let available = !!window.nostr
      setExtensionAvailable(available)
      if(available){
        clearInterval(interval)
      }
    }, 1000)
    return () => {
      clearInterval(interval)
    }
  })

  const [extensionAvailable, setExtensionAvailable] = useState(!!window.nostr)

  function login(){
    let event = {
      kind: 188102,
      created_at: Math.floor(Date.now() / 1000),
      tags: [],
      content: 'Authenticate me! Jskah5XozzaPfnE3WQ5R'
    }
    sign(event).then(function(event){
      console.log(event)
      axios.post('/api/v1/login', {
        auth: JSON.stringify(event)
      })
      .then(function(resp){
        dispatch(setUser(resp.data))
        dispatch(setTimeline([]))
        dispatch(setFeed("Following"))
        navigate("/")
      })
    })

  }

  function secKeyLogin(){
    try{
      let decoded = nip19.decode(seckey).data
      window.localStorage.setItem("seckey", decoded)
      login()
    }catch(e){

    }
  }

  return (
    <div style={{height: "100%"}}>
      <MainHeader>
        <h2>Login</h2>
      </MainHeader>
      <div className="padding">
        <h3>Login with a browser extension (recommended)</h3>
        <p>
          With this option, you can log in with a browser extension such as Nos2x (<a href="https://chrome.google.com/webstore/detail/nos2x/kpgefcfmnafjgpblomihpgmejjdanjjp" target="_blank">Chrome</a>, <a href="https://addons.mozilla.org/en-US/firefox/addon/nos2x/" target="_blank">Firefox</a>), <a href="https://getalby.com/" target="_blank">Alby</a> or <a href="https://www.blockcore.net/wallet" target="_blank">Blockcore</a>.
        </p>
        <p>
          Your private key is kept securely by the browser extension and is never exposed to the application using it.
        </p>

        <div className="flex center">
          <button className="btn blue-bg bold long" onClick={login} disabled={!extensionAvailable}>Login with extension</button>
        </div>
        <h3>Login with your secret key</h3>
        <p>
          Your secret key will be kept in the browsers local storage.  It will be deleted when you logout.
        </p>
        <input type="text"
         placeholder="nsec..." 
         value={seckey} 
         onChange={(e) => {setSeckey(e.target.value)}}>
         </input>
        <button className="btn blue-bg bold long" style={{marginLeft: "auto"}} onClick={secKeyLogin} disabled={!validSeckey(seckey)}>Login</button>
      </div>
    </div>
  )
}