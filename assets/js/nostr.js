
import {
  validateEvent,
  verifySignature,
  signEvent,
  getEventHash,
  getPublicKey
} from 'nostr-tools'

import { nip19 } from 'nostr-tools'

import axios from 'axios'

export function validSeckey(seckey){
  try{
    nip19.decode(seckey)
    return true
  }catch(e){
    return false
  }
}

export function sign(event){
  if(localStorage.getItem("seckey")){
    return new Promise((resolve, reject) => {
      let seckey = localStorage.getItem("seckey")
      event.pubkey = getPublicKey(seckey)
      event.id = getEventHash(event)
      event.sig = signEvent(event, seckey)
      resolve(event)
    })
  }else{
    return new Promise((resolve, reject) => {
      if(window.nostr){
        window.nostr.getPublicKey()
        .then(function(pubkey){
          event.pubkey = pubkey
          event.id = getEventHash(event)
          window.nostr.signEvent(event)
          .then(function(event){
            resolve(event)
          })
        })
      }else{
        reject()
      }
    })
  }
}

export async function getMetadataEvent(){
  let resp = await axios.get("/api/v1/metadata")
  return resp.data
}


let contact_list_event = null
let contact_list_at = 0
export async function getContactList(update){
  let now = Math.floor(Date.now() / 1000)
  if(contact_list_event == null || now == contact_list_at >10){
    let resp = await axios.get("/api/v1/contact_list")
    contact_list_event=resp.data
    contact_list_at = Math.floor(Date.now() / 1000)
  }
  return new Promise((resolve) => {
    if(update){
      if(update.action == "add"){
        let index = contact_list_event.tags.findIndex((t) => t[0] == "p" && t[1] == update.pubkey)
        if(index == -1){
          contact_list_event.tags.push(["p", update.pubkey])
          contact_list_event.created_at = Math.floor(Date.now() / 1000)
        }
      }else{
        let index = contact_list_event.tags.findIndex((t) => t[0] == "p" && t[1] == update.pubkey)
        if(index != -1){
          contact_list_event.tags.splice(index, 1)
          contact_list_event.created_at = Math.floor(Date.now() / 1000)
        }
      }
    }
    resolve(contact_list_event)
  })
}

