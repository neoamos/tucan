import {
  relayInit
} from 'nostr-tools'
import { useEffect } from 'react'

import { useSelector, useDispatch } from 'react-redux'
import { setRelay } from './state/userSlice'

import axios from 'axios'

let globalRelays = {}
let event_queue = []

const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
axios.defaults.headers.post["X-CSRF-Token"] = token

export function publishEvent(event){
  let queue_item = {event: event, relays: {}}
  event_queue.push(queue_item)
  for(const [key, value] of Object.entries(globalRelays)){
    if(value.connection.status == 1){
      console.log("Sending", event.id, "to", key)
      let pub = value.connection.publish(event)
      pub.on('ok', () => {
        console.log(`${key} has accepted our event`)
      })
      pub.on('seen', () => {
        console.log(`we saw the event on ${key}`)
      })
      pub.on('failed', reason => {
        console.log(`failed to publish to ${key}: ${reason}`)
      })
      queue_item.relays[key] = true
    }
  }
}

export function postEvent(event){
  return axios.post("/api/v1/event", {
    event: event
  })
}

export function connectedRelayCount(){
  let count = 0
  for(const [key, value] of Object.entries(globalRelays)){
    if(value.connected){
      count++
    }
  }
  return count
}

export function useRelays(){
  const user = useSelector((state) => state.user.user)
  const dispatch = useDispatch()

  function connectRelay(url){
    const relay = relayInit(url)
    relay.on('connect', () => {
      console.log(`connected to ${relay.url}`)
      dispatch(setRelay({url: relay.url, value: true}))
      globalRelays[relay.url].connected = true
      globalRelays[relay.url].retries = 0
      for(let i = 0; i < event_queue.length; i++){
        if(!event_queue[i].relays[relay.url]){
          console.log("Sending", event_queue[i].event.id, "to", relay.url)
          event_queue[i].relays[relay.url] = true
          relay.publish(event_queue[i].event)
        }
      }
    })
    relay.on('error', () => {
      if(globalRelays[relay.url]){
        console.log(`failed to connect to ${relay.url}`)
        globalRelays[relay.url].connected = false
        globalRelays[relay.url].retries = (globalRelays[relay.url].retries || 0) + 1
        clearTimeout(globalRelays[relay.url].timeout)
        globalRelays[relay.url].timeout = setTimeout(function(){
          relay.connect()
        }, (2**Math.min(globalRelays[relay.url].retries, 5)*1000))
      }
    })
    relay.on('disconnect', () => {
      if(globalRelays[relay.url]){
        console.log(`disconnected from ${relay.url}`)
        dispatch(setRelay({url: relay.url, value: false}))
        globalRelays[relay.url].connected = false
        globalRelays[relay.url].retries = (globalRelays[relay.url].retries || 0) + 1
        clearTimeout(globalRelays[relay.url].timeout)
        globalRelays[relay.url].timeout = setTimeout(function(){
          relay.connect()
        }, (2**Math.min(globalRelays[relay.url].retries, 5)*1000))
      }
    })
    globalRelays[url] = {
      connection: relay,
      connected: false
    }
    relay.connect()
  }

  function disconnectRelay(url){
    if(globalRelays[url]){
      let r = globalRelays[url]
      r.connection.off('disconnect')
      clearTimeout(r.timeout)
      r.connection.close()
      dispatch(setRelay({url: url, value: undefined}))
      globalRelays[url] = undefined
    }
  }

  function syncRelays(relays){
    // Connect new relays
    for(let i = 0; i < relays.length; i++){
      let r = relays[i]
      if(r.write && !globalRelays[r.url]){
        connectRelay(r.url)
      }
    }
    // Disconnect old relays
    for(const [key, value] of Object.entries(globalRelays)){
      let i = relays.findIndex((r) => r.url == key)
      if(i == -1){
        console.log("disconnecting", key)
        disconnectRelay(key)
      }else if(relays[i].write==false){
        console.log("disconnecting", key)
        disconnectRelay(key)
      }
    }
  }

  useEffect(() => {
    if(user && user.relays){
      syncRelays(user.relays)
    }
  }, [user])
}